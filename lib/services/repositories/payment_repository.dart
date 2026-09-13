// KisanSetu (SIH26032) - Payment Repository
// Abstract interface and dual Local/Supabase implementations.

import 'package:flutter/foundation.dart';
import '../../config/supabase_config.dart';
import '../procurement_state_service.dart';
import '../supabase_service.dart';

/// Abstract repository defining transparent MSP payment operations and lifecycle state transitions.
abstract class PaymentRepository {
  Future<Map<String, dynamic>> getPaymentDetails(String bookingId);
  Future<bool> updatePaymentStatus({
    required String bookingId,
    required String paymentStatus,
    double? grossAmount,
    double? deductions,
    double? netAmount,
    String? reference,
  });
  Future<bool> authorizePayment({
    required String bookingId,
    required double grossAmount,
    required double deductions,
    required double netAmount,
    required String reference,
  });
  Future<List<Map<String, dynamic>>> getFarmerPayments(String farmerId);
}

/// Local in-memory implementation of [PaymentRepository].
class LocalPaymentRepository implements PaymentRepository {
  static final Map<String, Map<String, dynamic>> _inMemoryPayments = {};

  static void reset() {
    _inMemoryPayments.clear();
  }

  @override
  Future<Map<String, dynamic>> getPaymentDetails(String bookingId) async {
    if (_inMemoryPayments.containsKey(bookingId)) {
      return _inMemoryPayments[bookingId]!;
    }
    final state = ProcurementStateService();
    final data = state.farmerData;
    return {
      'booking_id': bookingId,
      'gross_amount': data.grossAmount,
      'deductions': 0.0,
      'net_amount': data.netPayable,
      'payment_status': data.paymentStatus,
      'payment_reference': data.paymentReference,
      'payment_date': data.paymentDate,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<bool> updatePaymentStatus({
    required String bookingId,
    required String paymentStatus,
    double? grossAmount,
    double? deductions,
    double? netAmount,
    String? reference,
  }) async {
    final current = await getPaymentDetails(bookingId);
    final currentStatus = current['payment_status']?.toString() ?? PaymentLifecycleStatus.pending;
    if (!PaymentLifecycleStatus.canTransition(currentStatus, paymentStatus)) {
      debugPrint('LocalPaymentRepository: Invalid payment transition from $currentStatus to $paymentStatus for booking $bookingId');
      return false;
    }
    final map = Map<String, dynamic>.from(current);
    map['payment_status'] = paymentStatus;
    if (grossAmount != null) map['gross_amount'] = grossAmount;
    if (deductions != null) map['deductions'] = deductions;
    if (netAmount != null) map['net_amount'] = netAmount;
    if (reference != null) map['payment_reference'] = reference;
    map['updated_at'] = DateTime.now().toIso8601String();
    _inMemoryPayments[bookingId] = map;
    return true;
  }

  @override
  Future<bool> authorizePayment({
    required String bookingId,
    required double grossAmount,
    required double deductions,
    required double netAmount,
    required String reference,
  }) async {
    await updatePaymentStatus(
      bookingId: bookingId,
      paymentStatus: PaymentLifecycleStatus.processing,
      grossAmount: grossAmount,
      deductions: deductions,
      netAmount: netAmount,
      reference: reference,
    );
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> getFarmerPayments(String farmerId) async {
    final state = ProcurementStateService();
    final current = state.farmerData;
    final List<Map<String, dynamic>> results = [];

    // Current booking / payment
    if (current.tokenNumber.isNotEmpty && current.tokenNumber != 'None') {
      results.add({
        'id': 'PAY-${current.tokenNumber.replaceAll('TK-', '')}',
        'booking_id': 'BOOK-${current.tokenNumber.replaceAll('TK-', '')}',
        'token_number': current.tokenNumber,
        'crop_name': current.cropName,
        'quantity': current.quantity,
        'actual_quantity': current.actualQuantity,
        'quality_grade': current.qualityGrade,
        'centre_name': current.centreName,
        'gross_amount': current.grossAmount,
        'deductions': 0.0,
        'net_amount': current.netPayable,
        'payment_status': current.paymentStatus,
        'payment_reference': current.paymentReference,
        'payment_date': current.paymentDate,
        'date_time': '2026-09-09T11:30:00.000Z',
        'created_at': '2026-09-09T11:30:00.000Z',
      });
    }

    // Historical completed payments for Ramesh Kumar / demo farmer
    if (farmerId == '22222222-2222-2222-2222-222222222222' ||
        farmerId == 'Ramesh Kumar' ||
        farmerId.startsWith('9876543210')) {
      results.add({
        'id': 'PAY-7812',
        'booking_id': 'BOOK-7812',
        'token_number': 'TK-7812',
        'crop_name': 'Paddy',
        'quantity': '65 Quintals',
        'actual_quantity': '65.0 Quintals',
        'quality_grade': 'FAQ',
        'centre_name': 'Khanna Grain Market',
        'gross_amount': 149500.0,
        'deductions': 0.0,
        'net_amount': 149500.0,
        'payment_status': 'Completed',
        'payment_reference': 'PAY-2026-7812',
        'payment_date': '26 Aug 2026',
        'date_time': '2026-08-26T10:15:00.000Z',
        'created_at': '2026-08-26T10:15:00.000Z',
      });
      results.add({
        'id': 'PAY-6104',
        'booking_id': 'BOOK-6104',
        'token_number': 'TK-6104',
        'crop_name': 'Mustard',
        'quantity': '30 Quintals',
        'actual_quantity': '30.0 Quintals',
        'quality_grade': 'Grade A',
        'centre_name': 'Khanna Grain Market',
        'gross_amount': 169500.0,
        'deductions': 0.0,
        'net_amount': 169500.0,
        'payment_status': 'Completed',
        'payment_reference': 'PAY-2026-6104',
        'payment_date': '15 Apr 2026',
        'date_time': '2026-04-15T14:00:00.000Z',
        'created_at': '2026-04-15T14:00:00.000Z',
      });
    }

    // Sort newest first
    results.sort((a, b) {
      final dtA = DateTime.tryParse(a['date_time']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final dtB = DateTime.tryParse(b['date_time']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return dtB.compareTo(dtA);
    });

    return results;
  }
}

/// Supabase persistent implementation of [PaymentRepository].
class SupabasePaymentRepository implements PaymentRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  @override
  Future<Map<String, dynamic>> getPaymentDetails(String bookingId) async {
    if (!_supabase.isReady) {
      return await LocalPaymentRepository().getPaymentDetails(bookingId);
    }
    try {
      final response = await _supabase.client!
          .from('payments')
          .select()
          .eq('booking_id', bookingId)
          .maybeSingle();
      if (response != null) {
        return response;
      }
      return await LocalPaymentRepository().getPaymentDetails(bookingId);
    } catch (e) {
      debugPrint('SupabasePaymentRepository.getPaymentDetails error: $e');
      return await LocalPaymentRepository().getPaymentDetails(bookingId);
    }
  }

  @override
  Future<bool> updatePaymentStatus({
    required String bookingId,
    required String paymentStatus,
    double? grossAmount,
    double? deductions,
    double? netAmount,
    String? reference,
  }) async {
    if (!_supabase.isReady) {
      return await LocalPaymentRepository().updatePaymentStatus(
        bookingId: bookingId,
        paymentStatus: paymentStatus,
        grossAmount: grossAmount,
        deductions: deductions,
        netAmount: netAmount,
        reference: reference,
      );
    }
    try {
      final current = await getPaymentDetails(bookingId);
      final currentStatus = current['payment_status']?.toString() ?? PaymentLifecycleStatus.pending;
      if (!PaymentLifecycleStatus.canTransition(currentStatus, paymentStatus)) {
        debugPrint('SupabasePaymentRepository: Invalid payment transition from $currentStatus to $paymentStatus for booking $bookingId');
        return false;
      }
      final Map<String, dynamic> updates = {
        'payment_status': paymentStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (grossAmount != null) updates['gross_amount'] = grossAmount;
      if (deductions != null) updates['deductions'] = deductions;
      if (netAmount != null) updates['net_amount'] = netAmount;
      if (reference != null) updates['payment_reference'] = reference;

      await _supabase.client!
          .from('payments')
          .upsert({
            'booking_id': bookingId,
            ...updates,
          });
      return true;
    } catch (e) {
      debugPrint('SupabasePaymentRepository.updatePaymentStatus error: $e');
      return await LocalPaymentRepository().updatePaymentStatus(
        bookingId: bookingId,
        paymentStatus: paymentStatus,
        grossAmount: grossAmount,
        deductions: deductions,
        netAmount: netAmount,
        reference: reference,
      );
    }
  }

  @override
  Future<bool> authorizePayment({
    required String bookingId,
    required double grossAmount,
    required double deductions,
    required double netAmount,
    required String reference,
  }) async {
    if (!_supabase.isReady) {
      return await LocalPaymentRepository().authorizePayment(
        bookingId: bookingId,
        grossAmount: grossAmount,
        deductions: deductions,
        netAmount: netAmount,
        reference: reference,
      );
    }
    try {
      await _supabase.client!
          .from('payments')
          .upsert({
            'booking_id': bookingId,
            'gross_amount': grossAmount,
            'deductions': deductions,
            'net_amount': netAmount,
            'payment_status': PaymentLifecycleStatus.processing,
            'payment_reference': reference,
            'payment_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
      return true;
    } catch (e) {
      debugPrint('SupabasePaymentRepository.authorizePayment error: $e');
      return await LocalPaymentRepository().authorizePayment(
        bookingId: bookingId,
        grossAmount: grossAmount,
        deductions: deductions,
        netAmount: netAmount,
        reference: reference,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFarmerPayments(String farmerId) async {
    if (!_supabase.isReady) {
      return await LocalPaymentRepository().getFarmerPayments(farmerId);
    }
    try {
      final List<dynamic> response = await _supabase.client!
          .from('payments')
          .select('''
            id,
            booking_id,
            gross_amount,
            deductions,
            net_amount,
            payment_status,
            payment_reference,
            payment_date,
            created_at,
            bookings!inner(
              id,
              farmer_id,
              token,
              centre_id,
              procurement_centres(id, name),
              farmer_produce(id, crop, quantity),
              procurement_records(actual_quantity, quality_grade)
            )
          ''')
          .eq('bookings.farmer_id', farmerId)
          .order('payment_date', ascending: false);

      if (response.isNotEmpty) {
        return response.map<Map<String, dynamic>>((raw) {
          final map = Map<String, dynamic>.from(raw as Map);
          final booking = map['bookings'] is Map
              ? Map<String, dynamic>.from(map['bookings'] as Map)
              : (map['bookings'] is List && (map['bookings'] as List).isNotEmpty)
                  ? Map<String, dynamic>.from((map['bookings'] as List).first as Map)
                  : <String, dynamic>{};

          final produce = booking['farmer_produce'] is Map
              ? Map<String, dynamic>.from(booking['farmer_produce'] as Map)
              : (booking['farmer_produce'] is List && (booking['farmer_produce'] as List).isNotEmpty)
                  ? Map<String, dynamic>.from((booking['farmer_produce'] as List).first as Map)
                  : <String, dynamic>{};

          final centre = booking['procurement_centres'] is Map
              ? Map<String, dynamic>.from(booking['procurement_centres'] as Map)
              : (booking['procurement_centres'] is List && (booking['procurement_centres'] as List).isNotEmpty)
                  ? Map<String, dynamic>.from((booking['procurement_centres'] as List).first as Map)
                  : <String, dynamic>{};

          final procurement = booking['procurement_records'] is Map
              ? Map<String, dynamic>.from(booking['procurement_records'] as Map)
              : (booking['procurement_records'] is List && (booking['procurement_records'] as List).isNotEmpty)
                  ? Map<String, dynamic>.from((booking['procurement_records'] as List).first as Map)
                  : <String, dynamic>{};

          final token = booking['token']?.toString() ?? '';
          final crop = produce['crop']?.toString() ?? 'Wheat';
          final rawQty = produce['quantity'];
          final quantity = rawQty != null ? '$rawQty Quintals' : '50 Quintals';
          final rawActualQty = procurement['actual_quantity'];
          final actualQuantity = rawActualQty != null ? '$rawActualQty Quintals' : quantity;
          final qualityGrade = procurement['quality_grade']?.toString() ?? 'FAQ';
          final centreName = centre['name']?.toString() ?? 'Khanna Grain Market';

          final rawPaymentDate = map['payment_date']?.toString() ?? map['created_at']?.toString() ?? '';
          String formattedPaymentDate = rawPaymentDate;
          if (rawPaymentDate.isNotEmpty) {
            final dt = DateTime.tryParse(rawPaymentDate);
            if (dt != null) {
              const months = [
                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
              ];
              formattedPaymentDate =
                  '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
            }
          }

          final gross = (map['gross_amount'] as num?)?.toDouble() ?? 0.0;
          final ded = (map['deductions'] as num?)?.toDouble() ?? 0.0;
          final net = (map['net_amount'] as num?)?.toDouble() ?? (gross - ded);
          final status = map['payment_status']?.toString() ?? 'Pending';
          final ref = map['payment_reference']?.toString() ??
              (token.isNotEmpty ? 'PAY-${token.replaceAll('TK-', '')}' : 'PAY-2026-8492');

          return {
            'id': map['id']?.toString() ?? '',
            'booking_id': map['booking_id']?.toString() ?? booking['id']?.toString() ?? '',
            'token_number': token.isNotEmpty ? token : 'TK-8492',
            'token': token.isNotEmpty ? token : 'TK-8492',
            'crop_name': crop,
            'crop': crop,
            'quantity': quantity,
            'actual_quantity': actualQuantity,
            'quality_grade': qualityGrade,
            'centre_name': centreName,
            'centre': centreName,
            'gross_amount': gross,
            'deductions': ded,
            'net_amount': net,
            'payment_amount': net,
            'payment_status': status,
            'payment_reference': ref,
            'payment_date': formattedPaymentDate,
            'date_time': rawPaymentDate,
            'created_at': map['created_at']?.toString() ?? '',
            'bookings': booking,
          };
        }).toList();
      }
      return await LocalPaymentRepository().getFarmerPayments(farmerId);
    } catch (e) {
      debugPrint('SupabasePaymentRepository.getFarmerPayments error: $e');
      return await LocalPaymentRepository().getFarmerPayments(farmerId);
    }
  }
}
