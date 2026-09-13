/// Severity levels for officer exceptions.
enum ExceptionSeverity {
  critical,
  high,
  medium,
  low,
  // Backwards compatibility aliases
  warning,
  info,
}

/// Lifecycle statuses for operational exceptions.
enum ExceptionStatus {
  open,
  acknowledged,
  resolved,
}

/// Discrete operational exception categories.
enum ExceptionType {
  queueOverload,
  longWaitingFarmer,
  processingDelay,
  centreOverload,
  paymentDelay,
  quantityDiscrepancy,
  centreStopped,
  bookingAnomaly,
  capacityForecastRisk,
  slotOverload,
}

/// Authoritative data model for operational exceptions on the Officer Command Centre.
class OfficerExceptionModel {
  final String id;
  final ExceptionType type;
  final ExceptionSeverity severity;
  final String title;
  final String shortDescription;
  final String explanation;
  final String centreId;
  final String? tokenNumber;
  final String? farmerName;
  final DateTime createdTimestamp;
  final ExceptionStatus status;
  final String recommendedAction;
  final Map<String, dynamic> metadata;

  const OfficerExceptionModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.shortDescription,
    required this.explanation,
    required this.centreId,
    this.tokenNumber,
    this.farmerName,
    required this.createdTimestamp,
    this.status = ExceptionStatus.open,
    required this.recommendedAction,
    this.metadata = const {},
  });

  bool get isOpen => status == ExceptionStatus.open;
  bool get isAcknowledged => status == ExceptionStatus.acknowledged;
  bool get isResolved => status == ExceptionStatus.resolved;

  String get severityLabel {
    switch (severity) {
      case ExceptionSeverity.critical:
        return 'CRITICAL';
      case ExceptionSeverity.high:
        return 'HIGH';
      case ExceptionSeverity.warning:
        return 'WARNING';
      case ExceptionSeverity.medium:
        return 'MEDIUM';
      case ExceptionSeverity.low:
        return 'LOW';
      case ExceptionSeverity.info:
        return 'INFO';
    }
  }

  String get severityTag {
    switch (severity) {
      case ExceptionSeverity.critical:
        return '⛔ CRITICAL';
      case ExceptionSeverity.high:
        return '🔴 HIGH';
      case ExceptionSeverity.warning:
        return '⚠️ WARNING';
      case ExceptionSeverity.medium:
        return '🟠 MEDIUM';
      case ExceptionSeverity.low:
        return '🟢 LOW';
      case ExceptionSeverity.info:
        return 'ℹ️ INFO';
    }
  }

  String get statusLabel {
    switch (status) {
      case ExceptionStatus.open:
        return 'Open';
      case ExceptionStatus.acknowledged:
        return 'Acknowledged';
      case ExceptionStatus.resolved:
        return 'Resolved';
    }
  }

  OfficerExceptionModel copyWith({
    String? id,
    ExceptionType? type,
    ExceptionSeverity? severity,
    String? title,
    String? shortDescription,
    String? explanation,
    String? centreId,
    String? tokenNumber,
    String? farmerName,
    DateTime? createdTimestamp,
    ExceptionStatus? status,
    String? recommendedAction,
    Map<String, dynamic>? metadata,
  }) {
    return OfficerExceptionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      explanation: explanation ?? this.explanation,
      centreId: centreId ?? this.centreId,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      farmerName: farmerName ?? this.farmerName,
      createdTimestamp: createdTimestamp ?? this.createdTimestamp,
      status: status ?? this.status,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      metadata: metadata ?? this.metadata,
    );
  }
}
