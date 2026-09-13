// KisanSetu (SIH26032) - Procurement Centre Repository
// Abstract interface and dual Local/Supabase implementations.

import 'package:flutter/foundation.dart';
import '../../models/procurement_centre.dart';
import '../procurement_state_service.dart';
import '../supabase_service.dart';

/// Abstract repository defining procurement centre discovery and operational status operations.
abstract class ProcurementCentreRepository {
  Future<List<ProcurementCentre>> getCentres();
  Future<List<ProcurementCentre>> getCentresByLocation({
    required String state,
    required String district,
    required String mandal,
  });
  Future<List<ProcurementCentre>> getNearbyCentres({
    required String state,
    required String district,
    double? latitude,
    double? longitude,
    int limit = 5,
  });
  Future<ProcurementCentre?> getCentreById(String centreId);
  Future<bool> updateCentreOperations({
    required String centreId,
    String? operatingStatus,
    int? currentLoadPercent,
    int? delayMinutes,
    int? capacity,
    int? processingRatePerHour,
  });
}

/// Local in-memory implementation of [ProcurementCentreRepository].
class LocalProcurementCentreRepository implements ProcurementCentreRepository {
  @override
  Future<List<ProcurementCentre>> getCentres() async {
    return ProcurementCentre.getMockCentres();
  }

  @override
  Future<List<ProcurementCentre>> getCentresByLocation({
    required String state,
    required String district,
    required String mandal,
  }) async {
    final all = await getCentres();
    return all.where((c) {
      final sMatch = c.state.toLowerCase() == state.toLowerCase();
      final dMatch = c.district.toLowerCase() == district.toLowerCase();
      final mMatch = c.mandal.toLowerCase() == mandal.toLowerCase();
      return sMatch && dMatch && mMatch;
    }).toList();
  }

  @override
  Future<List<ProcurementCentre>> getNearbyCentres({
    required String state,
    required String district,
    double? latitude,
    double? longitude,
    int limit = 5,
  }) async {
    final all = await getCentres();
    if (all.isEmpty) return [];

    // Filter centres preferably in the same state first, or all centres if none in state
    var candidates = all.where((c) => c.state.toLowerCase() == state.toLowerCase()).toList();
    if (candidates.isEmpty) {
      candidates = List.from(all);
    }

    // Sort based on geographic distance (not randomly)
    candidates.sort((a, b) {
      final aDist = a.calculateDistanceKmFrom(latitude, longitude) ?? a.distanceKm;
      final bDist = b.calculateDistanceKmFrom(latitude, longitude) ?? b.distanceKm;
      return aDist.compareTo(bDist);
    });

    return candidates.take(limit).toList();
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
    int? capacity,
    int? processingRatePerHour,
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
    if (capacity != null || processingRatePerHour != null) {
      state.updateCentreParameters(
        capacity: capacity,
        processingRatePerHour: processingRatePerHour,
      );
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
        // Return empty list gracefully when the Supabase table is empty.
        // Do not insert fake production data automatically.
        return [];
      }

      return response.map((row) => _mapRowToCentre(row)).toList();
    } catch (e) {
      debugPrint('SupabaseProcurementCentreRepository.getCentres error: $e');
      return await LocalProcurementCentreRepository().getCentres();
    }
  }

  @override
  Future<List<ProcurementCentre>> getCentresByLocation({
    required String state,
    required String district,
    required String mandal,
  }) async {
    if (!_supabase.isReady) {
      return await LocalProcurementCentreRepository().getCentresByLocation(
        state: state,
        district: district,
        mandal: mandal,
      );
    }
    try {
      final List<dynamic> response = await _supabase.client!
          .from('procurement_centres')
          .select()
          .ilike('state', state)
          .ilike('district', district)
          .ilike('mandal', mandal);

      if (response.isEmpty) {
        return [];
      }

      return response.map((row) => _mapRowToCentre(row)).toList();
    } catch (e) {
      debugPrint('SupabaseProcurementCentreRepository.getCentresByLocation error: $e');
      return await LocalProcurementCentreRepository().getCentresByLocation(
        state: state,
        district: district,
        mandal: mandal,
      );
    }
  }

  @override
  Future<List<ProcurementCentre>> getNearbyCentres({
    required String state,
    required String district,
    double? latitude,
    double? longitude,
    int limit = 5,
  }) async {
    if (!_supabase.isReady) {
      return await LocalProcurementCentreRepository().getNearbyCentres(
        state: state,
        district: district,
        latitude: latitude,
        longitude: longitude,
        limit: limit,
      );
    }
    try {
      // Query verified centres in the state from Supabase
      final List<dynamic> response = await _supabase.client!
          .from('procurement_centres')
          .select()
          .ilike('state', state);

      List<ProcurementCentre> candidates = [];
      if (response.isNotEmpty) {
        candidates = response.map((row) => _mapRowToCentre(row)).toList();
      } else {
        // Query nationwide verified centres
        final List<dynamic> allResponse = await _supabase.client!
            .from('procurement_centres')
            .select();
        if (allResponse.isNotEmpty) {
          candidates = allResponse.map((row) => _mapRowToCentre(row)).toList();
        }
      }

      if (candidates.isEmpty) {
        return [];
      }

      // Sort based on geographic distance
      candidates.sort((a, b) {
        final aDist = a.calculateDistanceKmFrom(latitude, longitude) ?? a.distanceKm;
        final bDist = b.calculateDistanceKmFrom(latitude, longitude) ?? b.distanceKm;
        return aDist.compareTo(bDist);
      });

      return candidates.take(limit).toList();
    } catch (e) {
      debugPrint('SupabaseProcurementCentreRepository.getNearbyCentres error: $e');
      return await LocalProcurementCentreRepository().getNearbyCentres(
        state: state,
        district: district,
        latitude: latitude,
        longitude: longitude,
        limit: limit,
      );
    }
  }

  ProcurementCentre _mapRowToCentre(dynamic row) {
    final statusStr = row['operating_status']?.toString() ??
        row['status']?.toString() ??
        'Open • Normal';
    final isNormal = statusStr.toLowerCase().contains('normal') ||
        statusStr.toLowerCase().contains('operational');
    final capacity = (row['capacity'] as num?)?.toInt() ?? 500;
    final currentLoad = (row['current_load_percent'] as num?)?.toInt() ?? 75;
    final delay = (row['delay_minutes'] as num?)?.toInt() ?? 0;
    final processingRate = (row['processing_rate_per_hour'] as num?)?.toInt() ?? 15;
    final lat = (row['latitude'] as num?)?.toDouble();
    final lng = (row['longitude'] as num?)?.toDouble();

    return ProcurementCentre(
      id: row['id'].toString(),
      name: row['name'].toString(),
      subLocation: row['location']?.toString() ?? '',
      address: row['address']?.toString() ?? row['location']?.toString(),
      state: row['state']?.toString() ?? 'Punjab',
      district: row['district']?.toString() ?? 'Ludhiana',
      mandal: row['mandal']?.toString() ?? 'Khanna',
      latitude: lat,
      longitude: lng,
      status: statusStr,
      operatingStatus: statusStr,
      isNormal: isNormal,
      distance: '4.2 km',
      distanceKm: 4.2,
      queueStatus: currentLoad > 85 ? 'High' : (currentLoad > 70 ? 'Moderate' : 'Low'),
      queueEstimate: 'est. ${delay + 20} min',
      todayQueueCount: 12,
      estimatedWaitMinutes: delay + 20,
      capacity: capacity,
      processingRatePerHour: processingRate,
      currentLoadPercent: currentLoad,
      availableSlotsCount: (row['available_slots'] as num?)?.toInt() ?? 10,
      supportedCrops: (row['supported_crops'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Wheat', 'Paddy (Rice)', 'Mustard', 'Cotton'],
    );
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
    int? capacity,
    int? processingRatePerHour,
  }) async {
    if (!_supabase.isReady) {
      return await LocalProcurementCentreRepository().updateCentreOperations(
        centreId: centreId,
        operatingStatus: operatingStatus,
        currentLoadPercent: currentLoadPercent,
        delayMinutes: delayMinutes,
        capacity: capacity,
        processingRatePerHour: processingRatePerHour,
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
      if (capacity != null) {
        updates['capacity'] = capacity;
      }
      if (processingRatePerHour != null) {
        updates['processing_rate_per_hour'] = processingRatePerHour;
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
        capacity: capacity,
        processingRatePerHour: processingRatePerHour,
      );
    }
  }
}
