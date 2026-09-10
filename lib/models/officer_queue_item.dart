/// Model representing a farmer queue item on the Procurement Officer side.
class OfficerQueueItem {
  final String tokenNumber;
  final String farmerName;
  final String crop;
  final String quantity;
  final String bookedSlot;
  final String arrivalTime;
  final String status;
  final int peopleAhead;
  final int approxWaitMinutes;
  final String actualQuantity;
  final String qualityGrade;
  final double grossAmount;
  final double deductions;
  final double netPayable;
  final String paymentStatus;
  final String? paymentReference;
  final String? paymentDate;
  final String? discrepancyNote;
  final String checkInStatus;

  const OfficerQueueItem({
    required this.tokenNumber,
    required this.farmerName,
    required this.crop,
    required this.quantity,
    required this.bookedSlot,
    required this.arrivalTime,
    required this.status,
    required this.peopleAhead,
    required this.approxWaitMinutes,
    this.actualQuantity = '50.2 Quintals',
    this.qualityGrade = 'FAQ',
    this.grossAmount = 114205.0,
    this.deductions = 0.0,
    this.netPayable = 114205.0,
    this.paymentStatus = 'Pending',
    this.paymentReference = 'PAY-2026-8493',
    this.paymentDate = '09 Sep 2026',
    this.discrepancyNote,
    this.checkInStatus = 'Not Checked In',
  });

  OfficerQueueItem copyWith({
    String? tokenNumber,
    String? farmerName,
    String? crop,
    String? quantity,
    String? bookedSlot,
    String? arrivalTime,
    String? status,
    int? peopleAhead,
    int? approxWaitMinutes,
    String? actualQuantity,
    String? qualityGrade,
    double? grossAmount,
    double? deductions,
    double? netPayable,
    String? paymentStatus,
    String? paymentReference,
    String? paymentDate,
    String? discrepancyNote,
    String? checkInStatus,
  }) {
    return OfficerQueueItem(
      tokenNumber: tokenNumber ?? this.tokenNumber,
      farmerName: farmerName ?? this.farmerName,
      crop: crop ?? this.crop,
      quantity: quantity ?? this.quantity,
      bookedSlot: bookedSlot ?? this.bookedSlot,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      status: status ?? this.status,
      peopleAhead: peopleAhead ?? this.peopleAhead,
      approxWaitMinutes: approxWaitMinutes ?? this.approxWaitMinutes,
      actualQuantity: actualQuantity ?? this.actualQuantity,
      qualityGrade: qualityGrade ?? this.qualityGrade,
      grossAmount: grossAmount ?? this.grossAmount,
      deductions: deductions ?? this.deductions,
      netPayable: netPayable ?? this.netPayable,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentDate: paymentDate ?? this.paymentDate,
      discrepancyNote: discrepancyNote ?? this.discrepancyNote,
      checkInStatus: checkInStatus ?? this.checkInStatus,
    );
  }
}
