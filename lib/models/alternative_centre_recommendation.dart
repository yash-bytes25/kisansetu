import 'procurement_centre.dart';

/// Structured model representing a recommended alternative procurement centre.
class AlternativeCentreRecommendation {
  final ProcurementCentre centre;
  final double distanceKm;
  final int estimatedWaitMinutes;
  final int queueCount;
  final int capacityPercent;
  final String operatingStatus;
  final String nextAvailableSlot;
  final double score;
  final String reasonEn;
  final String reasonHi;
  final String reasonTe;
  final bool isTopPick;

  const AlternativeCentreRecommendation({
    required this.centre,
    required this.distanceKm,
    required this.estimatedWaitMinutes,
    required this.queueCount,
    required this.capacityPercent,
    required this.operatingStatus,
    required this.nextAvailableSlot,
    required this.score,
    required this.reasonEn,
    this.reasonHi = '',
    this.reasonTe = '',
    this.isTopPick = false,
  });

  String localizedReason({bool isHindi = false, bool isTelugu = false}) {
    if (isTelugu && reasonTe.isNotEmpty) return reasonTe;
    if (isHindi && reasonHi.isNotEmpty) return reasonHi;
    return reasonEn;
  }

  AlternativeCentreRecommendation copyWith({
    ProcurementCentre? centre,
    double? distanceKm,
    int? estimatedWaitMinutes,
    int? queueCount,
    int? capacityPercent,
    String? operatingStatus,
    String? nextAvailableSlot,
    double? score,
    String? reasonEn,
    String? reasonHi,
    String? reasonTe,
    bool? isTopPick,
  }) {
    return AlternativeCentreRecommendation(
      centre: centre ?? this.centre,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      queueCount: queueCount ?? this.queueCount,
      capacityPercent: capacityPercent ?? this.capacityPercent,
      operatingStatus: operatingStatus ?? this.operatingStatus,
      nextAvailableSlot: nextAvailableSlot ?? this.nextAvailableSlot,
      score: score ?? this.score,
      reasonEn: reasonEn ?? this.reasonEn,
      reasonHi: reasonHi ?? this.reasonHi,
      reasonTe: reasonTe ?? this.reasonTe,
      isTopPick: isTopPick ?? this.isTopPick,
    );
  }
}
