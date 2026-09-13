/// Model representing a dispute or discrepancy report submitted by a farmer.
class FarmerDisputeReport {
  final String id;
  final String tokenNumber;
  final String farmerName;
  final String reason;
  final String? explanation;
  final DateTime submittedAt;
  final String status;
  final String crop;
  final double registeredQuantity;
  final double actualQuantity;
  final String centreName;
  final String officerId;
  final String? officerNotes;
  final DateTime? resolvedAt;

  const FarmerDisputeReport({
    required this.id,
    required this.tokenNumber,
    required this.farmerName,
    required this.reason,
    this.explanation,
    required this.submittedAt,
    this.status = 'Submitted',
    this.crop = 'Wheat',
    this.registeredQuantity = 50.0,
    this.actualQuantity = 47.8,
    this.centreName = 'Example Procurement Centre',
    this.officerId = 'OFF-101',
    this.officerNotes,
    this.resolvedAt,
  });

  /// Difference between actual quantity weighed and registered quantity in Quintals.
  double get difference => actualQuantity - registeredQuantity;

  /// Percentage discrepancy: ((Actual - Registered) / Registered) * 100.
  double get differencePercentage => registeredQuantity > 0
      ? ((actualQuantity - registeredQuantity) / registeredQuantity) * 100
      : 0.0;

  bool get isResolved => status == 'Resolved';
  bool get isRejected => status == 'Rejected';
  bool get isEscalated => status == 'Escalated';
  bool get isActive => !isResolved && !isRejected;

  FarmerDisputeReport copyWith({
    String? id,
    String? tokenNumber,
    String? farmerName,
    String? reason,
    String? explanation,
    DateTime? submittedAt,
    String? status,
    String? crop,
    double? registeredQuantity,
    double? actualQuantity,
    String? centreName,
    String? officerId,
    String? officerNotes,
    DateTime? resolvedAt,
  }) {
    return FarmerDisputeReport(
      id: id ?? this.id,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      farmerName: farmerName ?? this.farmerName,
      reason: reason ?? this.reason,
      explanation: explanation ?? this.explanation,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      crop: crop ?? this.crop,
      registeredQuantity: registeredQuantity ?? this.registeredQuantity,
      actualQuantity: actualQuantity ?? this.actualQuantity,
      centreName: centreName ?? this.centreName,
      officerId: officerId ?? this.officerId,
      officerNotes: officerNotes ?? this.officerNotes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
