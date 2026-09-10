import '../models/procurement_centre.dart';
import '../models/procurement_slot.dart';

/// Service responsible for recommending the best arrival windows based on
/// centre load, queue length, intake rate, and capacity.
///
/// Implemented using a deterministic local algorithm ready for future integration
/// with the Smart Slot / Queue Prediction Engine.
class SmartSlotService {
  /// Computes recommended slots for a given procurement centre.
  static List<ProcurementSlot> recommendSlots({
    required ProcurementCentre centre,
    int? currentQueue,
    int? capacity,
    int? processingRate,
    String? crop,
  }) {
    final queue = currentQueue ?? centre.todayQueueCount;
    final cap = capacity ?? centre.capacity;
    final rate = processingRate ?? centre.processingRatePerHour;

    // Deterministic load index based on centre queue and rate
    final loadRatio = (queue / (cap > 0 ? cap : 100)).clamp(0.1, 1.0);

    if (centre.isNormal || loadRatio < 0.3) {
      return [
        const ProcurementSlot(
          id: 'slot_1',
          time: '10:30 AM',
          tag: 'Good',
          expectedWait: '25 min',
          expectedWaitMinutes: 25,
          recommendedArrival: '10:15 AM',
          isRecommended: false,
        ),
        const ProcurementSlot(
          id: 'slot_2',
          time: '11:30 AM',
          tag: 'Recommended',
          expectedWait: '15 min',
          expectedWaitMinutes: 15,
          recommendedArrival: '11:20 AM',
          isRecommended: true,
        ),
        const ProcurementSlot(
          id: 'slot_3',
          time: '1:00 PM',
          tag: 'Busy',
          expectedWait: '45 min',
          expectedWaitMinutes: 45,
          recommendedArrival: '12:45 PM',
          isRecommended: false,
        ),
      ];
    } else {
      // Busiere centres shift windows
      final waitAdjustment = (rate > 0 ? (queue / rate) * 15 : 30).round();
      return [
        ProcurementSlot(
          id: 'slot_b1',
          time: '11:00 AM',
          tag: 'Good',
          expectedWait: '$waitAdjustment min',
          expectedWaitMinutes: waitAdjustment,
          recommendedArrival: '10:45 AM',
          isRecommended: false,
        ),
        const ProcurementSlot(
          id: 'slot_b2',
          time: '11:30 AM',
          tag: 'Recommended',
          expectedWait: '15 min',
          expectedWaitMinutes: 15,
          recommendedArrival: '11:20 AM',
          isRecommended: true,
        ),
        ProcurementSlot(
          id: 'slot_b3',
          time: '2:30 PM',
          tag: 'Busy',
          expectedWait: '${waitAdjustment + 20} min',
          expectedWaitMinutes: waitAdjustment + 20,
          recommendedArrival: '2:15 PM',
          isRecommended: false,
        ),
      ];
    }
  }

  /// Generates the next sequential mock token.
  ///
  /// Increments deterministically (e.g. TK-8492 -> TK-8493).
  static String generateNextToken(String currentToken) {
    final prefix = currentToken.split('-').first;
    final numberPart = currentToken.split('-').last;
    final nextNumber = (int.tryParse(numberPart) ?? 8492) + 1;
    return '$prefix-$nextNumber';
  }
}
