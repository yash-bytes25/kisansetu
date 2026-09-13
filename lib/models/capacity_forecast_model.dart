import 'package:flutter/material.dart';

/// Congestion severity levels for procurement centre capacity forecasting.
enum CapacityCongestionLevel {
  normal,
  busy,
  highRisk,
  critical,
}

extension CapacityCongestionLevelExt on CapacityCongestionLevel {
  String get nameEn {
    switch (this) {
      case CapacityCongestionLevel.normal:
        return 'Normal';
      case CapacityCongestionLevel.busy:
        return 'Busy';
      case CapacityCongestionLevel.highRisk:
        return 'High Risk';
      case CapacityCongestionLevel.critical:
        return 'Critical';
    }
  }

  String get nameHi {
    switch (this) {
      case CapacityCongestionLevel.normal:
        return 'सामान्य';
      case CapacityCongestionLevel.busy:
        return 'व्यस्त';
      case CapacityCongestionLevel.highRisk:
        return 'उच्च जोखिम';
      case CapacityCongestionLevel.critical:
        return 'गंभीर';
    }
  }

  String get nameTe {
    switch (this) {
      case CapacityCongestionLevel.normal:
        return 'సాధారణం';
      case CapacityCongestionLevel.busy:
        return 'రద్దీ';
      case CapacityCongestionLevel.highRisk:
        return 'అధిక ప్రమాదం';
      case CapacityCongestionLevel.critical:
        return 'తీవ్రమైనది';
    }
  }

  String get displayTag {
    switch (this) {
      case CapacityCongestionLevel.normal:
        return '🟢 LOW';
      case CapacityCongestionLevel.busy:
        return '🟠 MODERATE';
      case CapacityCongestionLevel.highRisk:
        return '🔴 HIGH';
      case CapacityCongestionLevel.critical:
        return '⛔ CRITICAL';
    }
  }

  IconData get icon {
    switch (this) {
      case CapacityCongestionLevel.normal:
        return Icons.check_circle_rounded;
      case CapacityCongestionLevel.busy:
        return Icons.warning_amber_rounded;
      case CapacityCongestionLevel.highRisk:
        return Icons.error_outline_rounded;
      case CapacityCongestionLevel.critical:
        return Icons.dangerous_rounded;
    }
  }

  Color get color {
    switch (this) {
      case CapacityCongestionLevel.normal:
        return const Color(0xFF2E7D32); // Green
      case CapacityCongestionLevel.busy:
        return const Color(0xFFF57C00); // Orange
      case CapacityCongestionLevel.highRisk:
        return const Color(0xFFE65100); // Deep Orange
      case CapacityCongestionLevel.critical:
        return const Color(0xFFC62828); // Red
    }
  }

  Color get backgroundColor {
    switch (this) {
      case CapacityCongestionLevel.normal:
        return const Color(0xFFE8F5E9);
      case CapacityCongestionLevel.busy:
        return const Color(0xFFFFF3E0);
      case CapacityCongestionLevel.highRisk:
        return const Color(0xFFFBE9E7);
      case CapacityCongestionLevel.critical:
        return const Color(0xFFFFEBEE);
    }
  }
}

/// Time horizons for capacity forecasting.
enum ForecastWindow {
  oneHour,
  twoHours,
  fourHours,
  today,
}

extension ForecastWindowExt on ForecastWindow {
  String get label {
    switch (this) {
      case ForecastWindow.oneHour:
        return 'Next 1 Hour';
      case ForecastWindow.twoHours:
        return 'Next 2 Hours';
      case ForecastWindow.fourHours:
        return 'Next 4 Hours';
      case ForecastWindow.today:
        return 'Today';
    }
  }

  int get hours {
    switch (this) {
      case ForecastWindow.oneHour:
        return 1;
      case ForecastWindow.twoHours:
        return 2;
      case ForecastWindow.fourHours:
        return 4;
      case ForecastWindow.today:
        return 6;
    }
  }
}

/// Structured capacity forecast model for a discrete future window.
class CapacityForecastModel {
  final ForecastWindow window;
  final String windowLabel;
  final String predictedTime;
  final int predictedLoadPercent;
  final int predictedQueueCount;
  final int estimatedWaitMinutes;
  final CapacityCongestionLevel congestionLevel;
  final String confidenceBasis;
  final String recommendedAction;

  const CapacityForecastModel({
    required this.window,
    required this.windowLabel,
    required this.predictedTime,
    required this.predictedLoadPercent,
    required this.predictedQueueCount,
    required this.estimatedWaitMinutes,
    required this.congestionLevel,
    required this.confidenceBasis,
    required this.recommendedAction,
  });

  String get displayReason {
    if (congestionLevel == CapacityCongestionLevel.critical) {
      return 'Critical backlog: arrivals are significantly exceeding dock processing capacity.';
    } else if (congestionLevel == CapacityCongestionLevel.highRisk) {
      return 'Current arrivals are exceeding the estimated processing throughput.';
    } else if (congestionLevel == CapacityCongestionLevel.busy) {
      return 'Intake is approaching maximum capacity limits.';
    }
    return 'Processing rate is balanced with current arrival traffic.';
  }

  static const String operationalForecastLabel =
      'Operational forecast based on current queue, capacity and processing rate.';

  CapacityForecastModel copyWith({
    ForecastWindow? window,
    String? windowLabel,
    String? predictedTime,
    int? predictedLoadPercent,
    int? predictedQueueCount,
    int? estimatedWaitMinutes,
    CapacityCongestionLevel? congestionLevel,
    String? confidenceBasis,
    String? recommendedAction,
  }) {
    return CapacityForecastModel(
      window: window ?? this.window,
      windowLabel: windowLabel ?? this.windowLabel,
      predictedTime: predictedTime ?? this.predictedTime,
      predictedLoadPercent: predictedLoadPercent ?? this.predictedLoadPercent,
      predictedQueueCount: predictedQueueCount ?? this.predictedQueueCount,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      congestionLevel: congestionLevel ?? this.congestionLevel,
      confidenceBasis: confidenceBasis ?? this.confidenceBasis,
      recommendedAction: recommendedAction ?? this.recommendedAction,
    );
  }
}

/// Summary aggregating multiple forecast horizons into a holistic operational view.
class CapacityForecastSummary {
  final List<CapacityForecastModel> forecasts;
  final CapacityForecastModel? peakRiskWindow;
  final String peakRiskTime;
  final int peakLoadPercent;
  final CapacityCongestionLevel peakCongestionLevel;
  final String overallRecommendedAction;
  final bool hasHighOrCriticalRisk;

  const CapacityForecastSummary({
    required this.forecasts,
    this.peakRiskWindow,
    required this.peakRiskTime,
    required this.peakLoadPercent,
    required this.peakCongestionLevel,
    required this.overallRecommendedAction,
    required this.hasHighOrCriticalRisk,
  });
}
