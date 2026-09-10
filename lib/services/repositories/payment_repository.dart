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
}

/// Local in-memory implementation of [PaymentRepository].
class LocalPaymentRepository implements PaymentRepository {
  static final Map<String, Map<String, dynamic>> _inMemoryPayments = {};

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
}
