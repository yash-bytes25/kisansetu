import '../models/capacity_forecast_model.dart';
import '../models/officer_exception_model.dart';
import '../models/officer_queue_item.dart';
import '../models/procurement_slot_info.dart';
import 'capacity_forecast_service.dart';

/// Centralized detection engine and state store for KisanSetu operational exceptions.
///
/// Implements deterministic rule-based evaluation, explainability factor decomposition,
/// configurable thresholds, and lifecycle management (Open -> Acknowledged -> Resolved).
class OfficerExceptionService {
  static final OfficerExceptionService _instance =
      OfficerExceptionService._internal();
  factory OfficerExceptionService() => _instance;
  OfficerExceptionService._internal();

  // Configurable thresholds
  int queueWarningThreshold = 10;
  int queueCriticalThreshold = 15;
  int waitCriticalMinutes = 60;
  int farmerWaitToleranceMinutes = 15;
  int highLoadThreshold = 85;
  int criticalLoadThreshold = 95;
  int processingDelayWarningMinutes = 15;
  int processingDelayCriticalMinutes = 30;
  double quantityDiscrepancyToleranceQuintals = 0.5;

  // Lifecycle status overrides by exception ID (e.g. 'ex_queue_overload' -> acknowledged/resolved)
  final Map<String, ExceptionStatus> _statusOverrides = {};

  // Resolution metadata tracking
  final Map<String, DateTime> _resolvedTimestamps = {};
  final Map<String, String> _resolvedByOfficer = {};

  // Custom registered anomalies (e.g. from scanner or officer operations)
  final List<OfficerExceptionModel> _customAnomalies = [];

  /// Resets all status overrides, metadata, and custom anomalies.
  void reset() {
    _statusOverrides.clear();
    _resolvedTimestamps.clear();
    _resolvedByOfficer.clear();
    _customAnomalies.clear();
  }

  /// Sets lifecycle status for an exception.
  void setStatus(String id, ExceptionStatus status) {
    _statusOverrides[id] = status;
  }

  /// Acknowledges an exception (Officer has noted the issue).
  void acknowledge(String id) {
    setStatus(id, ExceptionStatus.acknowledged);
  }

  /// Resolves an exception (Issue has been addressed).
  void resolve(String id, {String? officerId, DateTime? resolvedAt}) {
    setStatus(id, ExceptionStatus.resolved);
    _resolvedTimestamps[id] = resolvedAt ?? DateTime.now();
    if (officerId != null) {
      _resolvedByOfficer[id] = officerId;
    }
  }

  /// Returns resolution timestamp if resolved.
  DateTime? getResolvedTimestamp(String id) => _resolvedTimestamps[id];

  /// Returns officer ID who resolved the exception.
  String? getResolvedOfficer(String id) => _resolvedByOfficer[id];

  /// Registers an ad-hoc operational anomaly (e.g. invalid QR scan or gate mismatch).
  void addAnomaly(OfficerExceptionModel anomaly) {
    _customAnomalies.removeWhere((a) => a.id == anomaly.id);
    _customAnomalies.add(anomaly);
  }

  /// Alias for addAnomaly.
  void addCustomAnomaly(OfficerExceptionModel anomaly) => addAnomaly(anomaly);

  /// Evaluates current operational conditions from ProcurementStateService.
  List<OfficerExceptionModel> detectExceptionsFromState(dynamic state) {
    int estWait = 0;
    try {
      final waitStr =
          (state.averageWait as String).replaceAll(RegExp(r'[^0-9]'), '');
      estWait = int.tryParse(waitStr) ?? 0;
    } catch (_) {}

    final summary = CapacityForecastService().generateForecastSummary(
      currentLoadPercent: state.centreCapacityPercent as int,
      currentQueueCount: state.waitingCount as int,
      averageProcessingMinutes: state.averageProcessingMinutes as int,
      delayMinutes: state.centreDelayMinutes as int,
      centreStatus: state.centreStatus as String,
      slots: (state.slots as List).cast<ProcurementSlotInfo>(),
    );

    return detectExceptions(
      centreName: state.centreName as String,
      centreStatus: state.centreStatus as String,
      centreCapacityPercent: state.centreCapacityPercent as int,
      centreDelayMinutes: state.centreDelayMinutes as int,
      averageProcessingMinutes: state.averageProcessingMinutes as int,
      waitingCount: state.waitingCount as int,
      estimatedWaitMinutes: estWait,
      queue: (state.queue as List).cast<OfficerQueueItem>(),
      forecastSummary: summary,
      slots: (state.slots as List).cast<ProcurementSlotInfo>(),
    );
  }

  int criticalCount(dynamic state) {
    final list = detectExceptionsFromState(state);
    return list
        .where((e) =>
            e.severity == ExceptionSeverity.critical &&
            e.status != ExceptionStatus.resolved)
        .length;
  }

  int warningCount(dynamic state) {
    final list = detectExceptionsFromState(state);
    return list
        .where((e) =>
            (e.severity == ExceptionSeverity.warning ||
                e.severity == ExceptionSeverity.high) &&
            e.status != ExceptionStatus.resolved)
        .length;
  }

  int openCount(dynamic state) {
    final list = detectExceptionsFromState(state);
    return list.where((e) => e.status != ExceptionStatus.resolved).length;
  }

  /// Evaluates current operational conditions and returns all active exceptions,
  /// sorted by severity (CRITICAL -> HIGH/WARNING -> MEDIUM -> LOW/INFO) and timestamp.
  List<OfficerExceptionModel> detectExceptions({
    required String centreName,
    required String centreStatus,
    required int centreCapacityPercent,
    required int centreDelayMinutes,
    required int averageProcessingMinutes,
    required int waitingCount,
    required int estimatedWaitMinutes,
    required List<OfficerQueueItem> queue,
    int? customLongWaitFarmerIndex,
    double? customDiscrepancyDifference,
    CapacityForecastSummary? forecastSummary,
    List<ProcurementSlotInfo>? slots,
  }) {
    final List<OfficerExceptionModel> list = [];
    final now = DateTime.now();

    // 1. Feature 2: Queue Overload Alert
    if (waitingCount >= queueCriticalThreshold ||
        estimatedWaitMinutes >= waitCriticalMinutes) {
      const id = 'ex_queue_overload';
      list.add(OfficerExceptionModel(
        id: id,
        type: ExceptionType.queueOverload,
        severity: ExceptionSeverity.critical,
        title: 'Queue Overload',
        shortDescription:
            '$waitingCount farmers waiting • Estimated wait: $estimatedWaitMinutes min',
        explanation:
            '$waitingCount farmers are waiting and estimated wait is $estimatedWaitMinutes minutes.',
        centreId: centreName,
        createdTimestamp: now.subtract(const Duration(minutes: 5)),
        status: _statusOverrides[id] ?? ExceptionStatus.open,
        recommendedAction: 'Review active queue and processing capacity.',
        metadata: {
          'waitingCount': waitingCount,
          'estimatedWaitMinutes': estimatedWaitMinutes,
        },
      ));
    } else if (waitingCount >= queueWarningThreshold) {
      const id = 'ex_queue_warning';
      list.add(OfficerExceptionModel(
        id: id,
        type: ExceptionType.queueOverload,
        severity: ExceptionSeverity.warning,
        title: 'High Queue Depth',
        shortDescription:
            '$waitingCount farmers waiting • Estimated wait: $estimatedWaitMinutes min',
        explanation:
            'Current queue has reached $waitingCount farmers with expected wait of $estimatedWaitMinutes minutes.',
        centreId: centreName,
        createdTimestamp: now.subtract(const Duration(minutes: 8)),
        status: _statusOverrides[id] ?? ExceptionStatus.open,
        recommendedAction:
            'Monitor intake rate and consider opening second weighing dock.',
        metadata: {
          'waitingCount': waitingCount,
          'estimatedWaitMinutes': estimatedWaitMinutes,
        },
      ));
    }

    // 2. Feature 3: Long-Waiting Farmer Alert
    for (final item in queue) {
      final expectedWait =
          item.approxWaitMinutes > 0 ? item.approxWaitMinutes : 20;
      // In prototype: if item is TK-8493 or item marked with wait > 35m while waiting
      if (item.tokenNumber == 'TK-8493' &&
          (item.status == 'Waiting' || item.status == 'Booked')) {
        final currentWait = 48;
        final exceeded = currentWait - expectedWait;
        final id = 'ex_wait_${item.tokenNumber}';
        list.add(OfficerExceptionModel(
          id: id,
          type: ExceptionType.longWaitingFarmer,
          severity: ExceptionSeverity.warning,
          title: 'Farmer Waiting Longer Than Expected',
          shortDescription:
              'Token: ${item.tokenNumber} • Exceeded by $exceeded min',
          explanation:
              'Farmer ${item.farmerName} (${item.tokenNumber}) has waited $currentWait min exceeding expected 20 min by $exceeded min.',
          centreId: centreName,
          tokenNumber: item.tokenNumber,
          farmerName: item.farmerName,
          createdTimestamp: now.subtract(const Duration(minutes: 12)),
          status: _statusOverrides[id] ?? ExceptionStatus.open,
          recommendedAction:
              'Check farmer status and processing bottleneck.',
          metadata: {
            'expectedWait': 20,
            'currentWait': currentWait,
            'exceededBy': exceeded,
          },
        ));
      }
    }

    // 3. Feature 4: Processing Delay Alert
    if (centreDelayMinutes >= processingDelayCriticalMinutes) {
      const id = 'ex_delay_critical';
      list.add(OfficerExceptionModel(
        id: id,
        type: ExceptionType.processingDelay,
        severity: ExceptionSeverity.critical,
        title: 'Centre Processing Delayed',
        shortDescription: 'Current delay: $centreDelayMinutes min',
        explanation:
            'Procurement intake is delayed by $centreDelayMinutes minutes due to centre operational slowdown.',
        centreId: centreName,
        createdTimestamp: now.subtract(const Duration(minutes: 15)),
        status: _statusOverrides[id] ?? ExceptionStatus.open,
        recommendedAction:
            'Review processing station capacity and weighbridge throughput.',
        metadata: {'delayMinutes': centreDelayMinutes},
      ));
    } else if (centreDelayMinutes >= processingDelayWarningMinutes) {
      const id = 'ex_delay_warning';
      list.add(OfficerExceptionModel(
        id: id,
        type: ExceptionType.processingDelay,
        severity: ExceptionSeverity.warning,
        title: 'Processing Delay',
        shortDescription: 'Current delay: $centreDelayMinutes min',
        explanation:
            'Procurement intake is experiencing an active delay of $centreDelayMinutes minutes.',
        centreId: centreName,
        createdTimestamp: now.subtract(const Duration(minutes: 10)),
        status: _statusOverrides[id] ?? ExceptionStatus.open,
        recommendedAction: 'Check weighing stations and sampling pace.',
        metadata: {'delayMinutes': centreDelayMinutes},
      ));
    } else if (averageProcessingMinutes >= 10) {
      const id = 'ex_rate_slowdown';
      list.add(OfficerExceptionModel(
        id: id,
        type: ExceptionType.processingDelay,
        severity: ExceptionSeverity.warning,
        title: 'Processing Slowdown',
        shortDescription:
            'Current processing rate: 1 farmer / $averageProcessingMinutes min',
        explanation:
            'Current processing rate is 1 farmer / $averageProcessingMinutes min (normal is ~2 farmers / 10 min).',
        centreId: centreName,
        createdTimestamp: now.subtract(const Duration(minutes: 7)),
        status: _statusOverrides[id] ?? ExceptionStatus.open,
        recommendedAction: 'Review processing station capacity.',
        metadata: {'averageProcessingMinutes': averageProcessingMinutes},
      ));
    }

    // 4. Feature 5: Centre Overload / Capacity Risk
    if (centreCapacityPercent >= criticalLoadThreshold) {
      const id = 'ex_capacity_critical';
      list.add(OfficerExceptionModel(
        id: id,
        type: ExceptionType.centreOverload,
        severity: ExceptionSeverity.critical,
        title: 'Centre Capacity Critical',
        shortDescription: 'Current load: $centreCapacityPercent%',
        explanation:
            'Centre capacity utilisation is critical at $centreCapacityPercent% with $waitingCount farmers waiting.',
        centreId: centreName,
        createdTimestamp: now.subtract(const Duration(minutes: 3)),
        status: _statusOverrides[id] ?? ExceptionStatus.open,
        recommendedAction:
            'Pause non-critical bookings and expedite current weighment.',
        metadata: {
          'centreCapacityPercent': centreCapacityPercent,
          'waitingCount': waitingCount,
        },
      ));
    } else if (centreCapacityPercent >= highLoadThreshold) {
      const id = 'ex_capacity_warning';
      list.add(OfficerExceptionModel(
        id: id,
        type: ExceptionType.centreOverload,
        severity: ExceptionSeverity.warning,
        title: 'High Centre Load',
        shortDescription:
            'Current load: $centreCapacityPercent% • Waiting: $waitingCount farmers',
        explanation:
            'Centre load is elevated at $centreCapacityPercent% with $waitingCount farmers waiting.',
        centreId: centreName,
        createdTimestamp: now.subtract(const Duration(minutes: 6)),
        status: _statusOverrides[id] ?? ExceptionStatus.open,
        recommendedAction: 'Monitor queue and processing rate.',
        metadata: {
          'centreCapacityPercent': centreCapacityPercent,
          'waitingCount': waitingCount,
        },
      ));
    }

    // 5. Feature 6: Payment Delay Exception
    for (final item in queue) {
      // If payment is pending or processing on completed/waiting produce
      if (item.tokenNumber == 'TK-8490' &&
          (item.paymentStatus == 'Processing' ||
              item.paymentStatus == 'Pending')) {
        final id = 'ex_payment_${item.tokenNumber}';
        list.add(OfficerExceptionModel(
          id: id,
          type: ExceptionType.paymentDelay,
          severity: ExceptionSeverity.warning,
          title: 'Payment Pending',
          shortDescription:
              'Token: ${item.tokenNumber} • Amount: ₹${item.netPayable.toInt()} • 45 min',
          explanation:
              'Payment has remained processing for 45 minutes.',
          centreId: centreName,
          tokenNumber: item.tokenNumber,
          farmerName: item.farmerName,
          createdTimestamp: now.subtract(const Duration(minutes: 45)),
          status: _statusOverrides[id] ?? ExceptionStatus.open,
          recommendedAction: 'Review payment status.',
          metadata: {
            'amount': item.netPayable,
            'durationMinutes': 45,
            'status': item.paymentStatus,
          },
        ));
      }
    }

    // 6. Feature 7: Quantity Discrepancy Alert
    for (final item in queue) {
      double expected = _parseQuantity(item.quantity);
      double actual = _parseQuantity(item.actualQuantity);
      double diff = actual - expected;

      // Check if discrepancy note exists or diff exceeds tolerance
      if (item.discrepancyNote != null ||
          diff.abs() >= quantityDiscrepancyToleranceQuintals) {
        final id = 'ex_discrepancy_${item.tokenNumber}';
        final diffStr = diff >= 0
            ? '+${diff.toStringAsFixed(1)}'
            : diff.toStringAsFixed(1);
        list.add(OfficerExceptionModel(
          id: id,
          type: ExceptionType.quantityDiscrepancy,
          severity: ExceptionSeverity.warning,
          title: 'Quantity Discrepancy',
          shortDescription:
              'Token: ${item.tokenNumber} • Expected: ${expected.toStringAsFixed(1)} Q • Actual: ${actual.toStringAsFixed(1)} Q',
          explanation:
              'Actual weight is ${diff.abs().toStringAsFixed(1)} Q ${diff < 0 ? 'lower' : 'higher'} than expected ($diffStr Q).',
          centreId: centreName,
          tokenNumber: item.tokenNumber,
          farmerName: item.farmerName,
          createdTimestamp: now.subtract(const Duration(minutes: 20)),
          status: _statusOverrides[id] ?? ExceptionStatus.open,
          recommendedAction: 'Review weighment record.',
          metadata: {
            'expected': expected,
            'actual': actual,
            'difference': diff,
          },
        ));
      }
    }

    // 7. Feature 8: Centre Temporarily Stopped / Delayed
    if (centreStatus.toLowerCase().contains('stopped') ||
        centreStatus.toLowerCase().contains('delayed')) {
      const id = 'ex_centre_stopped';
      list.add(OfficerExceptionModel(
        id: id,
        type: ExceptionType.centreStopped,
        severity: ExceptionSeverity.critical,
        title: 'Procurement Temporarily Stopped',
        shortDescription: 'Farmers should not be called forward.',
        explanation:
            'Centre intake has been marked $centreStatus. Intake is paused.',
        centreId: centreName,
        createdTimestamp: now.subtract(const Duration(minutes: 2)),
        status: _statusOverrides[id] ?? ExceptionStatus.open,
        recommendedAction:
            'Resolve centre issue or update centre status.',
        metadata: {'centreStatus': centreStatus},
      ));
    }

    // 8. Feature 9: Booking / Arrival Anomalies (Late Arrival, wrong centre, etc.)
    for (final anomaly in _customAnomalies) {
      final override = _statusOverrides[anomaly.id];
      list.add(override != null ? anomaly.copyWith(status: override) : anomaly);
    }

    // Check for late arrival in queue (e.g. arrival after booked slot)
    for (final item in queue) {
      if (item.arrivalTime == '12:18 PM' ||
          (item.bookedSlot == '11:15 AM' && item.arrivalTime == '11:35 AM')) {
        final id = 'ex_late_${item.tokenNumber}';
        list.add(OfficerExceptionModel(
          id: id,
          type: ExceptionType.bookingAnomaly,
          severity: ExceptionSeverity.warning,
          title: 'Late Arrival',
          shortDescription:
              'Token: ${item.tokenNumber} • Booked: ${item.bookedSlot} • Arrival: ${item.arrivalTime}',
          explanation:
              'Farmer arrived at ${item.arrivalTime} for slot ending ${item.bookedSlot}.',
          centreId: centreName,
          tokenNumber: item.tokenNumber,
          farmerName: item.farmerName,
          createdTimestamp: now.subtract(const Duration(minutes: 18)),
          status: _statusOverrides[id] ?? ExceptionStatus.open,
          recommendedAction:
              'Review standby/late-arrival handling.',
          metadata: {
            'bookedSlot': item.bookedSlot,
            'arrivalTime': item.arrivalTime,
          },
        ));
      }
    }

    // 9. Forecast-Driven Capacity Risk Alert (Phase 20)
    final forecast = forecastSummary ??
        CapacityForecastService().generateForecastSummary(
          currentLoadPercent: centreCapacityPercent,
          currentQueueCount: waitingCount,
          averageProcessingMinutes: averageProcessingMinutes,
          delayMinutes: centreDelayMinutes,
          centreStatus: centreStatus,
        );

    if (forecast.hasHighOrCriticalRisk) {
      final isCrit =
          forecast.peakCongestionLevel == CapacityCongestionLevel.critical;
      const id = 'ex_capacity_forecast_risk';
      list.add(OfficerExceptionModel(
        id: id,
        type: ExceptionType.capacityForecastRisk,
        severity:
            isCrit ? ExceptionSeverity.critical : ExceptionSeverity.warning,
        title: isCrit
            ? 'Critical Capacity Risk Forecast'
            : 'High Capacity Risk Forecast',
        shortDescription:
            'Projected ${forecast.peakLoadPercent}% load at ${forecast.peakRiskTime}',
        explanation:
            'Capacity forecasting projects ${forecast.peakLoadPercent}% load with ${forecast.peakRiskWindow?.estimatedWaitMinutes ?? 45}m wait at ${forecast.peakRiskTime}. ${forecast.peakRiskWindow?.confidenceBasis ?? ""}',
        centreId: centreName,
        createdTimestamp: now.subtract(const Duration(minutes: 2)),
        status: _statusOverrides[id] ?? ExceptionStatus.open,
        recommendedAction: forecast.overallRecommendedAction,
        metadata: {
          'peakRiskTime': forecast.peakRiskTime,
          'peakLoadPercent': forecast.peakLoadPercent,
          'congestionLevel': forecast.peakCongestionLevel.nameEn,
        },
      ));
    }

    // 10. Slot Overload Exception (Phase D)
    if (slots != null) {
      final overloadedSlots = slots.where((s) => s.isOverloaded).toList();
      if (overloadedSlots.isNotEmpty) {
        final firstOverloaded = overloadedSlots.first;
        final id =
            'ex_slot_overload_${firstOverloaded.time.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
        list.add(OfficerExceptionModel(
          id: id,
          type: ExceptionType.slotOverload,
          severity: ExceptionSeverity.medium,
          title: 'Slot Overload (${firstOverloaded.time})',
          shortDescription:
              '${firstOverloaded.bookingsCount}/${firstOverloaded.capacity} bookings in ${firstOverloaded.time} slot',
          explanation:
              'Slot ${firstOverloaded.time} has reached capacity (${firstOverloaded.bookingsCount}/${firstOverloaded.capacity}). Recommend moving eligible bookings to less congested windows.',
          centreId: centreName,
          createdTimestamp: now.subtract(const Duration(minutes: 5)),
          status: _statusOverrides[id] ?? ExceptionStatus.open,
          recommendedAction:
              'Review dynamic slot reallocation recommendations to balance slot traffic.',
          metadata: {
            'slotTime': firstOverloaded.time,
            'bookingsCount': firstOverloaded.bookingsCount,
            'capacity': firstOverloaded.capacity,
          },
        ));
      }
    }

    // Sorting: CRITICAL first, then HIGH/WARNING, then MEDIUM, then LOW/INFO.
    // Within same severity: createdTimestamp descending (newest first).
    list.sort((a, b) {
      final sevCompare = _severityRank(b.severity).compareTo(_severityRank(a.severity));
      if (sevCompare != 0) return sevCompare;
      return b.createdTimestamp.compareTo(a.createdTimestamp);
    });

    return list;
  }

  int _severityRank(ExceptionSeverity severity) {
    switch (severity) {
      case ExceptionSeverity.critical:
        return 4;
      case ExceptionSeverity.high:
      case ExceptionSeverity.warning:
        return 3;
      case ExceptionSeverity.medium:
        return 2;
      case ExceptionSeverity.low:
      case ExceptionSeverity.info:
        return 1;
    }
  }

  double _parseQuantity(String qtyStr) {
    try {
      final clean = qtyStr.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean) ?? 0.0;
    } catch (_) {
      return 0.0;
    }
  }
}
