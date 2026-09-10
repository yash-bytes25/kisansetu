/// Model representing a time slot for procurement.
class ProcurementSlot {
  final String id;
  final String time;
  final String tag;
  final String expectedWait;
  final int expectedWaitMinutes;
  final String recommendedArrival;
  final bool isRecommended;

  const ProcurementSlot({
    required this.id,
    required this.time,
    required this.tag,
    required this.expectedWait,
    required this.expectedWaitMinutes,
    required this.recommendedArrival,
    this.isRecommended = false,
  });
}
