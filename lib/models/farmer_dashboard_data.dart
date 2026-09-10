import '../services/queue_prediction_service.dart';

/// Data model representing the farmer dashboard metrics for KisanSetu.
///
/// Integrated with the Dynamic Queue Intelligence Engine.
class FarmerDashboardData {
  final String farmerName;
  final String cropName;
  final String quantity;
  final String centreName;
  final String tokenNumber;
  final int peopleAhead;
  final int totalInQueue;
  final int travelTimeMinutes;
  final int expectedWaitMinutes;
  final String recommendedDepartureTime;
  final String expectedTurnTime;
  final String centreStatus;
  final String paymentStatus;
  final bool isGoodTimeToLeave;
  final String waitReason;
  final String waitRecommendedArrival;
  final String? bookedSlotTime;
  final String estimatedMspValue;
  final String lifecycleStatus;
  final String actualQuantity;
  final String qualityGrade;
  final double grossAmount;
  final double netPayable;
  final String paymentReference;
  final String paymentDate;
  final int disputeCount;
  final String checkInStatus;
  final String? actualArrivalTime;

  // Phase 13 enhanced intelligence attributes
  final GoTimeRecommendation recommendation;
  final int centreLoadPercentage;
  final String confidence;
  final bool isLateArrival;
  final int delayMinutes;
  final int averageProcessingMinutes;

  const FarmerDashboardData({
    required this.farmerName,
    required this.cropName,
    required this.quantity,
    required this.centreName,
    required this.tokenNumber,
    required this.peopleAhead,
    required this.totalInQueue,
    required this.travelTimeMinutes,
    required this.expectedWaitMinutes,
    required this.recommendedDepartureTime,
    required this.expectedTurnTime,
    required this.centreStatus,
    required this.paymentStatus,
    this.isGoodTimeToLeave = true,
    this.waitReason =
        'Centre is currently busy. Recommended arrival: 12:15 PM. We\'ll alert you when it is a good time to leave.',
    this.waitRecommendedArrival = '12:15 PM',
    this.bookedSlotTime,
    this.estimatedMspValue = '₹1,13,750',
    this.lifecycleStatus = 'Waiting',
    this.actualQuantity = '50.2 Quintals',
    this.qualityGrade = 'FAQ',
    this.grossAmount = 114205.0,
    this.netPayable = 114205.0,
    this.paymentReference = 'PAY-2026-8493',
    this.paymentDate = '09 Sep 2026',
    this.disputeCount = 0,
    this.checkInStatus = 'Not Checked In',
    this.actualArrivalTime,
    this.recommendation = GoTimeRecommendation.goNow,
    this.centreLoadPercentage = 75,
    this.confidence = 'High',
    this.isLateArrival = false,
    this.delayMinutes = 0,
    this.averageProcessingMinutes = 5,
  });

  String get crop => cropName;
  String get quantityQuintals =>
      quantity.replaceAll(' Quintals', '').replaceAll(' क्विंटल', '');
  int get currentPosition => peopleAhead + 1;

  /// Whether the farmer currently has an active procurement booking/token.
  bool get hasActiveBooking =>
      tokenNumber.isNotEmpty &&
      lifecycleStatus != 'Completed' &&
      lifecycleStatus != 'None' &&
      bookedSlotTime != null;

  FarmerDashboardData applyPrediction({
    required int peopleAhead,
    required int estimatedWaitMinutes,
    required String expectedTurnTime,
    required String recommendedDepartureTime,
    required String recommendedArrivalTime,
    required bool isGoodTimeToLeave,
    required String centreStatus,
    required String statusReason,
    GoTimeRecommendation recommendation = GoTimeRecommendation.goNow,
    int centreLoadPercentage = 75,
    String confidence = 'High',
    bool isLateArrival = false,
    int delayMinutes = 0,
    int averageProcessingMinutes = 5,
  }) {
    return copyWith(
      peopleAhead: peopleAhead,
      expectedWaitMinutes: estimatedWaitMinutes,
      expectedTurnTime: expectedTurnTime,
      recommendedDepartureTime: recommendedDepartureTime,
      waitRecommendedArrival: recommendedArrivalTime,
      isGoodTimeToLeave: isGoodTimeToLeave,
      centreStatus: centreStatus,
      waitReason: statusReason,
      recommendation: recommendation,
      centreLoadPercentage: centreLoadPercentage,
      confidence: confidence,
      isLateArrival: isLateArrival,
      delayMinutes: delayMinutes,
      averageProcessingMinutes: averageProcessingMinutes,
    );
  }

  /// Factory providing prototype mock data for Ramesh Kumar.
  factory FarmerDashboardData.mock() {
    return const FarmerDashboardData(
      farmerName: 'Ramesh Kumar',
      cropName: 'Wheat',
      quantity: '50 Quintals',
      centreName: 'Example Procurement Centre',
      tokenNumber: 'TK-8492',
      peopleAhead: 7,
      totalInQueue: 12,
      travelTimeMinutes: 25,
      expectedWaitMinutes: 35,
      recommendedDepartureTime: '10:55 AM',
      expectedTurnTime: '11:30 AM',
      centreStatus: 'Open • Normal',
      paymentStatus: 'Pending',
      isGoodTimeToLeave: true,
      estimatedMspValue: '₹1,14,205',
      actualQuantity: '50.2 Quintals',
      qualityGrade: 'FAQ',
      grossAmount: 114205.0,
      netPayable: 114205.0,
      paymentReference: 'PAY-2026-8493',
      paymentDate: '09 Sep 2026',
      disputeCount: 0,
      checkInStatus: 'Not Checked In',
      recommendation: GoTimeRecommendation.goNow,
      centreLoadPercentage: 75,
      confidence: 'High',
    );
  }

  FarmerDashboardData copyWith({
    String? farmerName,
    String? cropName,
    String? quantity,
    String? centreName,
    String? tokenNumber,
    int? peopleAhead,
    int? totalInQueue,
    int? travelTimeMinutes,
    int? expectedWaitMinutes,
    String? recommendedDepartureTime,
    String? expectedTurnTime,
    String? centreStatus,
    String? paymentStatus,
    bool? isGoodTimeToLeave,
    String? waitReason,
    String? waitRecommendedArrival,
    String? bookedSlotTime,
    String? estimatedMspValue,
    String? lifecycleStatus,
    String? actualQuantity,
    String? qualityGrade,
    double? grossAmount,
    double? netPayable,
    String? paymentReference,
    String? paymentDate,
    int? disputeCount,
    String? checkInStatus,
    String? actualArrivalTime,
    GoTimeRecommendation? recommendation,
    int? centreLoadPercentage,
    String? confidence,
    bool? isLateArrival,
    int? delayMinutes,
    int? averageProcessingMinutes,
  }) {
    return FarmerDashboardData(
      farmerName: farmerName ?? this.farmerName,
      cropName: cropName ?? this.cropName,
      quantity: quantity ?? this.quantity,
      centreName: centreName ?? this.centreName,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      peopleAhead: peopleAhead ?? this.peopleAhead,
      totalInQueue: totalInQueue ?? this.totalInQueue,
      travelTimeMinutes: travelTimeMinutes ?? this.travelTimeMinutes,
      expectedWaitMinutes: expectedWaitMinutes ?? this.expectedWaitMinutes,
      recommendedDepartureTime:
          recommendedDepartureTime ?? this.recommendedDepartureTime,
      expectedTurnTime: expectedTurnTime ?? this.expectedTurnTime,
      centreStatus: centreStatus ?? this.centreStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      isGoodTimeToLeave: isGoodTimeToLeave ?? this.isGoodTimeToLeave,
      waitReason: waitReason ?? this.waitReason,
      waitRecommendedArrival:
          waitRecommendedArrival ?? this.waitRecommendedArrival,
      bookedSlotTime: bookedSlotTime ?? this.bookedSlotTime,
      estimatedMspValue: estimatedMspValue ?? this.estimatedMspValue,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      actualQuantity: actualQuantity ?? this.actualQuantity,
      qualityGrade: qualityGrade ?? this.qualityGrade,
      grossAmount: grossAmount ?? this.grossAmount,
      netPayable: netPayable ?? this.netPayable,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentDate: paymentDate ?? this.paymentDate,
      disputeCount: disputeCount ?? this.disputeCount,
      checkInStatus: checkInStatus ?? this.checkInStatus,
      actualArrivalTime: actualArrivalTime ?? this.actualArrivalTime,
      recommendation: recommendation ?? this.recommendation,
      centreLoadPercentage: centreLoadPercentage ?? this.centreLoadPercentage,
      confidence: confidence ?? this.confidence,
      isLateArrival: isLateArrival ?? this.isLateArrival,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      averageProcessingMinutes:
          averageProcessingMinutes ?? this.averageProcessingMinutes,
    );
  }
}
