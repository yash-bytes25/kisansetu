// KisanSetu (SIH26032) - Dispute Repository
// Abstract interface and dual Local/Supabase implementations.

import 'package:flutter/foundation.dart';
import '../../models/farmer_dispute_report.dart';
import '../supabase_service.dart';

/// Abstract repository defining farmer grievance and dispute filing operations.
abstract class DisputeRepository {
  Future<FarmerDisputeReport> submitDispute({
    required String farmerId,
    required String bookingId,
    required String category,
    required String description,
  });
  Future<List<FarmerDisputeReport>> getDisputes(String farmerId);
  Future<bool> updateDisputeStatus(String disputeId, String status);
}

/// Local in-memory implementation of [DisputeRepository].
class LocalDisputeRepository implements DisputeRepository {
  static final List<FarmerDisputeReport> _inMemoryDisputes = [];

  @override
  Future<FarmerDisputeReport> submitDispute({
    required String farmerId,
    required String bookingId,
    required String category,
    required String description,
  }) async {
    final report = FarmerDisputeReport(
      id: 'DISP-${DateTime.now().millisecondsSinceEpoch}',
      tokenNumber: bookingId,
      farmerName: 'Ramesh Kumar',
      reason: category,
      explanation: description,
      submittedAt: DateTime.now(),
      status: 'Submitted',
    );
    _inMemoryDisputes.add(report);
    return report;
  }

  @override
  Future<List<FarmerDisputeReport>> getDisputes(String farmerId) async {
    return List.unmodifiable(_inMemoryDisputes);
  }

  @override
  Future<bool> updateDisputeStatus(String disputeId, String status) async {
    for (int i = 0; i < _inMemoryDisputes.length; i++) {
      if (_inMemoryDisputes[i].id == disputeId) {
        _inMemoryDisputes[i] = FarmerDisputeReport(
          id: _inMemoryDisputes[i].id,
          tokenNumber: _inMemoryDisputes[i].tokenNumber,
          farmerName: _inMemoryDisputes[i].farmerName,
          reason: _inMemoryDisputes[i].reason,
          explanation: _inMemoryDisputes[i].explanation,
          submittedAt: _inMemoryDisputes[i].submittedAt,
          status: status,
        );
        return true;
      }
    }
    return true;
  }
}

/// Supabase persistent implementation of [DisputeRepository].
class SupabaseDisputeRepository implements DisputeRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  @override
  Future<FarmerDisputeReport> submitDispute({
    required String farmerId,
    required String bookingId,
    required String category,
    required String description,
  }) async {
    if (!_supabase.isReady) {
      return await LocalDisputeRepository().submitDispute(
        farmerId: farmerId,
        bookingId: bookingId,
        category: category,
        description: description,
      );
    }
    try {
      final trackingId = 'DSP-${DateTime.now().millisecondsSinceEpoch % 100000}';
      final response = await _supabase.client!.from('disputes').insert({
        'farmer_id': farmerId,
        'booking_id': bookingId,
        'category': category,
        'description': description,
        'tracking_id': trackingId,
        'status': 'submitted',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return FarmerDisputeReport(
        id: response['tracking_id']?.toString() ?? trackingId,
        tokenNumber: bookingId,
        farmerName: 'Ramesh Kumar',
        reason: category,
        explanation: description,
        submittedAt: DateTime.now(),
        status: 'Submitted',
      );
    } catch (e) {
      debugPrint('SupabaseDisputeRepository.submitDispute error: $e');
      return await LocalDisputeRepository().submitDispute(
        farmerId: farmerId,
        bookingId: bookingId,
        category: category,
        description: description,
      );
    }
  }

  @override
  Future<List<FarmerDisputeReport>> getDisputes(String farmerId) async {
    if (!_supabase.isReady) {
      return await LocalDisputeRepository().getDisputes(farmerId);
    }
    try {
      final List<dynamic> response = await _supabase.client!
          .from('disputes')
          .select()
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        return await LocalDisputeRepository().getDisputes(farmerId);
      }

      return response.map((row) {
        return FarmerDisputeReport(
          id: row['tracking_id']?.toString() ?? row['id']?.toString() ?? 'DSP-0000',
          tokenNumber: row['booking_id']?.toString() ?? 'TK-8492',
          farmerName: 'Ramesh Kumar',
          reason: row['category']?.toString() ?? 'General',
          explanation: row['description']?.toString(),
          submittedAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
          status: row['status']?.toString() ?? 'Submitted',
        );
      }).toList();
    } catch (e) {
      debugPrint('SupabaseDisputeRepository.getDisputes error: $e');
      return await LocalDisputeRepository().getDisputes(farmerId);
    }
  }

  @override
  Future<bool> updateDisputeStatus(String disputeId, String status) async {
    if (!_supabase.isReady) {
      return await LocalDisputeRepository().updateDisputeStatus(disputeId, status);
    }
    try {
      await _supabase.client!
          .from('disputes')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('tracking_id', disputeId);
      return true;
    } catch (e) {
      debugPrint('SupabaseDisputeRepository.updateDisputeStatus error: $e');
      return await LocalDisputeRepository().updateDisputeStatus(disputeId, status);
    }
  }
}
