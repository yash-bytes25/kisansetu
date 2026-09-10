import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import '../models/alternative_centre_recommendation.dart';
import '../models/capacity_forecast_model.dart';
import '../models/crop_model.dart';
import '../models/farmer_dashboard_data.dart';
import '../models/farmer_dispute_report.dart';
import '../models/officer_exception_model.dart';
import '../models/officer_queue_item.dart';
import '../models/offline_essential_info_model.dart';
import '../models/procurement_centre.dart';
import '../models/procurement_slot_info.dart';
import '../models/slot_reallocation_model.dart';
import 'alternative_centre_service.dart';
import 'capacity_forecast_service.dart';
import 'connectivity_service.dart';
import 'notification_service.dart';
import 'offline_essential_info_service.dart';
import 'officer_exception_service.dart';
import 'payment_calculation_service.dart';
import 'queue_prediction_service.dart';
import 'repositories/repository_provider.dart';
import 'slot_reallocation_service.dart';
import 'smart_slot_service.dart';

/// Single source of truth for KisanSetu procurement operations and shared state.
///
/// Bridges the Procurement Officer operations dashboard and the Farmer mobile
/// application in-memory, structured for seamless integration with Supabase Realtime.
class ProcurementStateService extends ChangeNotifier {
  // Singleton pattern
  static final ProcurementStateService _instance =
      ProcurementStateService._internal();
  factory ProcurementStateService() => _instance;
  ProcurementStateService._internal() {
    reset();
    AppConnectivityService.instance.onConnectivityChanged.listen((isOnline) {
      if (isOnline && SupabaseConfig.shouldUseSupabase) {
        reconcileFromSupabase();
      }
    });
  }

  // Centre Configuration
  String _centreName = 'Example Procurement Centre';
  String _centreStatus = 'Open • Normal';
  int _centreCapacityPercent = 75;
  String _capacityMode = 'Normal';

  // KPIs
  int _todayBookingsCount = 24;
  int _arrivedCount = 16;
  int _waitingCount = 7;
  int _completedCount = 9;
  String _averageWait = '35 min';
  String _processingRate = '~2 farmers / 10 min';

  // Active Queue
  List<OfficerQueueItem> _queue = [];

  // Slots
  List<ProcurementSlotInfo> _slots = [];

  // Farmer's own state (Ramesh Kumar)
  late FarmerDashboardData _farmerData;

  // Disputes & Grievances
  final List<FarmerDisputeReport> _disputes = [];

  // Phase 13 Queue Intelligence attributes
  int _centreDelayMinutes = 0;
  int _averageProcessingMinutes = 5;

  // Phase 14: Officer Exceptions & Operational Alerts
  final OfficerExceptionService _exceptionService = OfficerExceptionService();

  // Getters
  String get centreName => _centreName;
  String get centreStatus => _centreStatus;
  int get centreCapacityPercent => _centreCapacityPercent;
  String get capacityMode => _capacityMode;
  int get centreDelayMinutes => _centreDelayMinutes;
  int get averageProcessingMinutes => _averageProcessingMinutes;

  int get todayBookingsCount => _todayBookingsCount;
  int get arrivedCount => _arrivedCount;
  int get waitingCount => _waitingCount;
  int get completedCount => _completedCount;
  String get averageWait => _averageWait;
  String get processingRate => _processingRate;

  List<OfficerQueueItem> get queue => List.unmodifiable(_queue);
  List<ProcurementSlotInfo> get slots => List.unmodifiable(_slots);
  FarmerDashboardData get farmerData => _farmerData;
  List<FarmerDisputeReport> get disputes => List.unmodifiable(_disputes);

  OfficerExceptionService get exceptionService => _exceptionService;
  List<OfficerExceptionModel> get exceptions =>
      _exceptionService.detectExceptionsFromState(this);
  int get criticalExceptionCount => _exceptionService.criticalCount(this);
  int get warningExceptionCount => _exceptionService.warningCount(this);
  int get openExceptionCount => _exceptionService.openCount(this);

  // Dynamic Slot Reallocation
  List<SlotReallocationRecommendation> get slotReallocations =>
      SlotReallocationService().getRecommendations(this);
  int get pendingSlotReallocationsCount =>
      SlotReallocationService().pendingCount(this);

  // Alternative Procurement Centre Recommendations
  int _farmerTravelTimeMinutes = 25;
  int get farmerTravelTimeMinutes => _farmerTravelTimeMinutes;

  List<AlternativeCentreRecommendation> get alternativeCentres =>
      AlternativeCentreService().getAlternativeCentres(
        currentCentreName: _centreName,
        currentWaitMinutes: _farmerData.expectedWaitMinutes,
        currentLoadPercent: _centreCapacityPercent,
        crop: _farmerData.cropName,
      );

  bool get isCurrentCentreOverloadedOrDelayed =>
      AlternativeCentreService().isCentreOverloadedOrDelayed(
        capacityPercent: _centreCapacityPercent,
        delayMinutes: _centreDelayMinutes,
        centreStatus: _centreStatus,
        waitMinutes: _farmerData.expectedWaitMinutes,
      );

  // Capacity Forecasting (Phase 20)
  CapacityForecastSummary get capacityForecastSummary =>
      CapacityForecastService().generateForecastSummary(
        currentLoadPercent: _centreCapacityPercent,
        currentQueueCount: _waitingCount,
        averageProcessingMinutes: _averageProcessingMinutes,
        delayMinutes: _centreDelayMinutes,
        centreStatus: _centreStatus,
        slots: _slots,
      );

  List<CapacityForecastModel> get capacityForecasts =>
      capacityForecastSummary.forecasts;

  // Offline-First Essential Information (Phase 21)
  OfflineEssentialInfoModel? get offlineEssentialInfo =>
      OfflineEssentialInfoService.instance.getCachedInfo();

  /// Forces an offline cache synchronization from live state.
  void syncOfflineCache() {
    OfflineEssentialInfoService.instance.cacheStateSync(
      farmerData: _farmerData,
      centreName: _centreName,
      notifications: NotificationService().notifications,
    );
    notifyListeners();
  }

  /// Resets state to default initial conditions (ideal for testing and new sessions).
  void reset() {
    _centreName = 'Example Procurement Centre';
    _centreStatus = 'Open • Normal';
    _centreCapacityPercent = 75;
    _capacityMode = 'Normal';

    _todayBookingsCount = 24;
    _arrivedCount = 16;
    _waitingCount = 7;
    _completedCount = 9;
    _averageWait = '35 min';
    _processingRate = '~2 farmers / 10 min';
    _centreDelayMinutes = 0;
    _averageProcessingMinutes = 5;
    _farmerTravelTimeMinutes = 25;

    _disputes.clear();
    NotificationService().reset();
    _exceptionService.reset();
    SlotReallocationService().reset();

    _slots = [
      const ProcurementSlotInfo(
        time: '10:30 AM',
        bookingsCount: 8,
        capacity: 12,
        recommendationTag: 'Good',
      ),
      const ProcurementSlotInfo(
        time: '11:30 AM',
        bookingsCount: 10,
        capacity: 12,
        recommendationTag: 'Recommended',
      ),
      const ProcurementSlotInfo(
        time: '01:00 PM',
        bookingsCount: 6,
        capacity: 12,
        recommendationTag: 'Busy',
      ),
    ];

    _queue = [
      const OfficerQueueItem(
        tokenNumber: 'TK-8490',
        farmerName: 'Sukhdev Singh',
        crop: 'Wheat',
        quantity: '40 Quintals',
        actualQuantity: '40.0 Quintals',
        qualityGrade: 'Grade A',
        bookedSlot: '11:00 AM',
        arrivalTime: '10:50 AM',
        status: 'Waiting',
        peopleAhead: 1,
        approxWaitMinutes: 5,
        grossAmount: 91000.0,
        deductions: 0.0,
        netPayable: 91000.0,
        paymentStatus: 'Pending',
        paymentReference: 'PAY-2026-8490',
        paymentDate: '09 Sep 2026',
        checkInStatus: 'Checked In',
      ),
      const OfficerQueueItem(
        tokenNumber: 'TK-8491',
        farmerName: 'Balwinder Kaur',
        crop: 'Paddy',
        quantity: '65 Quintals',
        actualQuantity: '65.0 Quintals',
        qualityGrade: 'FAQ',
        bookedSlot: '11:15 AM',
        arrivalTime: '11:05 AM',
        status: 'Sampling',
        peopleAhead: 2,
        approxWaitMinutes: 10,
        grossAmount: 149500.0,
        deductions: 0.0,
        netPayable: 149500.0,
        paymentStatus: 'Pending',
        paymentReference: 'PAY-2026-8491',
        paymentDate: '09 Sep 2026',
        checkInStatus: 'Checked In',
      ),
      const OfficerQueueItem(
        tokenNumber: 'TK-8492',
        farmerName: 'Ramesh Kumar',
        crop: 'Wheat',
        quantity: '50 Quintals',
        actualQuantity: '50.2 Quintals',
        qualityGrade: 'FAQ',
        bookedSlot: '11:30 AM',
        arrivalTime: '11:20 AM',
        status: 'Waiting',
        peopleAhead: 7,
        approxWaitMinutes: 35,
        grossAmount: 114205.0,
        deductions: 0.0,
        netPayable: 114205.0,
        paymentStatus: 'Pending',
        paymentReference: 'PAY-2026-8492',
        paymentDate: '09 Sep 2026',
        discrepancyNote:
            'Actual weighment exceeds registered quantity by +0.2 Quintals.',
        checkInStatus: 'Not Checked In',
      ),
      const OfficerQueueItem(
        tokenNumber: 'TK-8493',
        farmerName: 'Harpreet Singh',
        crop: 'Wheat',
        quantity: '45 Quintals',
        actualQuantity: '45.0 Quintals',
        qualityGrade: 'FAQ',
        bookedSlot: '11:45 AM',
        arrivalTime: 'Not arrived',
        status: 'Booked',
        peopleAhead: 8,
        approxWaitMinutes: 40,
        grossAmount: 102375.0,
        deductions: 0.0,
        netPayable: 102375.0,
        paymentStatus: 'Pending',
        paymentReference: 'PAY-2026-8493',
        paymentDate: '09 Sep 2026',
        checkInStatus: 'Not Checked In',
      ),
    ];

    _recalculateFarmerData();
    notifyListeners();
  }

  /// Recalculates Ramesh Kumar's FarmerDashboardData using QueuePredictionService.
  void _recalculateFarmerData() {
    final rameshQueueIndex =
        _queue.indexWhere((q) => q.farmerName == 'Ramesh Kumar');

    int peopleAhead = 7;
    String status = 'Waiting';
    String token = 'TK-8492';
    String bookedSlot = '11:30 AM';
    String crop = 'Wheat';
    String quantity = '50 Quintals';
    String actualQuantity = '50.2 Quintals';
    String qualityGrade = 'FAQ';
    double grossAmount = 114205.0;
    double netPayable = 114205.0;
    String paymentStatus = 'Pending';
    String paymentReference = 'PAY-2026-8492';
    String paymentDate = '09 Sep 2026';
    String checkInStatus = 'Not Checked In';
    String? actualArrivalTime;

    if (rameshQueueIndex != -1) {
      final ramesh = _queue[rameshQueueIndex];
      peopleAhead = ramesh.peopleAhead;
      status = ramesh.status;
      token = ramesh.tokenNumber;
      bookedSlot = ramesh.bookedSlot;
      crop = ramesh.crop;
      quantity = ramesh.quantity;
      actualQuantity = ramesh.actualQuantity;
      qualityGrade = ramesh.qualityGrade;
      grossAmount = ramesh.grossAmount;
      netPayable = ramesh.netPayable;
      paymentStatus = ramesh.paymentStatus;
      paymentReference = ramesh.paymentReference ?? 'PAY-2026-8492';
      paymentDate = ramesh.paymentDate ?? '09 Sep 2026';
      checkInStatus = ramesh.checkInStatus;
      actualArrivalTime =
          ramesh.arrivalTime != 'Not arrived' ? ramesh.arrivalTime : null;
    }

    final prediction = QueuePredictionService.predict(
      peopleAhead: peopleAhead,
      centreStatus: _centreStatus,
      slotTime: bookedSlot,
      travelTimeMinutes: _farmerTravelTimeMinutes,
      processingTimePerFarmer: _averageProcessingMinutes,
      currentDelayOverrideMinutes:
          _centreDelayMinutes > 0 ? _centreDelayMinutes : null,
      centreCapacityPercent: _centreCapacityPercent,
      isFarmerCheckedIn: checkInStatus == 'Checked In',
    );

    _farmerData = FarmerDashboardData(
      farmerName: 'Ramesh Kumar',
      cropName: crop,
      quantity: quantity,
      centreName: _centreName,
      tokenNumber: token,
      peopleAhead: prediction.peopleAhead,
      totalInQueue: _queue.where((q) => q.status != 'Completed').length,
      travelTimeMinutes: _farmerTravelTimeMinutes,
      expectedWaitMinutes: prediction.estimatedWaitMinutes,
      recommendedDepartureTime: prediction.recommendedDepartureTime,
      expectedTurnTime: prediction.expectedTurnTime,
      centreStatus: _centreStatus,
      paymentStatus: paymentStatus,
      isGoodTimeToLeave: prediction.isGoodTimeToLeave,
      waitReason: prediction.statusReasonEn,
      waitRecommendedArrival: prediction.recommendedArrivalTime,
      bookedSlotTime: bookedSlot,
      lifecycleStatus: status,
      estimatedMspValue: '₹1,13,750',
      actualQuantity: actualQuantity,
      qualityGrade: qualityGrade,
      grossAmount: grossAmount,
      netPayable: netPayable,
      paymentReference: paymentReference,
      paymentDate: paymentDate,
      disputeCount: _disputes.length,
      checkInStatus: checkInStatus,
      actualArrivalTime: actualArrivalTime,
      recommendation: prediction.recommendation,
      centreLoadPercentage: prediction.centreLoadPercentage,
      confidence: prediction.confidence,
      isLateArrival: prediction.isLateArrival,
      delayMinutes: prediction.currentDelayMinutes,
      averageProcessingMinutes: prediction.averageProcessingMinutes,
    );

    // Sync offline cache whenever live state updates while online
    if (AppConnectivityService.instance.isOnline) {
      OfflineEssentialInfoService.instance.cacheStateSync(
        farmerData: _farmerData,
        centreName: _centreName,
        notifications: NotificationService().notifications,
      );
    }
  }

  /// Sets the centre delay in minutes and recalculates queue metrics.
  void setCentreDelay(int delayMinutes) {
    _centreDelayMinutes = delayMinutes;
    _averageWait = '${(7 * _averageProcessingMinutes) + delayMinutes} min';
    _recalculateFarmerData();
    if (delayMinutes > 0) {
      NotificationService().notifyCentreDelay(
        tokenNumber: _farmerData.tokenNumber,
        delayMinutes: delayMinutes,
        updatedDeparture: _farmerData.recommendedDepartureTime,
      );
    }
    notifyListeners();
  }

  /// Sets centre delay in minutes (alias for repository and external drivers).
  void setCentreDelayMinutes(int delayMinutes) => setCentreDelay(delayMinutes);

  /// Sets centre capacity load percent directly.
  void setCentreCapacityPercent(int percent) {
    _centreCapacityPercent = percent.clamp(10, 100);
    _recalculateFarmerData();
    notifyListeners();
  }

  /// Sets average processing minutes per farmer (e.g. 5 min).
  void setAverageProcessingMinutes(int minutes) {
    _averageProcessingMinutes = minutes > 0 ? minutes : 5;
    _processingRate = '~${10 ~/ _averageProcessingMinutes} farmers / 10 min';
    _recalculateFarmerData();
    notifyListeners();
  }

  /// Updates the farmer's produce crop and expected quantity.
  ///
  /// Recalculates estimated MSP value, updates queue data for Ramesh Kumar,
  /// triggers a proactive notification, and notifies all UI listeners.
  void changeFarmerCrop({
    required CropModel crop,
    required double quantityQuintals,
  }) {
    final qtyStr = quantityQuintals.truncateToDouble() == quantityQuintals
        ? '${quantityQuintals.toInt()} Quintals'
        : '${quantityQuintals.toStringAsFixed(1)} Quintals';
    final actualQtyStr = '${quantityQuintals.toStringAsFixed(1)} Quintals';

    // Calculate dynamic MSP using PaymentCalculationService
    final calc = PaymentCalculationService.calculate(
      acceptedQuantity: quantityQuintals,
      crop: crop.cropName,
      qualityGrade: _farmerData.qualityGrade,
    );

    final mspFormatted =
        PaymentCalculationService.formatCurrency(calc.netPayable);

    // Update _farmerData
    _farmerData = _farmerData.copyWith(
      cropName: crop.cropName,
      quantity: qtyStr,
      actualQuantity: actualQtyStr,
      grossAmount: calc.grossAmount,
      netPayable: calc.netPayable,
      estimatedMspValue: mspFormatted,
    );

    // Update Ramesh's queue item if in queue
    final rameshIndex =
        _queue.indexWhere((q) => q.farmerName == 'Ramesh Kumar');
    if (rameshIndex != -1) {
      _queue[rameshIndex] = _queue[rameshIndex].copyWith(
        crop: crop.cropName,
        quantity: qtyStr,
        actualQuantity: actualQtyStr,
        grossAmount: calc.grossAmount,
        netPayable: calc.netPayable,
      );
    }

    // Proactive transparent notification
    NotificationService().notifyCropChanged(
      cropNameEn: crop.cropName,
      cropNameHi: crop.nameHi,
      cropNameTe: crop.nameTe,
      quantity: qtyStr,
      estimatedMsp: mspFormatted,
      tokenNumber: _farmerData.tokenNumber,
    );

    // Persist crop selection to repository (Supabase in cloud mode / local in-memory)
    RepositoryProvider.farmer.saveFarmerProduce(
      farmerId: '22222222-2222-2222-2222-222222222222',
      crop: crop.cropName,
      quantity: quantityQuintals,
    );
    syncOfflineCache();

    notifyListeners();
  }

  /// Sets people ahead directly for Ramesh Kumar and updates state.
  void setPeopleAhead(int newAhead) {
    final index = _queue.indexWhere((q) => q.farmerName == 'Ramesh Kumar');
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        peopleAhead: newAhead,
        approxWaitMinutes:
            (newAhead * _averageProcessingMinutes) + _centreDelayMinutes,
      );
      _recalculateFarmerData();
      notifyListeners();
    }
  }

  /// Steps to next discrete queue simulation step [7, 5, 3, 1, 0].
  void simulateNextQueueStep() {
    const steps = [7, 5, 3, 1, 0];
    final currentAhead = _farmerData.peopleAhead;
    final currentIndex = steps.indexOf(currentAhead);
    final nextIndex = (currentIndex + 1) % steps.length;
    final nextAhead = steps[nextIndex];

    setPeopleAhead(nextAhead);

    NotificationService().notifyQueueUpdate(
      tokenNumber: _farmerData.tokenNumber,
      peopleAhead: nextAhead,
      estimatedWait: '${_farmerData.expectedWaitMinutes} min',
    );

    if (nextAhead <= 3) {
      NotificationService().notifyWhenToLeave(
        tokenNumber: _farmerData.tokenNumber,
        departureTime: _farmerData.recommendedDepartureTime,
        expectedTurn: _farmerData.expectedTurnTime,
      );
    }

    if (nextAhead == 3 || nextAhead == 1) {
      NotificationService().notifyQueueImprovement(
        tokenNumber: _farmerData.tokenNumber,
        waitMinutes: _farmerData.expectedWaitMinutes,
      );
    }
  }

  /// Updates centre status and immediately triggers queue recalculation.
  void setCentreStatus(String newStatus) {
    if (_centreStatus == newStatus) return;
    _centreStatus = newStatus;

    int offset = 0;
    if (newStatus == 'Open • Busy') {
      offset = 20;
      _centreDelayMinutes = 20;
    } else if (newStatus == 'Temporarily Delayed') {
      offset = 45;
      _centreDelayMinutes = 45;
    } else if (newStatus.contains('Stopped') || newStatus.contains('Closed')) {
      offset = 60;
      _centreDelayMinutes = 60;
    } else {
      _centreDelayMinutes = 0;
    }

    _queue = _queue.map((item) {
      final newWait = (item.peopleAhead * _averageProcessingMinutes) + offset;
      return item.copyWith(approxWaitMinutes: newWait);
    }).toList();

    _averageWait = '${(7 * _averageProcessingMinutes) + offset} min';
    _recalculateFarmerData();

    if (newStatus == 'Open • Busy') {
      NotificationService().notifyCentreStatus(
        status: newStatus,
        reasonEn:
            'Centre is currently busy. Your recommended arrival time has changed.',
        reasonHi:
            'केंद्र वर्तमान में व्यस्त है। आपका अनुशंसित आगमन समय बदल गया है।',
        tokenNumber: _farmerData.tokenNumber,
      );
    } else if (newStatus == 'Temporarily Delayed') {
      NotificationService().notifyCentreStatus(
        status: newStatus,
        reasonEn:
            'Procurement is temporarily delayed. Please wait for the updated recommendation.',
        reasonHi:
            'खरीद प्रक्रिया अस्थायी रूप से विलंबित है। कृपया अद्यतन अनुशंसा की प्रतीक्षा करें।',
        tokenNumber: _farmerData.tokenNumber,
      );
    } else if (newStatus.contains('Stopped') || newStatus.contains('Closed')) {
      NotificationService().notifyCentreStopped(
        tokenNumber: _farmerData.tokenNumber,
      );
    }

    notifyListeners();
  }

  /// Sets capacity utilization mode (Normal 75%, Busy 85%, High Load 95%).
  void setCapacityMode(String mode) {
    _capacityMode = mode;
    if (mode == 'Normal') {
      _centreCapacityPercent = 75;
    } else if (mode == 'Busy') {
      _centreCapacityPercent = 85;
    } else if (mode == 'High Load') {
      _centreCapacityPercent = 95;
    }
    notifyListeners();
  }

  /// Adjusts capacity for a specific slot.
  void adjustSlotCapacity(String slotTime, int newCapacity) {
    final index = _slots.indexWhere((s) => s.time == slotTime);
    if (index != -1) {
      _slots[index] = _slots[index].copyWith(capacity: newCapacity);
      notifyListeners();
    }
  }

  /// Called by Officer: "Call Next Farmer"
  void callNextFarmer() {
    int activeIndex = -1;

    for (int i = 0; i < _queue.length; i++) {
      if (_queue[i].status != 'Completed') {
        activeIndex = i;
        break;
      }
    }

    if (activeIndex != -1) {
      final current = _queue[activeIndex];
      if (current.status == 'Waiting' || current.status == 'Arrived') {
        _queue[activeIndex] = current.copyWith(status: 'Sampling');
      } else if (current.status == 'Sampling' ||
          current.status == 'Quality Check') {
        _queue[activeIndex] = current.copyWith(status: 'Completed');
        _completedCount++;
        if (_waitingCount > 0) _waitingCount--;
      } else {
        _queue[activeIndex] = current.copyWith(status: 'Completed');
        _completedCount++;
        if (_waitingCount > 0) _waitingCount--;
      }
    }

    for (int i = 0; i < _queue.length; i++) {
      if (_queue[i].status != 'Completed' && _queue[i].peopleAhead > 0) {
        final newAhead = _queue[i].peopleAhead - 1;
        final newWait = newAhead * 5;
        _queue[i] = _queue[i].copyWith(
          peopleAhead: newAhead,
          approxWaitMinutes: newWait,
        );
      }
    }

    _recalculateFarmerData();
    NotificationService().notifyQueueUpdate(
      tokenNumber: _farmerData.tokenNumber,
      peopleAhead: _farmerData.peopleAhead,
      estimatedWait: '${_farmerData.expectedWaitMinutes} min',
    );
    if (_farmerData.peopleAhead <= 3) {
      NotificationService().notifyWhenToLeave(
        tokenNumber: _farmerData.tokenNumber,
        departureTime: _farmerData.recommendedDepartureTime,
        expectedTurn: _farmerData.expectedTurnTime,
      );
    }
    RepositoryProvider.queue.advanceQueue(_farmerData.tokenNumber);
    notifyListeners();
  }

  /// Checks in a farmer upon scanning their valid QR pass.
  /// Transitions state: BOOKED -> CHECKED_IN -> WAITING / PROCESSING.
  /// Records arrival timestamp, increments arrived count if previously unarrived,
  /// and updates farmer UI and notifications.
  bool checkInFarmer(String tokenNumber, {String? arrivalTime}) {
    final index = _queue.indexWhere((q) => q.tokenNumber == tokenNumber);
    final timeStr = arrivalTime ?? '11:18 AM';

    if (index != -1) {
      final item = _queue[index];
      if (item.checkInStatus == 'Checked In') {
        return false;
      }

      final wasBooked = item.status == 'Booked';
      if (wasBooked) {
        _arrivedCount++;
        _waitingCount++;
      }

      _queue[index] = item.copyWith(
        checkInStatus: 'Checked In',
        status: wasBooked ? 'Waiting' : item.status,
        arrivalTime: timeStr,
      );

      _recalculateFarmerData();
      NotificationService().notifyCheckInConfirmed(
        tokenNumber: tokenNumber,
        centreName: _centreName,
        arrivalTime: timeStr,
      );
      RepositoryProvider.booking.updateBookingStatus(
        tokenNumber,
        BookingLifecycleStatus.checkedIn,
      );
      RepositoryProvider.queue.createQueueEntry(
        bookingId: tokenNumber,
        status: 'waiting',
        position: _farmerData.peopleAhead + 1,
        peopleAhead: _farmerData.peopleAhead,
        estimatedWaitMinutes: _farmerData.expectedWaitMinutes,
        expectedTurn: _farmerData.expectedTurnTime,
      );
      notifyListeners();
      return true;
    } else if (tokenNumber == _farmerData.tokenNumber) {
      _farmerData = _farmerData.copyWith(
        checkInStatus: 'Checked In',
        actualArrivalTime: timeStr,
        lifecycleStatus: _farmerData.lifecycleStatus == 'Booked'
            ? 'Waiting'
            : _farmerData.lifecycleStatus,
      );
      NotificationService().notifyCheckInConfirmed(
        tokenNumber: tokenNumber,
        centreName: _centreName,
        arrivalTime: timeStr,
      );
      RepositoryProvider.booking.updateBookingStatus(
        tokenNumber,
        BookingLifecycleStatus.checkedIn,
      );
      RepositoryProvider.queue.createQueueEntry(
        bookingId: tokenNumber,
        status: 'waiting',
        position: _farmerData.peopleAhead + 1,
        peopleAhead: _farmerData.peopleAhead,
        estimatedWaitMinutes: _farmerData.expectedWaitMinutes,
        expectedTurn: _farmerData.expectedTurnTime,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Officer action: Mark Arrived
  void markArrived(String tokenNumber) {
    final index = _queue.indexWhere((q) => q.tokenNumber == tokenNumber);
    if (index != -1) {
      final item = _queue[index];
      if (item.status == 'Booked') {
        _arrivedCount++;
        _waitingCount++;
      }
      _queue[index] = item.copyWith(
        status: 'Waiting',
        arrivalTime: '11:20 AM',
        checkInStatus: 'Checked In',
      );
      _recalculateFarmerData();
      notifyListeners();
    }
  }

  /// Officer action: Start Processing / Advance to Quality Check
  void startProcessing(String tokenNumber) {
    final index = _queue.indexWhere((q) => q.tokenNumber == tokenNumber);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(status: 'Quality Check');
      _recalculateFarmerData();
      notifyListeners();
    }
  }

  /// Phase 8: Officer action to confirm Quality Grade.
  void confirmQuality(String tokenNumber, String grade) {
    final index = _queue.indexWhere((q) => q.tokenNumber == tokenNumber);
    if (index != -1) {
      final item = _queue[index];
      final actualQ = double.tryParse(
              item.actualQuantity.replaceAll(RegExp(r'[^0-9.]'), '')) ??
          50.2;
      final calc = PaymentCalculationService.calculate(
        acceptedQuantity: actualQ,
        crop: item.crop,
        qualityGrade: grade,
      );

      String newStatus = item.status;
      if (item.status == 'Quality Check' || item.status == 'Sampling') {
        newStatus = 'Weighment';
      }

      _queue[index] = item.copyWith(
        qualityGrade: grade,
        status: newStatus,
        grossAmount: calc.grossAmount,
        netPayable: calc.netPayable,
      );
      _recalculateFarmerData();
      NotificationService().notifyProcurementProcessing(
        stageName: 'Quality Grade $grade',
        detailsEn: 'Quality assessment confirmed as $grade.',
        detailsHi: 'गुणवत्ता मूल्यांकन $grade के रूप में स्वीकृत किया गया।',
        tokenNumber: tokenNumber,
      );
      RepositoryProvider.procurement.recordWeighmentAndGrade(
        bookingId: tokenNumber,
        actualQty: actualQ,
        grade: grade,
        hasDiscrepancy: false,
      );
      notifyListeners();
    }
  }

  /// Phase 8: Officer action to record and confirm actual weighment.
  void confirmWeighment(String tokenNumber, double actualWeight) {
    final index = _queue.indexWhere((q) => q.tokenNumber == tokenNumber);
    if (index != -1) {
      final item = _queue[index];
      final expectedQ = double.tryParse(
              item.quantity.replaceAll(RegExp(r'[^0-9.]'), '')) ??
          50.0;
      final diff = actualWeight - expectedQ;
      final discrepancy = diff.abs() > 0.05
          ? 'Actual quantity differs from booked quantity by ${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)} Quintals.'
          : null;

      final calc = PaymentCalculationService.calculate(
        acceptedQuantity: actualWeight,
        crop: item.crop,
        qualityGrade: item.qualityGrade,
      );

      String newStatus = item.status;
      if (item.status == 'Weighment' || item.status == 'Quality Check') {
        newStatus = 'Accepted';
      }

      _queue[index] = item.copyWith(
        actualQuantity: '${actualWeight.toStringAsFixed(1)} Quintals',
        grossAmount: calc.grossAmount,
        netPayable: calc.netPayable,
        discrepancyNote: discrepancy,
        status: newStatus,
      );
      _recalculateFarmerData();
      NotificationService().notifyProcurementProcessing(
        stageName: 'Weighment Completed',
        detailsEn:
            'Actual weight recorded as ${actualWeight.toStringAsFixed(1)} Quintals.',
        detailsHi:
            'वास्तविक वजन ${actualWeight.toStringAsFixed(1)} क्विंटल दर्ज किया गया।',
        tokenNumber: tokenNumber,
      );
      RepositoryProvider.procurement.recordWeighmentAndGrade(
        bookingId: tokenNumber,
        actualQty: actualWeight,
        grade: item.qualityGrade,
        hasDiscrepancy: discrepancy != null,
        previousWeight: expectedQ,
      );
      notifyListeners();
    }
  }

  /// Phase 8: Officer action: Accept Produce
  void acceptProduce(String tokenNumber) {
    final index = _queue.indexWhere((q) => q.tokenNumber == tokenNumber);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(status: 'Accepted');
      _recalculateFarmerData();
      NotificationService().notifyProcurementAccepted(
        crop: _queue[index].crop,
        quantity: _queue[index].actualQuantity,
        tokenNumber: tokenNumber,
      );
      notifyListeners();
    }
  }

  /// Phase 8: Officer action: Initiate Payment
  void initiatePayment(String tokenNumber) {
    final index = _queue.indexWhere((q) => q.tokenNumber == tokenNumber);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        paymentStatus: 'Processing',
        status: 'Payment Pending',
      );
      _recalculateFarmerData();
      NotificationService().notifyPaymentInitiated(
        amount: _queue[index].netPayable,
        reference: _queue[index].paymentReference ??
            'PAY-2026-${tokenNumber.replaceAll('TK-', '')}',
        tokenNumber: tokenNumber,
      );
      RepositoryProvider.payment.authorizePayment(
        bookingId: tokenNumber,
        grossAmount: _queue[index].grossAmount,
        deductions: _queue[index].deductions,
        netAmount: _queue[index].netPayable,
        reference: _queue[index].paymentReference ??
            'PAY-2026-${tokenNumber.replaceAll('TK-', '')}',
      );
      notifyListeners();
    }
  }

  /// Phase 8: Officer action: Mark Payment Completed
  void markPaymentCompleted(String tokenNumber) {
    final index = _queue.indexWhere((q) => q.tokenNumber == tokenNumber);
    if (index != -1) {
      final ref = 'PAY-2026-${tokenNumber.replaceAll('TK-', '')}';
      _queue[index] = _queue[index].copyWith(
        paymentStatus: 'Completed',
        paymentReference: ref,
        paymentDate: '09 Sep 2026',
        status: 'Completed',
      );
      _completedCount++;
      if (_waitingCount > 0) _waitingCount--;

      _recalculateFarmerData();
      NotificationService().notifyPaymentCompleted(
        amount: _queue[index].netPayable,
        reference: ref,
        tokenNumber: tokenNumber,
      );
      notifyListeners();
    }
  }

  /// Phase 8: Farmer action to submit a dispute / report a problem
  void submitDispute({
    required String tokenNumber,
    required String reason,
    String? explanation,
  }) {
    final farmerName = _farmerData.farmerName;
    final report = FarmerDisputeReport(
      id: 'DISP-${DateTime.now().millisecondsSinceEpoch}',
      tokenNumber: tokenNumber,
      farmerName: farmerName,
      reason: reason,
      explanation: explanation,
      submittedAt: DateTime.now(),
      status: 'Submitted',
    );

    _disputes.add(report);
    _recalculateFarmerData();
    NotificationService().notifyDisputeSubmitted(
      disputeId: report.id,
      category: reason,
      tokenNumber: tokenNumber,
    );
    RepositoryProvider.dispute.submitDispute(
      farmerId: '22222222-2222-2222-2222-222222222222',
      bookingId: tokenNumber,
      category: reason,
      description: explanation ?? '',
    );
    notifyListeners();
  }

  /// Advances a farmer through the 7-stage procurement lifecycle:
  /// Booked -> Arrived -> Quality Check -> Weighment -> Accepted -> Payment Pending -> Completed
  void advanceLifecycle(String tokenNumber) {
    final index = _queue.indexWhere((q) => q.tokenNumber == tokenNumber);
    if (index == -1) return;

    final item = _queue[index];
    String nextStatus;
    switch (item.status) {
      case 'Booked':
        nextStatus = 'Arrived';
        _arrivedCount++;
        _waitingCount++;
        break;
      case 'Arrived':
      case 'Waiting':
        nextStatus = 'Quality Check';
        break;
      case 'Quality Check':
      case 'Sampling':
        nextStatus = 'Weighment';
        break;
      case 'Weighment':
        nextStatus = 'Accepted';
        break;
      case 'Accepted':
        nextStatus = 'Payment Pending';
        break;
      case 'Payment Pending':
        nextStatus = 'Completed';
        _completedCount++;
        if (_waitingCount > 0) _waitingCount--;
        break;
      default:
        nextStatus = 'Completed';
    }

    _queue[index] = item.copyWith(status: nextStatus);
    _recalculateFarmerData();
    if (nextStatus == 'Accepted') {
      NotificationService().notifyProcurementAccepted(
        crop: _queue[index].crop,
        quantity: _queue[index].actualQuantity,
        tokenNumber: tokenNumber,
      );
    } else if (nextStatus == 'Completed') {
      NotificationService().notifyPaymentCompleted(
        amount: _queue[index].netPayable,
        reference: _queue[index].paymentReference ??
            'PAY-2026-${tokenNumber.replaceAll('TK-', '')}',
        tokenNumber: tokenNumber,
      );
    } else {
      NotificationService().notifyProcurementProcessing(
        stageName: nextStatus,
        detailsEn: 'Procurement progressed to $nextStatus stage.',
        detailsHi: 'खरीद प्रक्रिया $nextStatus चरण में आगे बढ़ी।',
        tokenNumber: tokenNumber,
      );
    }
    notifyListeners();
  }

  /// Officer action: Complete Procurement
  void completeProcurement(String tokenNumber) {
    final index = _queue.indexWhere((q) => q.tokenNumber == tokenNumber);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        status: 'Completed',
        paymentStatus: 'Completed',
      );
      _completedCount++;
      if (_waitingCount > 0) _waitingCount--;
      _recalculateFarmerData();
      NotificationService().notifyProcurementAccepted(
        crop: _queue[index].crop,
        quantity: _queue[index].actualQuantity,
        tokenNumber: tokenNumber,
      );
      NotificationService().notifyPaymentCompleted(
        amount: _queue[index].netPayable,
        reference: _queue[index].paymentReference ??
            'PAY-2026-${tokenNumber.replaceAll('TK-', '')}',
        tokenNumber: tokenNumber,
      );
      notifyListeners();
    }
  }

  /// Synchronizes booking performed by Ramesh Kumar from the Farmer Book Slot flow.
  void updateFarmerBooking({
    required String centreName,
    required String bookedSlot,
    required String tokenNumber,
    required String crop,
    required String quantity,
  }) {
    if (!AppConnectivityService.instance.isOnline) {
      throw StateError('Cannot create or confirm a new booking while offline.');
    }
    _centreName = centreName;
    _todayBookingsCount++;

    final index = _queue.indexWhere((q) => q.farmerName == 'Ramesh Kumar');
    final newItem = OfficerQueueItem(
      tokenNumber: tokenNumber,
      farmerName: 'Ramesh Kumar',
      crop: crop,
      quantity: quantity,
      actualQuantity: '50.2 Quintals',
      qualityGrade: 'FAQ',
      bookedSlot: bookedSlot,
      arrivalTime: '11:20 AM',
      status: 'Waiting',
      peopleAhead: 7,
      approxWaitMinutes: 35,
      grossAmount: 114205.0,
      deductions: 0.0,
      netPayable: 114205.0,
      paymentStatus: 'Pending',
      paymentReference: 'PAY-2026-${tokenNumber.replaceAll('TK-', '')}',
      paymentDate: '09 Sep 2026',
      checkInStatus: 'Not Checked In',
    );

    if (index != -1) {
      _queue[index] = newItem;
    } else {
      _queue.add(newItem);
    }

    _recalculateFarmerData();
    NotificationService().notifyBookingConfirmed(
      tokenNumber: tokenNumber,
      slotTime: bookedSlot,
      centreName: centreName,
    );
    final double qtyNum = double.tryParse(quantity.split(' ').first) ?? 50.0;
    RepositoryProvider.booking.createBooking(
      farmerId: '22222222-2222-2222-2222-222222222222',
      centreId: centreName,
      crop: crop,
      quantity: qtyNum,
      slotTime: bookedSlot,
      token: tokenNumber,
    );
    notifyListeners();
  }

  /// Phase 14: Acknowledges an operational exception.
  void acknowledgeException(String id) {
    _exceptionService.acknowledge(id);
    notifyListeners();
  }

  /// Phase 14: Resolves an operational exception.
  void resolveException(String id) {
    _exceptionService.resolve(id);
    notifyListeners();
  }

  /// Phase 14: Injects a custom anomaly (e.g. for testing or external events).
  void addCustomAnomaly(OfficerExceptionModel anomaly) {
    _exceptionService.addCustomAnomaly(anomaly);
    notifyListeners();
  }

  /// Dynamic Slot Reallocation:
  /// Reallocates a farmer's booked slot to an optimal alternative slot at the same centre
  /// upon Procurement Officer confirmation.
  void reallocateFarmerSlot({
    required String tokenNumber,
    required String newSlot,
    required String reasonEn,
    String? reasonHi,
    String? reasonTe,
  }) {
    final queueIndex = _queue.indexWhere((q) => q.tokenNumber == tokenNumber);
    if (queueIndex == -1) return;

    final oldItem = _queue[queueIndex];
    final oldSlot = oldItem.bookedSlot;

    // Update queue item with the new slot
    _queue[queueIndex] = oldItem.copyWith(bookedSlot: newSlot);

    // Shift slot booking counts if old and new slots exist in _slots
    String cleanTime(String t) => t.trim().replaceAll(RegExp(r'^0'), '');
    for (int i = 0; i < _slots.length; i++) {
      if (cleanTime(_slots[i].time) == cleanTime(oldSlot) &&
          _slots[i].bookingsCount > 0) {
        _slots[i] =
            _slots[i].copyWith(bookingsCount: _slots[i].bookingsCount - 1);
      } else if (cleanTime(_slots[i].time) == cleanTime(newSlot)) {
        _slots[i] =
            _slots[i].copyWith(bookingsCount: _slots[i].bookingsCount + 1);
      }
    }

    _recalculateFarmerData();

    // Mark recommendation as reallocated if tracked
    final recId = 'realloc_$tokenNumber';
    SlotReallocationService().markReallocated(recId);

    // Send trilingual notification to the farmer
    NotificationService().notifySlotReallocated(
      tokenNumber: tokenNumber,
      oldSlot: oldSlot,
      newSlot: newSlot,
      centreName: _centreName,
      reasonEn: reasonEn,
      reasonHi: reasonHi,
      reasonTe: reasonTe,
      newDepartureTime: _farmerData.recommendedDepartureTime,
    );

    notifyListeners();
  }

  /// Alternative Procurement Centre Switch:
  /// Farmer explicitly confirms switching to a recommended alternative procurement centre.
  void switchFarmerProcurementCentre({
    required ProcurementCentre newCentre,
    required String newSlot,
  }) {
    if (!AppConnectivityService.instance.isOnline) {
      throw StateError('Cannot switch procurement centres while offline.');
    }
    final oldCentreName = _centreName;
    _centreName = newCentre.name;
    _centreStatus = newCentre.status;
    final cap = newCentre.capacity > 0 ? newCentre.capacity : 100;
    _centreCapacityPercent =
        ((newCentre.todayQueueCount / cap) * 100).round().clamp(10, 100);
    _centreDelayMinutes = 0; // Fresh centre reset
    _farmerTravelTimeMinutes =
        (newCentre.distanceKm * 3.0).round().clamp(15, 60);

    // Refresh slots for new centre
    final recommendedSlots = SmartSlotService.recommendSlots(
      centre: newCentre,
      crop: _farmerData.cropName,
    );
    _slots = recommendedSlots
        .map((s) => ProcurementSlotInfo(
              time: s.time,
              bookingsCount: s.isRecommended ? 6 : 4,
              capacity: 12,
              recommendationTag: s.tag,
            ))
        .toList();

    // Update queue item for Ramesh Kumar
    final rameshIndex =
        _queue.indexWhere((q) => q.farmerName == 'Ramesh Kumar');
    if (rameshIndex != -1) {
      _queue[rameshIndex] = _queue[rameshIndex].copyWith(
        bookedSlot: newSlot,
        peopleAhead: (newCentre.todayQueueCount ~/ 2).clamp(1, 10),
        approxWaitMinutes: newCentre.estimatedWaitMinutes,
        checkInStatus: 'Not Checked In', // Reset gate check-in for new centre
      );
    }

    _recalculateFarmerData();

    // Proactive trilingual notification
    NotificationService().notifyCentreChanged(
      tokenNumber: _farmerData.tokenNumber,
      oldCentre: oldCentreName,
      newCentre: newCentre.name,
      newSlot: newSlot,
      departureTime: _farmerData.recommendedDepartureTime,
    );

    notifyListeners();
  }

  /// Asynchronously loads procurement and centre state from active repositories.
  Future<void> loadFromRepositories() async {
    if (!AppConnectivityService.instance.isOnline) return;

    try {
      final centres = await RepositoryProvider.centre.getCentres();
      if (centres.isNotEmpty) {
        final currentCentre = centres.firstWhere(
          (c) => c.name == _centreName || c.id == _centreName,
          orElse: () => centres.first,
        );
        _centreName = currentCentre.name;
        _centreStatus = currentCentre.status;
        _centreCapacityPercent = currentCentre.capacity > 0
            ? ((currentCentre.todayQueueCount / currentCentre.capacity) * 100)
                .toInt()
                .clamp(10, 100)
            : 75;
      }

      final produceList = await RepositoryProvider.farmer
          .getFarmerProduce('22222222-2222-2222-2222-222222222222');
      if (produceList.isNotEmpty) {
        final crop = produceList.first['crop']?.toString() ?? 'Wheat';
        final qty = (produceList.first['quantity'] as num?)?.toDouble() ?? 50.0;
        _farmerData = _farmerData.copyWith(
          cropName: crop,
          quantity: '$qty Quintals',
        );
      }

      _recalculateFarmerData();
      syncOfflineCache();
      notifyListeners();
    } catch (e) {
      debugPrint('ProcurementStateService.loadFromRepositories error: $e');
    }
  }

  /// Reconciles local memory and cache from Supabase when network connectivity returns.
  Future<void> reconcileFromSupabase() async {
    if (!AppConnectivityService.instance.isOnline) return;
    await loadFromRepositories();
    syncOfflineCache();
  }

  /// Applies incoming Supabase Realtime booking event.
  void applyRealtimeBooking(Map<String, dynamic> row) {
    final token = row['token']?.toString();
    final status = row['status']?.toString();
    if (token == null) return;

    final index = _queue.indexWhere((q) => q.tokenNumber == token);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        status: status != null ? status.toUpperCase() : _queue[index].status,
      );
      _recalculateFarmerData();
      syncOfflineCache();
      notifyListeners();
    }
  }

  /// Applies incoming Supabase Realtime queue entry event.
  void applyRealtimeQueue(Map<String, dynamic> row) {
    final bookingId = row['booking_id']?.toString();
    final peopleAhead = (row['people_ahead'] as num?)?.toInt();
    final status = row['status']?.toString();
    final waitMinutes = (row['estimated_wait_minutes'] as num?)?.toInt();

    if (bookingId == null) return;

    final index = _queue.indexWhere(
        (q) => q.tokenNumber == bookingId || 'BOOK-${q.tokenNumber}' == bookingId);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        peopleAhead: peopleAhead ?? _queue[index].peopleAhead,
        approxWaitMinutes: waitMinutes ?? _queue[index].approxWaitMinutes,
        status: status != null ? status.toUpperCase() : _queue[index].status,
      );
      _recalculateFarmerData();
      syncOfflineCache();
      notifyListeners();
    }
  }

  /// Applies incoming Supabase Realtime procurement record event.
  void applyRealtimeProcurement(Map<String, dynamic> row) {
    final bookingId = row['booking_id']?.toString();
    final actualQty = (row['actual_quantity'] as num?)?.toDouble();
    final grade = row['quality_grade']?.toString();
    final stage = row['procurement_stage']?.toString();

    if (bookingId == null) return;

    final index = _queue.indexWhere(
        (q) => q.tokenNumber == bookingId || 'BOOK-${q.tokenNumber}' == bookingId);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        actualQuantity: actualQty != null
            ? '$actualQty Quintals'
            : _queue[index].actualQuantity,
        qualityGrade: grade ?? _queue[index].qualityGrade,
        status: stage != null ? stage.toUpperCase() : _queue[index].status,
      );
      _recalculateFarmerData();
      syncOfflineCache();
      notifyListeners();
    }
  }

  /// Applies incoming Supabase Realtime payment event.
  void applyRealtimePayment(Map<String, dynamic> row) {
    final bookingId = row['booking_id']?.toString();
    final paymentStatus = row['payment_status']?.toString();
    final netAmount = (row['net_amount'] as num?)?.toDouble();
    final ref = row['payment_reference']?.toString();

    if (bookingId == null) return;

    final index = _queue.indexWhere(
        (q) => q.tokenNumber == bookingId || 'BOOK-${q.tokenNumber}' == bookingId);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(
        paymentStatus: paymentStatus ?? _queue[index].paymentStatus,
        netPayable: netAmount ?? _queue[index].netPayable,
        paymentReference: ref ?? _queue[index].paymentReference,
      );
      _recalculateFarmerData();
      syncOfflineCache();
      notifyListeners();
    }
  }

  /// Applies incoming Supabase Realtime notification event.
  void applyRealtimeNotification(Map<String, dynamic> row) {
    final title = row['title']?.toString() ?? 'Update';
    final message = row['message']?.toString() ?? '';
    NotificationService().notifyGeneralAlert(
      titleEn: title,
      messageEn: message,
    );
    syncOfflineCache();
    notifyListeners();
  }
}
