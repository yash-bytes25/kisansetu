import 'dart:math';
import '../models/capacity_forecast_model.dart';
import '../models/procurement_slot_info.dart';

/// Centralized deterministic engine for predicting procurement centre congestion,
/// queue backlog, and load risks across future operational windows.
///
/// Designed with an explainable throughput-versus-arrival formula that can later
/// be dropped into an ML service when training datasets become available.
class CapacityForecastService {
  static final CapacityForecastService _instance =
      CapacityForecastService._internal();
  factory CapacityForecastService() => _instance;
  CapacityForecastService._internal();

  /// Generates capacity forecasts for Next 1 Hour, Next 2 Hours, Next 4 Hours, and Today.
  CapacityForecastSummary generateForecastSummary({
    required int currentLoadPercent,
    required int currentQueueCount,
    int capacity = 100,
    int averageProcessingMinutes = 5,
    int delayMinutes = 0,
    String centreStatus = 'Open • Normal',
    List<ProcurementSlotInfo>? slots,
  }) {
    final effectiveCapacity = capacity > 0 ? capacity : 100;
    final effectiveProcessingMins =
        averageProcessingMinutes > 0 ? averageProcessingMinutes : 5;
    final processingRatePerHour = (60 / effectiveProcessingMins).round();

    final statusLower = centreStatus.toLowerCase();
    final isDisrupted = statusLower.contains('stop') ||
        statusLower.contains('halt') ||
        statusLower.contains('pause');

    // Deterministic arrival expectations based on slot bookings or typical dock traffic
    int getArrivalsForWindow(ForecastWindow window) {
      if (slots != null && slots.isNotEmpty) {
        switch (window) {
          case ForecastWindow.oneHour:
            return slots.isNotEmpty ? slots[0].bookingsCount : 8;
          case ForecastWindow.twoHours:
            return slots.length >= 2
                ? slots[0].bookingsCount + slots[1].bookingsCount
                : 16;
          case ForecastWindow.fourHours:
            return slots.fold<int>(0, (sum, s) => sum + s.bookingsCount);
          case ForecastWindow.today:
            return (slots.fold<int>(0, (sum, s) => sum + s.bookingsCount) * 1.3)
                .round();
        }
      }
      // Fallback deterministic arrivals
      switch (window) {
        case ForecastWindow.oneHour:
          return 10;
        case ForecastWindow.twoHours:
          return 20;
        case ForecastWindow.fourHours:
          return 36;
        case ForecastWindow.today:
          return 48;
      }
    }

    final windows = [
      ForecastWindow.oneHour,
      ForecastWindow.twoHours,
      ForecastWindow.fourHours,
      ForecastWindow.today,
    ];

    final List<CapacityForecastModel> forecastList = [];

    for (final window in windows) {
      final hours = window.hours;
      final expectedArrivals = getArrivalsForWindow(window);

      // Throughput capacity in this window
      // Active delay diminishes processing throughput
      final throughputEfficiency = isDisrupted
          ? 0.1
          : (delayMinutes >= 30
              ? 0.65
              : (delayMinutes >= 15 ? 0.80 : 1.0));

      final throughput =
          (processingRatePerHour * hours * throughputEfficiency).round();

      // Predicted queue = current + arrivals - processed
      final predictedQueue = max(
        isDisrupted ? currentQueueCount + expectedArrivals : 1,
        currentQueueCount + expectedArrivals - throughput,
      );

      // Predicted load percent calculation
      int predictedLoad;
      if (isDisrupted) {
        predictedLoad = 98;
      } else {
        // Base load incremented by arrival backlog vs throughput, scaled by capacity factor
        final netChange = expectedArrivals - throughput;
        final capacityFactor = 100.0 / effectiveCapacity;
        final deltaPercent =
            ((netChange * 2.2) * capacityFactor).round() + (delayMinutes ~/ 2);
        predictedLoad = (currentLoadPercent + deltaPercent).clamp(15, 100);
      }

      // Predicted wait minutes
      final predictedWait = isDisrupted
          ? max(60, (predictedQueue * effectiveProcessingMins) + delayMinutes)
          : (predictedQueue * effectiveProcessingMins) + delayMinutes;

      // Congestion Level Classification
      final congestion = classifyCongestion(
        loadPercent: predictedLoad,
        waitMinutes: predictedWait,
        delayMinutes: delayMinutes,
        isDisrupted: isDisrupted,
      );

      // Recommended Officer Action
      final action = determineRecommendedAction(congestion, predictedLoad);

      // Time label
      final timeLabel = _getTimeLabelForWindow(window);

      // Explainable Confidence Basis
      final delayPenaltyStr =
          delayMinutes > 0 ? ' (+${delayMinutes}m delay penalty)' : '';
      final basis =
          'Basis: $currentQueueCount queue + $expectedArrivals arrivals - $throughput throughput '
          'at $processingRatePerHour/hr rate$delayPenaltyStr (Cap: $effectiveCapacity)';

      forecastList.add(CapacityForecastModel(
        window: window,
        windowLabel: window.label,
        predictedTime: timeLabel,
        predictedLoadPercent: predictedLoad,
        predictedQueueCount: predictedQueue,
        estimatedWaitMinutes: predictedWait,
        congestionLevel: congestion,
        confidenceBasis: basis,
        recommendedAction: action,
      ));
    }

    // Determine Peak Risk Window
    CapacityForecastModel? peakWindow;
    int maxScore = -1;

    for (final f in forecastList) {
      final score = (f.predictedLoadPercent * 2) + f.estimatedWaitMinutes;
      if (score > maxScore) {
        maxScore = score;
        peakWindow = f;
      }
    }

    final peak = peakWindow ?? forecastList.last;
    final hasHighOrCritical = forecastList.any((f) =>
        f.congestionLevel == CapacityCongestionLevel.highRisk ||
        f.congestionLevel == CapacityCongestionLevel.critical);

    return CapacityForecastSummary(
      forecasts: forecastList,
      peakRiskWindow: peak,
      peakRiskTime: peak.predictedTime,
      peakLoadPercent: peak.predictedLoadPercent,
      peakCongestionLevel: peak.congestionLevel,
      overallRecommendedAction: peak.recommendedAction,
      hasHighOrCriticalRisk: hasHighOrCritical,
    );
  }

  /// Classifies congestion severity based on explainable threshold boundaries.
  CapacityCongestionLevel classifyCongestion({
    required int loadPercent,
    required int waitMinutes,
    required int delayMinutes,
    bool isDisrupted = false,
  }) {
    if (isDisrupted || loadPercent >= 95 || waitMinutes >= 60) {
      return CapacityCongestionLevel.critical;
    }
    if (loadPercent >= 85 || waitMinutes >= 45 || delayMinutes >= 20) {
      return CapacityCongestionLevel.highRisk;
    }
    if (loadPercent >= 70 || waitMinutes >= 30) {
      return CapacityCongestionLevel.busy;
    }
    return CapacityCongestionLevel.normal;
  }

  /// Generates actionable officer interventions based on risk level.
  String determineRecommendedAction(
    CapacityCongestionLevel level,
    int loadPercent,
  ) {
    switch (level) {
      case CapacityCongestionLevel.critical:
        return 'Open additional processing dock immediately • Recommend catchment alternative centres to upcoming arrivals • Temporarily halt unscheduled arrivals.';
      case CapacityCongestionLevel.highRisk:
        return 'Open additional processing counter • Redistribute upcoming slots via Dynamic Slot Reallocation • Encourage nearby alternative centres.';
      case CapacityCongestionLevel.busy:
        return 'Monitor intake throughput • Review delayed bookings • Prepare backup weighment counter.';
      case CapacityCongestionLevel.normal:
        return 'Intake rate and queue backlog are balanced. Continue standard intake operations.';
    }
  }

  String _getTimeLabelForWindow(ForecastWindow window) {
    switch (window) {
      case ForecastWindow.oneHour:
        return '11:00 AM';
      case ForecastWindow.twoHours:
        return '12:00 PM';
      case ForecastWindow.fourHours:
        return '02:00 PM';
      case ForecastWindow.today:
        return 'Today EOD';
    }
  }
}
