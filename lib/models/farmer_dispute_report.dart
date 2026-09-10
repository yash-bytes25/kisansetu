/// Model representing a dispute or discrepancy report submitted by a farmer.
class FarmerDisputeReport {
  final String id;
  final String tokenNumber;
  final String farmerName;
  final String reason;
  final String? explanation;
  final DateTime submittedAt;
  final String status;

  const FarmerDisputeReport({
    required this.id,
    required this.tokenNumber,
    required this.farmerName,
    required this.reason,
    this.explanation,
    required this.submittedAt,
    this.status = 'Submitted',
  });
}
