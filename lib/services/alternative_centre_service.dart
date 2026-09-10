import '../models/alternative_centre_recommendation.dart';
import '../models/procurement_centre.dart';
import 'smart_slot_service.dart';

/// Service responsible for identifying when a procurement centre is overloaded,
/// delayed, or stopped, and calculating ranked alternative centre recommendations.
class AlternativeCentreService {
  static final AlternativeCentreService _instance =
      AlternativeCentreService._internal();

  factory AlternativeCentreService() => _instance;

  AlternativeCentreService._internal();

  /// Determines if a centre is considered overloaded, delayed, or stopped.
  bool isCentreOverloadedOrDelayed({
    int capacityPercent = 0,
    int delayMinutes = 0,
    String centreStatus = '',
    int waitMinutes = 0,
  }) {
    final statusLower = centreStatus.toLowerCase();
    final isStoppedOrPaused = statusLower.contains('stop') ||
        statusLower.contains('halt') ||
        statusLower.contains('pause') ||
        statusLower.contains('delay');

    return capacityPercent >= 85 ||
        delayMinutes >= 15 ||
        waitMinutes >= 45 ||
        isStoppedOrPaused;
  }

  /// Calculates 3 to 5 ranked alternative centre recommendations.
  List<AlternativeCentreRecommendation> getAlternativeCentres({
    required String currentCentreName,
    required int currentWaitMinutes,
    required int currentLoadPercent,
    String? crop,
    List<ProcurementCentre>? allCentres,
  }) {
    final pool = allCentres ?? ProcurementCentre.getMockCentres();

    // Exclude current centre
    final candidates = pool.where((c) {
      final nameMatches =
          c.name.trim().toLowerCase() == currentCentreName.trim().toLowerCase();
      final idMatches =
          c.id.trim().toLowerCase() == currentCentreName.trim().toLowerCase();
      return !nameMatches && !idMatches;
    }).toList();

    final List<AlternativeCentreRecommendation> recommendations = [];

    for (final candidate in candidates) {
      final distanceKm = candidate.distanceKm;
      final waitMinutes = candidate.estimatedWaitMinutes;
      final queueCount = candidate.todayQueueCount;
      final cap = candidate.capacity > 0 ? candidate.capacity : 100;
      final loadPercent = ((queueCount / cap) * 100).round().clamp(10, 100);

      // Determine operating status
      final opStatus = candidate.isNormal ? 'Open' : candidate.status;

      // Extract next available slot from SmartSlotService
      final slots = SmartSlotService.recommendSlots(
        centre: candidate,
        crop: crop,
      );
      final nextSlot = slots.firstWhere(
        (s) => s.isRecommended,
        orElse: () => slots.first,
      ).time;

      // Calculate composite score (lower is better):
      // (Wait * 1.0) + (Distance * 2.5) + (Load * 0.5)
      final score =
          (waitMinutes * 1.0) + (distanceKm * 2.5) + (loadPercent * 0.5);

      final waitSavings = (currentWaitMinutes - waitMinutes).clamp(0, 180);
      final distStr = distanceKm.toStringAsFixed(1);

      final reasonEn = waitSavings > 0
          ? 'Save ~$waitSavings min wait • $distStr km away • $loadPercent% load'
          : '$distStr km away • $loadPercent% load • Slot $nextSlot';

      final reasonHi = waitSavings > 0
          ? 'प्रतीक्षा समय में ~$waitSavings मिनट बचत • $distStr किमी दूर • $loadPercent% लोड'
          : '$distStr किमी दूर • $loadPercent% लोड • स्लॉट $nextSlot';

      final reasonTe = waitSavings > 0
          ? 'నిరీక్షణ సమయం ~$waitSavings నిమిషాలు తగ్గుతుంది • $distStr కి.మీ దూరం • $loadPercent% లోడ్'
          : '$distStr కి.మీ దూరం • $loadPercent% లోడ్ • స్లాట్ $nextSlot';

      recommendations.add(AlternativeCentreRecommendation(
        centre: candidate,
        distanceKm: distanceKm,
        estimatedWaitMinutes: waitMinutes,
        queueCount: queueCount,
        capacityPercent: loadPercent,
        operatingStatus: opStatus,
        nextAvailableSlot: nextSlot,
        score: score,
        reasonEn: reasonEn,
        reasonHi: reasonHi,
        reasonTe: reasonTe,
      ));
    }

    // Sort by composite score ascending (best options first)
    recommendations.sort((a, b) => a.score.compareTo(b.score));

    // Limit to 3 to 5 recommendations
    final topList = recommendations.take(5).toList();

    // Mark the top recommendation
    if (topList.isNotEmpty) {
      final top = topList[0];
      topList[0] = top.copyWith(isTopPick: true);
    }

    return topList;
  }
}
