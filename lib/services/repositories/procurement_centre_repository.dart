// KisanSetu (SIH26032) - Procurement Centre Repository
// Abstract interface and dual Local/Supabase implementations.

import 'package:flutter/foundation.dart';
import '../../models/procurement_centre.dart';
import '../procurement_state_service.dart';
import '../supabase_service.dart';

/// Abstract repository defining procurement centre discovery and operational status operations.
abstract class ProcurementCentreRepository {
  Future<List<ProcurementCentre>> getCentres();
  Future<ProcurementCentre?> getCentreById(String centreId);
  Future<bool> updateCentreOperations({
    required String centreId,
    String? operatingStatus,
    int? currentLoadPercent,
    int? delayMinutes,
  });
}

/// Local in-memory implementation of [ProcurementCentreRepository].
class LocalProcurementCentreRepository implements ProcurementCentreRepository {
  @override
  Future<List<ProcurementCentre>> getCentres() async {
    return ProcurementCentre.getMockCentres();
  }

  @override
  Future<ProcurementCentre?> getCentreById(String centreId) async {
    final centres = await getCentres();
    try {
      return centres.firstWhere((c) => c.id == centreId || c.name == centreId);
    } catch (_) {
      return centres.isNotEmpty ? centres.first : null;
    }
  }

  @override
  Future<bool> updateCentreOperations({
    required String centreId,
    String? operatingStatus,
    int? currentLoadPercent,
    int? delayMinutes,
  }) async {
    final state = ProcurementStateService();
    if (operatingStatus != null) {
      state.setCentreStatus(operatingStatus);
    }
    if (currentLoadPercent != null) {
      state.setCentreCapacityPercent(currentLoadPercent);
    }
    if (delayMinutes != null) {
      state.setCentreDelayMinutes(delayMinutes);
    }
    return true;
  }
}

/// Supabase persistent implementation of [ProcurementCentreRepository].
class SupabaseProcurementCentreRepository implements ProcurementCentreRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  @override
  Future<List<ProcurementCentre>> getCentres() async {
    if (!_supabase.isReady) {
      return await LocalProcurementCentreRepository().getCentres();
    }
    try {
      final List<dynamic> response = await _supabase.client!
          .from('procurement_centres')
          .select();

      if (response.isEmpty) {
        return await LocalProcurementCentreRepository().getCentres();
      }

      return response.map((row) {
        final statusStr = row['operating_status']?.toString() ??
            row['status']?.toString() ??
            'Open • Normal';
        final isNormal = statusStr.toLowerCase().contains('normal') ||
            statusStr.toLowerCase().contains('operational');
        final capacity = (row['capacity'] as num?)?.toInt() ?? 500;
        final currentLoad = (row['current_load_percent'] as num?)?.toInt() ?? 75;
        final delay = (row['delay_minutes'] as num?)?.toInt() ?? 0;
        final processingRate = (row['processing_rate_per_hour'] as num?)?.toInt() ?? 15;

        return ProcurementCentre(
          id: row['id'].toString(),
          name: row['name'].toString(),
          subLocation: row['location']?.toString() ?? '',
          status: statusStr,
          isNormal: isNormal,
          distance: '4.2 km',
          distanceKm: 4.2,
          queueStatus: currentLoad > 85 ? 'High' : (currentLoad > 70 ? 'Moderate' : 'Low'),
          queueEstimate: 'est. ${delay + 20} min',
          todayQueueCount: 12,
          estimatedWaitMinutes: delay + 20,
          capacity: capacity,
          processingRatePerHour: processingRate,
        );
      }).toList();
    } catch (e) {
      debugPrint('SupabaseProcurementCentreRepository.getCentres error: $e');
      return await LocalProcurementCentreRepository().getCentres();
    }
  }

  @override
  Future<ProcurementCentre?> getCentreById(String centreId) async {
    if (!_supabase.isReady) {
      return await LocalProcurementCentreRepository().getCentreById(centreId);
    }
    try {
      final response = await _supabase.client!
          .from('procurement_centres')
          .select()
          .eq('id', centreId)
          .maybeSingle();

      if (response == null) {
        return await LocalProcurementCentreRepository().getCentreById(centreId);
      }

      final statusStr = response['operating_status']?.toString() ??
          response['status']?.toString() ??
          'Open • Normal';
      final isNormal = statusStr.toLowerCase().contains('normal') ||
          statusStr.toLowerCase().contains('operational');
      final capacity = (response['capacity'] as num?)?.toInt() ?? 500;
      final delay = (response['delay_minutes'] as num?)?.toInt() ?? 0;

      return ProcurementCentre(
        id: response['id'].toString(),
        name: response['name'].toString(),
        subLocation: response['location']?.toString() ?? '',
        status: statusStr,
        isNormal: isNormal,
        distance: '4.2 km',
        distanceKm: 4.2,
        queueStatus: 'Normal',
        queueEstimate: 'est. ${delay + 20} min',
        todayQueueCount: 12,
        estimatedWaitMinutes: delay + 20,
        capacity: capacity,
        processingRatePerHour: (response['processing_rate_per_hour'] as num?)?.toInt() ?? 15,
      );
    } catch (e) {
      debugPrint('SupabaseProcurementCentreRepository.getCentreById error: $e');
      return await LocalProcurementCentreRepository().getCentreById(centreId);
    }
  }

  @override
  Future<bool> updateCentreOperations({
    required String centreId,
    String? operatingStatus,
    int? currentLoadPercent,
    int? delayMinutes,
  }) async {
    if (!_supabase.isReady) {
      return await LocalProcurementCentreRepository().updateCentreOperations(
        centreId: centreId,
        operatingStatus: operatingStatus,
        currentLoadPercent: currentLoadPercent,
        delayMinutes: delayMinutes,
      );
    }
    try {
      final Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (operatingStatus != null) {
        updates['operating_status'] = operatingStatus;
        updates['status'] = operatingStatus;
      }
      if (currentLoadPercent != null) {
        updates['current_load_percent'] = currentLoadPercent;
      }
      if (delayMinutes != null) {
        updates['delay_minutes'] = delayMinutes;
      }

      await _supabase.client!
          .from('procurement_centres')
          .update(updates)
          .eq('id', centreId);
      return true;
    } catch (e) {
      debugPrint('SupabaseProcurementCentreRepository.updateCentreOperations error: $e');
      return await LocalProcurementCentreRepository().updateCentreOperations(
        centreId: centreId,
        operatingStatus: operatingStatus,
        currentLoadPercent: currentLoadPercent,
        delayMinutes: delayMinutes,
      );
    }
  }
}
