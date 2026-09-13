/// Model representing procurement slot capacity and utilization on the officer side.
class ProcurementSlotInfo {
  final String time;
  final int bookingsCount;
  final int capacity;
  final String recommendationTag;
  final int? expectedArrivalsCount;

  const ProcurementSlotInfo({
    required this.time,
    required this.bookingsCount,
    required this.capacity,
    required this.recommendationTag,
    this.expectedArrivalsCount,
  });

  /// Available remaining slot capacity.
  int get availableCapacity => (capacity - bookingsCount).clamp(0, capacity);

  /// Expected arrivals for this slot window.
  int get expectedArrivals => expectedArrivalsCount ?? bookingsCount;

  /// Whether the slot is at or exceeding nominal capacity.
  bool get isOverloaded => bookingsCount >= capacity;

  /// Estimated congestion level tag: LOW, MODERATE, HIGH, CRITICAL.
  String get congestionTag {
    if (bookingsCount > capacity) return 'CRITICAL';
    if (bookingsCount >= capacity) return 'HIGH';
    if (capacity > 0 && bookingsCount >= (capacity * 0.85).round()) {
      return 'MODERATE';
    }
    return 'LOW';
  }

  /// Non-color status indicator with emoji/icon badge.
  String get congestionDisplayTag {
    switch (congestionTag) {
      case 'CRITICAL':
        return '⛔ CRITICAL';
      case 'HIGH':
        return '🔴 HIGH';
      case 'MODERATE':
        return '🟠 MODERATE';
      case 'LOW':
      default:
        return '🟢 LOW';
    }
  }

  ProcurementSlotInfo copyWith({
    String? time,
    int? bookingsCount,
    int? capacity,
    String? recommendationTag,
    int? expectedArrivalsCount,
  }) {
    return ProcurementSlotInfo(
      time: time ?? this.time,
      bookingsCount: bookingsCount ?? this.bookingsCount,
      capacity: capacity ?? this.capacity,
      recommendationTag: recommendationTag ?? this.recommendationTag,
      expectedArrivalsCount:
          expectedArrivalsCount ?? this.expectedArrivalsCount,
    );
  }
}
