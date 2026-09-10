// KisanSetu (SIH26032) - Procurement Repository
// Abstract interface and dual Local/Supabase implementations.

import 'package:flutter/foundation.dart';
import '../procurement_state_service.dart';
import '../supabase_service.dart';

/// Abstract repository defining physical procurement inspection, auditable weighment, and grading.
abstract class ProcurementRepository {
  Future<Map<String, dynamic>> getProcurementRecord(String bookingId);
  Future<bool> updateInspectionStage(String bookingId, String stage);
  Future<bool> recordWeighmentAndGrade({
    required String bookingId,
    required double actualQty,
    required String grade,
    required bool hasDiscrepancy,
    double? previousWeight,
    String? officerNotes,
  });
}

/// Local in-memory implementation of [ProcurementRepository].
class LocalProcurementRepository implements ProcurementRepository {
  static final Map<String, Map<String, dynamic>> _inMemoryRecords = {};

  @override
  Future<Map<String, dynamic>> getProcurementRecord(String bookingId) async {
    if (_inMemoryRecords.containsKey(bookingId)) {
      return _inMemoryRecords[bookingId]!;
    }
    final state = ProcurementStateService();
    final data = state.farmerData;
    return {
      'booking_id': bookingId,
      'expected_quantity': 50.0,
      'actual_quantity': double.tryParse(data.actualQuantity.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 50.2,
      'quality_grade': data.qualityGrade,
      'procurement_stage': data.lifecycleStatus,
      'discrepancy': false,
      'token': data.tokenNumber,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<bool> updateInspectionStage(String bookingId, String stage) async {
    final current = await getProcurementRecord(bookingId);
    _inMemoryRecords[bookingId] = {
      ...current,
      'procurement_stage': stage,
      'updated_at': DateTime.now().toIso8601String(),
    };
    return true;
  }

  @override
  Future<bool> recordWeighmentAndGrade({
    required String bookingId,
    required double actualQty,
    required String grade,
    required bool hasDiscrepancy,
    double? previousWeight,
    String? officerNotes,
  }) async {
    final current = await getProcurementRecord(bookingId);
    final prev = previousWeight ?? (current['actual_quantity'] as num?)?.toDouble();
    _inMemoryRecords[bookingId] = {
      ...current,
      'actual_quantity': actualQty,
      'previous_weight': prev,
      'weight_changed_at': DateTime.now().toIso8601String(),
      'quality_grade': grade,
      'discrepancy': hasDiscrepancy,
      'procurement_stage': 'acceptance',
      'officer_notes': officerNotes,
      'updated_at': DateTime.now().toIso8601String(),
    };
    return true;
  }
}

/// Supabase persistent implementation of [ProcurementRepository].
class SupabaseProcurementRepository implements ProcurementRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  @override
  Future<Map<String, dynamic>> getProcurementRecord(String bookingId) async {
    if (!_supabase.isReady) {
      return await LocalProcurementRepository().getProcurementRecord(bookingId);
    }
    try {
      final response = await _supabase.client!
          .from('procurement_records')
          .select()
          .eq('booking_id', bookingId)
          .maybeSingle();
      if (response != null) {
        return response;
      }
      return await LocalProcurementRepository().getProcurementRecord(bookingId);
    } catch (e) {
      debugPrint('SupabaseProcurementRepository.getProcurementRecord error: $e');
      return await LocalProcurementRepository().getProcurementRecord(bookingId);
    }
  }

  @override
  Future<bool> updateInspectionStage(String bookingId, String stage) async {
    if (!_supabase.isReady) {
      return await LocalProcurementRepository().updateInspectionStage(bookingId, stage);
    }
    try {
      await _supabase.client!
          .from('procurement_records')
          .update({
            'procurement_stage': stage,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('booking_id', bookingId);
      return true;
    } catch (e) {
      debugPrint('SupabaseProcurementRepository.updateInspectionStage error: $e');
      return await LocalProcurementRepository().updateInspectionStage(bookingId, stage);
    }
  }

  @override
  Future<bool> recordWeighmentAndGrade({
    required String bookingId,
    required double actualQty,
    required String grade,
    required bool hasDiscrepancy,
    double? previousWeight,
    String? officerNotes,
  }) async {
    if (!_supabase.isReady) {
      return await LocalProcurementRepository().recordWeighmentAndGrade(
        bookingId: bookingId,
        actualQty: actualQty,
        grade: grade,
        hasDiscrepancy: hasDiscrepancy,
        previousWeight: previousWeight,
        officerNotes: officerNotes,
      );
    }
    try {
      final existing = await getProcurementRecord(bookingId);
      final double? prev = previousWeight ?? (existing['actual_quantity'] as num?)?.toDouble();

      await _supabase.client!
          .from('procurement_records')
          .upsert({
            'booking_id': bookingId,
            'actual_quantity': actualQty,
            'previous_weight': prev,
            'weight_changed_at': prev != null && prev != actualQty ? DateTime.now().toIso8601String() : null,
            'quality_grade': grade,
            'discrepancy': hasDiscrepancy,
            'procurement_stage': 'acceptance',
            'officer_notes': officerNotes,
            'updated_at': DateTime.now().toIso8601String(),
          });
      return true;
    } catch (e) {
      debugPrint('SupabaseProcurementRepository.recordWeighmentAndGrade error: $e');
      return await LocalProcurementRepository().recordWeighmentAndGrade(
        bookingId: bookingId,
        actualQty: actualQty,
        grade: grade,
        hasDiscrepancy: hasDiscrepancy,
        previousWeight: previousWeight,
        officerNotes: officerNotes,
      );
    }
  }
}
