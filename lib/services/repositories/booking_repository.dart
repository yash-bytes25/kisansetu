// KisanSetu (SIH26032) - Booking Repository
// Abstract interface and dual Local/Supabase implementations.

import 'package:flutter/foundation.dart';
import '../../config/supabase_config.dart';
import '../../models/procurement_centre.dart';
import '../procurement_state_service.dart';
import '../supabase_service.dart';

/// Abstract repository defining procurement booking operations and lifecycle management.
abstract class BookingRepository {
  Future<Map<String, dynamic>?> createBooking({
    required String farmerId,
    required String centreId,
    required String crop,
    required double quantity,
    required String slotTime,
    String? bookingDate,
    String? token,
  });

  Future<Map<String, dynamic>?> getBooking(String bookingId);
  Future<Map<String, dynamic>?> getBookingByToken(String token);
  Future<List<Map<String, dynamic>>> getFarmerBookings(String farmerId);
  Future<List<Map<String, dynamic>>> getCentreBookings(String centreId);
  Future<bool> updateBookingStatus(String bookingId, String status);
  Future<bool> updateBookingSlot(String bookingIdOrToken, String newSlot);
  Future<List<ProcurementCentre>> getProcurementCentres();
}

/// Local in-memory implementation of [BookingRepository].
class LocalBookingRepository implements BookingRepository {
  static final Map<String, Map<String, dynamic>> _inMemoryBookings = {};

  static void reset() {
    _inMemoryBookings.clear();
  }

  @override
  Future<Map<String, dynamic>?> createBooking({
    required String farmerId,
    required String centreId,
    required String crop,
    required double quantity,
    required String slotTime,
    String? bookingDate,
    String? token,
  }) async {
    final generatedToken =
        token ?? 'TK-${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}';
    final booking = {
      'id': 'BOOK-${DateTime.now().millisecondsSinceEpoch}',
      'farmer_id': farmerId,
      'centre_id': centreId,
      'crop': crop,
      'quantity': quantity,
      'slot_time': slotTime,
      'booking_date': bookingDate ?? 'Today',
      'token': generatedToken,
      'status': BookingLifecycleStatus.booked,
      'created_at': DateTime.now().toIso8601String(),
    };
    _inMemoryBookings[booking['id'] as String] = booking;
    _inMemoryBookings[generatedToken] = booking;
    return booking;
  }

  @override
  Future<Map<String, dynamic>?> getBooking(String bookingId) async {
    if (_inMemoryBookings.containsKey(bookingId)) {
      return _inMemoryBookings[bookingId];
    }
    final state = ProcurementStateService();
    final data = state.farmerData;
    final booking = {
      'id': bookingId,
      'farmer_id': '22222222-2222-2222-2222-222222222222',
      'centre_id': state.centreName,
      'crop': data.cropName,
      'quantity': double.tryParse(data.quantity.split(' ').first) ?? 50.0,
      'slot_time': data.bookedSlotTime ?? '11:30 AM',
      'token': data.tokenNumber,
      'status': BookingLifecycleStatus.booked,
      'created_at': DateTime.now().toIso8601String(),
    };
    _inMemoryBookings[bookingId] = booking;
    return booking;
  }

  @override
  Future<Map<String, dynamic>?> getBookingByToken(String token) async {
    if (_inMemoryBookings.containsKey(token)) {
      return _inMemoryBookings[token];
    }
    final state = ProcurementStateService();
    if (state.farmerData.tokenNumber == token) {
      return await getBooking('BOOK-8492');
    }
    for (final q in state.queue) {
      if (q.tokenNumber == token) {
        return {
          'id': 'BOOK-${q.tokenNumber}',
          'farmer_id': 'FARMER-${q.tokenNumber}',
          'centre_id': state.centreName,
          'crop': q.crop,
          'quantity': double.tryParse(q.quantity.split(' ').first) ?? 40.0,
          'slot_time': q.bookedSlot,
          'token': q.tokenNumber,
          'status': q.status.toUpperCase(),
          'created_at': DateTime.now().toIso8601String(),
        };
      }
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getFarmerBookings(String farmerId) async {
    final state = ProcurementStateService();
    final data = state.farmerData;
    return [
      {
        'id': 'BOOK-001',
        'farmer_id': farmerId,
        'centre_id': state.centreName,
        'crop': data.cropName,
        'quantity': double.tryParse(data.quantity.split(' ').first) ?? 50.0,
        'slot_time': data.bookedSlotTime ?? '11:30 AM',
        'token': data.tokenNumber,
        'status': BookingLifecycleStatus.booked,
        'created_at': DateTime.now().toIso8601String(),
      }
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> getCentreBookings(String centreId) async {
    final state = ProcurementStateService();
    return state.queue.map((item) {
      return {
        'id': 'BOOK-${item.tokenNumber}',
        'farmer_id': item.farmerName,
        'centre_id': centreId,
        'crop': item.crop,
        'quantity': item.quantity,
        'slot_time': item.bookedSlot,
        'token': item.tokenNumber,
        'status': item.status,
      };
    }).toList();
  }

  @override
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    final current = await getBooking(bookingId);
    final currentStatus = current?['status']?.toString() ?? BookingLifecycleStatus.booked;
    if (!BookingLifecycleStatus.canTransition(currentStatus, status)) {
      debugPrint('LocalBookingRepository: Invalid transition from $currentStatus to $status for booking $bookingId');
      return false;
    }
    if (_inMemoryBookings.containsKey(bookingId)) {
      _inMemoryBookings[bookingId]!['status'] = status.toUpperCase();
    }
    return true;
  }

  @override
  Future<bool> updateBookingSlot(String bookingIdOrToken, String newSlot) async {
    if (_inMemoryBookings.containsKey(bookingIdOrToken)) {
      _inMemoryBookings[bookingIdOrToken]!['slot_time'] = newSlot;
      return true;
    }
    for (final b in _inMemoryBookings.values) {
      if (b['token'] == bookingIdOrToken || b['id'] == bookingIdOrToken) {
        b['slot_time'] = newSlot;
        return true;
      }
    }
    return true;
  }

  @override
  Future<List<ProcurementCentre>> getProcurementCentres() async {
    return ProcurementCentre.getMockCentres();
  }
}

/// Supabase persistent implementation of [BookingRepository].
class SupabaseBookingRepository implements BookingRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  @override
  Future<Map<String, dynamic>?> createBooking({
    required String farmerId,
    required String centreId,
    required String crop,
    required double quantity,
    required String slotTime,
    String? bookingDate,
    String? token,
  }) async {
    if (!_supabase.isReady) {
      return await LocalBookingRepository().createBooking(
        farmerId: farmerId,
        centreId: centreId,
        crop: crop,
        quantity: quantity,
        slotTime: slotTime,
        bookingDate: bookingDate,
        token: token,
      );
    }
    try {
      final String generatedToken =
          token ?? 'TK-${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}';
      final response = await _supabase.client!
          .from('bookings')
          .insert({
            'farmer_id': farmerId,
            'centre_id': centreId,
            'slot_time': slotTime,
            'token': generatedToken,
            'status': BookingLifecycleStatus.booked,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      return response;
    } catch (e) {
      debugPrint('SupabaseBookingRepository.createBooking error: $e');
      return await LocalBookingRepository().createBooking(
        farmerId: farmerId,
        centreId: centreId,
        crop: crop,
        quantity: quantity,
        slotTime: slotTime,
        bookingDate: bookingDate,
        token: token,
      );
    }
  }

  Map<String, dynamic> _flattenBooking(Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    final produce = map['farmer_produce'] is Map
        ? Map<String, dynamic>.from(map['farmer_produce'] as Map)
        : (map['farmer_produce'] is List && (map['farmer_produce'] as List).isNotEmpty)
            ? Map<String, dynamic>.from((map['farmer_produce'] as List).first as Map)
            : null;
    final centre = map['procurement_centres'] is Map
        ? Map<String, dynamic>.from(map['procurement_centres'] as Map)
        : (map['procurement_centres'] is List && (map['procurement_centres'] as List).isNotEmpty)
            ? Map<String, dynamic>.from((map['procurement_centres'] as List).first as Map)
            : null;

    if (produce != null) {
      map['crop'] = map['crop'] ?? produce['crop'];
      map['quantity'] = map['quantity'] ?? produce['quantity'];
    }
    if (centre != null) {
      map['centre_name'] = map['centre_name'] ?? centre['name'];
    }
    return map;
  }

  @override
  Future<Map<String, dynamic>?> getBooking(String bookingId) async {
    if (!_supabase.isReady) {
      return await LocalBookingRepository().getBooking(bookingId);
    }
    try {
      final response = await _supabase.client!
          .from('bookings')
          .select('*, farmer_produce(id, crop, quantity), procurement_centres(id, name)')
          .eq('id', bookingId)
          .maybeSingle();
      if (response != null) {
        return _flattenBooking(response);
      }
      return await LocalBookingRepository().getBooking(bookingId);
    } catch (e) {
      debugPrint('SupabaseBookingRepository.getBooking error: $e');
      return await LocalBookingRepository().getBooking(bookingId);
    }
  }

  @override
  Future<Map<String, dynamic>?> getBookingByToken(String token) async {
    if (!_supabase.isReady) {
      return await LocalBookingRepository().getBookingByToken(token);
    }
    try {
      final response = await _supabase.client!
          .from('bookings')
          .select('*, farmer_produce(id, crop, quantity), procurement_centres(id, name)')
          .eq('token', token)
          .maybeSingle();
      if (response != null) {
        return _flattenBooking(response);
      }
      return await LocalBookingRepository().getBookingByToken(token);
    } catch (e) {
      debugPrint('SupabaseBookingRepository.getBookingByToken error: $e');
      return await LocalBookingRepository().getBookingByToken(token);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFarmerBookings(String farmerId) async {
    if (!_supabase.isReady) {
      return await LocalBookingRepository().getFarmerBookings(farmerId);
    }
    try {
      final List<dynamic> response = await _supabase.client!
          .from('bookings')
          .select('*, farmer_produce(id, crop, quantity), procurement_centres(id, name)')
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);
      if (response.isEmpty) {
        return await LocalBookingRepository().getFarmerBookings(farmerId);
      }
      return response.map<Map<String, dynamic>>((b) => _flattenBooking(b as Map)).toList();
    } catch (e) {
      debugPrint('SupabaseBookingRepository.getFarmerBookings error: $e');
      return await LocalBookingRepository().getFarmerBookings(farmerId);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCentreBookings(String centreId) async {
    if (!_supabase.isReady) {
      return await LocalBookingRepository().getCentreBookings(centreId);
    }
    try {
      final List<dynamic> response = await _supabase.client!
          .from('bookings')
          .select('*, farmer_produce(id, crop, quantity), procurement_centres(id, name)')
          .eq('centre_id', centreId)
          .order('created_at', ascending: false);
      if (response.isEmpty) {
        return await LocalBookingRepository().getCentreBookings(centreId);
      }
      return response.map<Map<String, dynamic>>((b) => _flattenBooking(b as Map)).toList();
    } catch (e) {
      debugPrint('SupabaseBookingRepository.getCentreBookings error: $e');
      return await LocalBookingRepository().getCentreBookings(centreId);
    }
  }

  @override
  Future<bool> updateBookingStatus(String bookingId, String status) async {
    if (!_supabase.isReady) {
      return await LocalBookingRepository().updateBookingStatus(bookingId, status);
    }
    try {
      final current = await getBooking(bookingId);
      final currentStatus = current?['status']?.toString() ?? BookingLifecycleStatus.booked;
      if (!BookingLifecycleStatus.canTransition(currentStatus, status)) {
        debugPrint('SupabaseBookingRepository: Invalid transition from $currentStatus to $status for booking $bookingId');
        return false;
      }
      await _supabase.client!
          .from('bookings')
          .update({
            'status': status.toUpperCase(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);
      return true;
    } catch (e) {
      debugPrint('SupabaseBookingRepository.updateBookingStatus error: $e');
      return await LocalBookingRepository().updateBookingStatus(bookingId, status);
    }
  }

  @override
  Future<bool> updateBookingSlot(String bookingIdOrToken, String newSlot) async {
    if (!_supabase.isReady) {
      return await LocalBookingRepository()
          .updateBookingSlot(bookingIdOrToken, newSlot);
    }
    try {
      await _supabase.client!
          .from('bookings')
          .update({
            'slot_time': newSlot,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .or('id.eq.$bookingIdOrToken,token.eq.$bookingIdOrToken');
      return true;
    } catch (e) {
      debugPrint('SupabaseBookingRepository.updateBookingSlot error: $e');
      return await LocalBookingRepository()
          .updateBookingSlot(bookingIdOrToken, newSlot);
    }
  }

  @override
  Future<List<ProcurementCentre>> getProcurementCentres() async {
    if (!_supabase.isReady) {
      return await LocalBookingRepository().getProcurementCentres();
    }
    try {
      final List<dynamic> response = await _supabase.client!
          .from('procurement_centres')
          .select();
      if (response.isEmpty) {
        return await LocalBookingRepository().getProcurementCentres();
      }
      return response.map((row) {
        return ProcurementCentre(
          id: row['id'].toString(),
          name: row['name'].toString(),
          subLocation: row['location']?.toString() ?? '',
          status: row['status']?.toString() ?? 'Open • Normal',
          isNormal: (row['status']?.toString() ?? '').toLowerCase().contains('normal'),
          distance: '4.2 km',
          distanceKm: 4.2,
          queueStatus: 'Low',
          queueEstimate: 'est. 15-20 min',
          todayQueueCount: 12,
          estimatedWaitMinutes: 20,
          capacity: (row['capacity'] as num?)?.toInt() ?? 500,
          processingRatePerHour: 15,
        );
      }).toList();
    } catch (e) {
      debugPrint('SupabaseBookingRepository.getProcurementCentres error: $e');
      return await LocalBookingRepository().getProcurementCentres();
    }
  }
}
