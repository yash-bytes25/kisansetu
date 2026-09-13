import 'farmer_dashboard_data.dart';

/// Data model representing a procurement payment record for the logged-in farmer.
class FarmerPaymentRecord {
  final String id;
  final String bookingId;
  final String tokenNumber;
  final String cropName;
  final String quantity;
  final String actualQuantity;
  final String qualityGrade;
  final String centreName;
  final double grossAmount;
  final double deductions;
  final double netAmount;
  final String paymentStatus;
  final String paymentReference;
  final String paymentDate;
  final DateTime dateTime;

  const FarmerPaymentRecord({
    required this.id,
    required this.bookingId,
    required this.tokenNumber,
    required this.cropName,
    required this.quantity,
    this.actualQuantity = '50.0 Quintals',
    this.qualityGrade = 'FAQ',
    required this.centreName,
    required this.grossAmount,
    this.deductions = 0.0,
    required this.netAmount,
    required this.paymentStatus,
    required this.paymentReference,
    required this.paymentDate,
    required this.dateTime,
  });

  /// Converts this payment record into a [FarmerDashboardData] representation
  /// suitable for rendering in the existing [FarmerPaymentScreen].
  FarmerDashboardData toDashboardData({
    String farmerName = 'Ramesh Kumar',
    String? bookedSlotTime,
  }) {
    return FarmerDashboardData(
      farmerName: farmerName,
      cropName: cropName,
      quantity: quantity,
      centreName: centreName,
      tokenNumber: tokenNumber,
      peopleAhead: 0,
      totalInQueue: 0,
      travelTimeMinutes: 25,
      expectedWaitMinutes: 0,
      recommendedDepartureTime: '10:55 AM',
      expectedTurnTime: '11:30 AM',
      centreStatus: 'Open • Normal',
      paymentStatus: paymentStatus,
      bookedSlotTime: bookedSlotTime ?? '11:30 AM',
      lifecycleStatus: paymentStatus == 'Completed' ? 'Payment Completed' : 'Payment Pending',
      checkInStatus: 'Checked In',
      grossAmount: grossAmount,
      netPayable: netAmount,
      paymentReference: paymentReference,
      paymentDate: paymentDate,
      actualQuantity: actualQuantity,
      qualityGrade: qualityGrade,
    );
  }

  factory FarmerPaymentRecord.fromMap(Map<String, dynamic> map) {
    return FarmerPaymentRecord(
      id: map['id']?.toString() ?? '',
      bookingId: map['booking_id']?.toString() ?? '',
      tokenNumber: map['token_number']?.toString() ?? map['token']?.toString() ?? 'TK-8492',
      cropName: map['crop_name']?.toString() ?? map['crop']?.toString() ?? 'Wheat',
      quantity: map['quantity']?.toString() ?? '50 Quintals',
      actualQuantity: map['actual_quantity']?.toString() ?? '50.0 Quintals',
      qualityGrade: map['quality_grade']?.toString() ?? 'FAQ',
      centreName: map['centre_name']?.toString() ?? 'Khanna Grain Market',
      grossAmount: (map['gross_amount'] as num?)?.toDouble() ?? 0.0,
      deductions: (map['deductions'] as num?)?.toDouble() ?? 0.0,
      netAmount: (map['net_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: map['payment_status']?.toString() ?? 'Pending',
      paymentReference: map['payment_reference']?.toString() ?? 'PAY-2026-8492',
      paymentDate: map['payment_date']?.toString() ?? '09 Sep 2026',
      dateTime: DateTime.tryParse(map['date_time']?.toString() ?? '') ??
          DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'token_number': tokenNumber,
      'crop_name': cropName,
      'quantity': quantity,
      'actual_quantity': actualQuantity,
      'quality_grade': qualityGrade,
      'centre_name': centreName,
      'gross_amount': grossAmount,
      'deductions': deductions,
      'net_amount': netAmount,
      'payment_status': paymentStatus,
      'payment_reference': paymentReference,
      'payment_date': paymentDate,
      'date_time': dateTime.toIso8601String(),
    };
  }
}
