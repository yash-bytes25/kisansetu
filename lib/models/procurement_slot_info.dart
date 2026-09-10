/// Model representing procurement slot capacity and utilization on the officer side.
class ProcurementSlotInfo {
  final String time;
  final int bookingsCount;
  final int capacity;
  final String recommendationTag;

  const ProcurementSlotInfo({
    required this.time,
    required this.bookingsCount,
    required this.capacity,
    required this.recommendationTag,
  });

  ProcurementSlotInfo copyWith({
    String? time,
    int? bookingsCount,
    int? capacity,
    String? recommendationTag,
  }) {
    return ProcurementSlotInfo(
      time: time ?? this.time,
      bookingsCount: bookingsCount ?? this.bookingsCount,
      capacity: capacity ?? this.capacity,
      recommendationTag: recommendationTag ?? this.recommendationTag,
    );
  }
}
