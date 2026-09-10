/// Status of a dynamic slot reallocation recommendation.
enum ReallocationStatus {
  recommended,
  reallocated,
  dismissed,
}

/// Structured model representing a dynamic slot reallocation recommendation
/// for a farmer at a congested or delayed procurement centre.
class SlotReallocationRecommendation {
  final String id;
  final String tokenNumber;
  final String farmerName;
  final String crop;
  final String quantity;
  final String currentSlot;
  final String recommendedSlot;
  final String reasonEn;
  final String reasonHi;
  final String reasonTe;
  final int centreLoadPercent;
  final int estimatedWaitMinutes;
  final ReallocationStatus status;
  final String? reallocatedAt;

  const SlotReallocationRecommendation({
    required this.id,
    required this.tokenNumber,
    required this.farmerName,
    required this.crop,
    required this.quantity,
    required this.currentSlot,
    required this.recommendedSlot,
    required this.reasonEn,
    this.reasonHi = '',
    this.reasonTe = '',
    required this.centreLoadPercent,
    required this.estimatedWaitMinutes,
    this.status = ReallocationStatus.recommended,
    this.reallocatedAt,
  });

  bool get isPending => status == ReallocationStatus.recommended;
  bool get isReallocated => status == ReallocationStatus.reallocated;
  bool get isDismissed => status == ReallocationStatus.dismissed;

  String localizedReason({bool isHindi = false, bool isTelugu = false}) {
    if (isTelugu && reasonTe.isNotEmpty) return reasonTe;
    if (isHindi && reasonHi.isNotEmpty) return reasonHi;
    return reasonEn;
  }

  SlotReallocationRecommendation copyWith({
    String? id,
    String? tokenNumber,
    String? farmerName,
    String? crop,
    String? quantity,
    String? currentSlot,
    String? recommendedSlot,
    String? reasonEn,
    String? reasonHi,
    String? reasonTe,
    int? centreLoadPercent,
    int? estimatedWaitMinutes,
    ReallocationStatus? status,
    String? reallocatedAt,
  }) {
    return SlotReallocationRecommendation(
      id: id ?? this.id,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      farmerName: farmerName ?? this.farmerName,
      crop: crop ?? this.crop,
      quantity: quantity ?? this.quantity,
      currentSlot: currentSlot ?? this.currentSlot,
      recommendedSlot: recommendedSlot ?? this.recommendedSlot,
      reasonEn: reasonEn ?? this.reasonEn,
      reasonHi: reasonHi ?? this.reasonHi,
      reasonTe: reasonTe ?? this.reasonTe,
      centreLoadPercent: centreLoadPercent ?? this.centreLoadPercent,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      status: status ?? this.status,
      reallocatedAt: reallocatedAt ?? this.reallocatedAt,
    );
  }
}
