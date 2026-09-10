// KisanSetu (SIH26032) - Queue Repository
// Abstract interface and dual Local/Supabase implementations.

import 'package:flutter/foundation.dart';
import '../../models/officer_queue_item.dart';
import '../procurement_state_service.dart';
import '../supabase_service.dart';

/// Abstract repository defining live queue tracking and sequence progression operations.
abstract class QueueRepository {
  Future<Map<String, dynamic>> getQueueStatus(String bookingId);
  Future<Map<String, dynamic>?> createQueueEntry({
    required String bookingId,
    int? sequenceNumber,
    int? position,
    int? peopleAhead,
    String? status,
    int? estimatedWaitMinutes,
    String? expectedTurn,
  });
  Future<bool> advanceQueue(String bookingId);
  Future<bool> updateQueueStatus(
    String bookingId, {
    required String status,
    int? peopleAhead,
    int? waitMinutes,
    String? expectedTurn,
  });
  Future<List<OfficerQueueItem>> getOfficerQueue(String centreId);
}

/// Local in-memory implementation of [QueueRepository].
class LocalQueueRepository implements QueueRepository {
  static final Map<String, Map<String, dynamic>> _inMemoryQueueEntries = {};
  static int _sequenceCounter = 100;

  @override
  Future<Map<String, dynamic>> getQueueStatus(String bookingId) async {
    if (_inMemoryQueueEntries.containsKey(bookingId)) {
      return _inMemoryQueueEntries[bookingId]!;
    }
    final state = ProcurementStateService();
    final data = state.farmerData;
    return {
      'booking_id': bookingId,
      'sequence_number': 107,
      'position': data.peopleAhead + 1,
      'people_ahead': data.peopleAhead,
      'status': data.peopleAhead == 0 ? 'in_inspection' : 'waiting',
      'estimated_wait_minutes': data.expectedWaitMinutes,
      'expected_turn': data.expectedTurnTime,
      'token': data.tokenNumber,
    };
  }

  @override
  Future<Map<String, dynamic>?> createQueueEntry({
    required String bookingId,
    int? sequenceNumber,
    int? position,
    int? peopleAhead,
    String? status,
    int? estimatedWaitMinutes,
    String? expectedTurn,
  }) async {
    _sequenceCounter++;
    final entry = {
      'id': 'Q-${DateTime.now().millisecondsSinceEpoch}',
      'booking_id': bookingId,
      'sequence_number': sequenceNumber ?? _sequenceCounter,
      'position': position ?? 1,
      'people_ahead': peopleAhead ?? 0,
      'status': status ?? 'waiting',
      'estimated_wait_minutes': estimatedWaitMinutes ?? 15,
      'expected_turn': expectedTurn ?? '12:00 PM',
      'updated_at': DateTime.now().toIso8601String(),
    };
    _inMemoryQueueEntries[bookingId] = entry;
    return entry;
  }

  @override
  Future<bool> advanceQueue(String bookingId) async {
    final current = await getQueueStatus(bookingId);
    final int peopleAhead = (current['people_ahead'] as num?)?.toInt() ?? 1;
    final int nextAhead = (peopleAhead - 1).clamp(0, 999);
    _inMemoryQueueEntries[bookingId] = {
      ...current,
      'people_ahead': nextAhead,
      'position': nextAhead + 1,
      'status': nextAhead == 0 ? 'in_inspection' : 'waiting',
      'updated_at': DateTime.now().toIso8601String(),
    };
    return true;
  }

  @override
  Future<bool> updateQueueStatus(
    String bookingId, {
    required String status,
    int? peopleAhead,
    int? waitMinutes,
    String? expectedTurn,
  }) async {
    final current = await getQueueStatus(bookingId);
    final map = Map<String, dynamic>.from(current);
    map['status'] = status;
    if (peopleAhead != null) {
      map['people_ahead'] = peopleAhead;
      map['position'] = peopleAhead + 1;
    }
    if (waitMinutes != null) {
      map['estimated_wait_minutes'] = waitMinutes;
    }
    if (expectedTurn != null) {
      map['expected_turn'] = expectedTurn;
    }
    map['updated_at'] = DateTime.now().toIso8601String();
    _inMemoryQueueEntries[bookingId] = map;
    return true;
  }

  @override
  Future<List<OfficerQueueItem>> getOfficerQueue(String centreId) async {
    return ProcurementStateService().queue;
  }
}

/// Supabase persistent implementation of [QueueRepository].
class SupabaseQueueRepository implements QueueRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  @override
  Future<Map<String, dynamic>> getQueueStatus(String bookingId) async {
    if (!_supabase.isReady) {
      return await LocalQueueRepository().getQueueStatus(bookingId);
    }
    try {
      final response = await _supabase.client!
          .from('queue_entries')
          .select()
          .eq('booking_id', bookingId)
          .maybeSingle();
      if (response != null) {
        return response;
      }
      return await LocalQueueRepository().getQueueStatus(bookingId);
    } catch (e) {
      debugPrint('SupabaseQueueRepository.getQueueStatus error: $e');
      return await LocalQueueRepository().getQueueStatus(bookingId);
    }
  }

  @override
  Future<Map<String, dynamic>?> createQueueEntry({
    required String bookingId,
    int? sequenceNumber,
    int? position,
    int? peopleAhead,
    String? status,
    int? estimatedWaitMinutes,
    String? expectedTurn,
  }) async {
    if (!_supabase.isReady) {
      return await LocalQueueRepository().createQueueEntry(
        bookingId: bookingId,
        sequenceNumber: sequenceNumber,
        position: position,
        peopleAhead: peopleAhead,
        status: status,
        estimatedWaitMinutes: estimatedWaitMinutes,
        expectedTurn: expectedTurn,
      );
    }
    try {
      final Map<String, dynamic> payload = {
        'booking_id': bookingId,
        'position': position ?? 1,
        'people_ahead': peopleAhead ?? 0,
        'status': status ?? 'waiting',
        'estimated_wait_minutes': estimatedWaitMinutes ?? 15,
        'expected_turn': expectedTurn ?? '12:00 PM',
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (sequenceNumber != null) {
        payload['sequence_number'] = sequenceNumber;
      }

      final response = await _supabase.client!
          .from('queue_entries')
          .upsert(payload)
          .select()
          .single();
      return response;
    } catch (e) {
      debugPrint('SupabaseQueueRepository.createQueueEntry error: $e');
      return await LocalQueueRepository().createQueueEntry(
        bookingId: bookingId,
        sequenceNumber: sequenceNumber,
        position: position,
        peopleAhead: peopleAhead,
        status: status,
        estimatedWaitMinutes: estimatedWaitMinutes,
        expectedTurn: expectedTurn,
      );
    }
  }

  @override
  Future<bool> advanceQueue(String bookingId) async {
    if (!_supabase.isReady) {
      return await LocalQueueRepository().advanceQueue(bookingId);
    }
    try {
      final current = await getQueueStatus(bookingId);
      final int peopleAhead = (current['people_ahead'] as num?)?.toInt() ?? 1;
      final int nextAhead = (peopleAhead - 1).clamp(0, 999);
      await _supabase.client!
          .from('queue_entries')
          .update({
            'people_ahead': nextAhead,
            'position': nextAhead + 1,
            'status': nextAhead == 0 ? 'in_inspection' : 'waiting',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('booking_id', bookingId);
      return true;
    } catch (e) {
      debugPrint('SupabaseQueueRepository.advanceQueue error: $e');
      return await LocalQueueRepository().advanceQueue(bookingId);
    }
  }

  @override
  Future<bool> updateQueueStatus(
    String bookingId, {
    required String status,
    int? peopleAhead,
    int? waitMinutes,
    String? expectedTurn,
  }) async {
    if (!_supabase.isReady) {
      return await LocalQueueRepository().updateQueueStatus(
        bookingId,
        status: status,
        peopleAhead: peopleAhead,
        waitMinutes: waitMinutes,
        expectedTurn: expectedTurn,
      );
    }
    try {
      final Map<String, dynamic> updates = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (peopleAhead != null) {
        updates['people_ahead'] = peopleAhead;
        updates['position'] = peopleAhead + 1;
      }
      if (waitMinutes != null) {
        updates['estimated_wait_minutes'] = waitMinutes;
      }
      if (expectedTurn != null) {
        updates['expected_turn'] = expectedTurn;
      }

      await _supabase.client!
          .from('queue_entries')
          .update(updates)
          .eq('booking_id', bookingId);
      return true;
    } catch (e) {
      debugPrint('SupabaseQueueRepository.updateQueueStatus error: $e');
      return await LocalQueueRepository().updateQueueStatus(
        bookingId,
        status: status,
        peopleAhead: peopleAhead,
        waitMinutes: waitMinutes,
        expectedTurn: expectedTurn,
      );
    }
  }

  @override
  Future<List<OfficerQueueItem>> getOfficerQueue(String centreId) async {
    return await LocalQueueRepository().getOfficerQueue(centreId);
  }
}
