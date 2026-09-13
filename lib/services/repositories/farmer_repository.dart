// KisanSetu (SIH26032) - Farmer Repository
// Abstract interface and dual Local/Supabase implementations.

import 'package:flutter/foundation.dart';
import '../supabase_service.dart';

/// Abstract repository defining farmer data operations.
abstract class FarmerRepository {
  Future<Map<String, dynamic>?> getFarmerProfile(String farmerId);
  Future<Map<String, dynamic>?> getFarmerByPhone(String phone);
  Future<Map<String, dynamic>?> createOrUpdateProfile({
    required String id,
    required String phone,
    required String name,
    required String preferredLanguage,
  });
  Future<bool> updateFarmerLanguage(String farmerId, String languageCode);
  Future<bool> updateKycDetails({
    required String farmerId,
    required String state,
    required String district,
    required String village,
  });
  Future<bool> updateBankDetails({
    required String farmerId,
    required String bankName,
    required String accountNumberMasked,
    required String ifscCode,
  });
  Future<List<Map<String, dynamic>>> getFarmerProduce(String farmerId);
  Future<Map<String, dynamic>?> saveFarmerProduce({
    required String farmerId,
    required String crop,
    required double quantity,
  });
}

/// Local fallback implementation of [FarmerRepository].
/// Operates 100% in-memory without external credentials or network access.
class LocalFarmerRepository implements FarmerRepository {
  static final Map<String, Map<String, dynamic>> _inMemoryFarmers = {
    '22222222-2222-2222-2222-222222222222': {
      'id': '22222222-2222-2222-2222-222222222222',
      'name': 'Ramesh Kumar',
      'phone': '9876543210',
      'preferred_language': 'hi',
      'created_at': DateTime.now().toIso8601String(),
    },
  };

  static final Map<String, List<Map<String, dynamic>>> _inMemoryProduce = {
    '22222222-2222-2222-2222-222222222222': [
      {
        'id': 'PROD-001',
        'farmer_id': '22222222-2222-2222-2222-222222222222',
        'crop': 'Wheat (गेहूं)',
        'quantity': 50.0,
        'created_at': DateTime.now().toIso8601String(),
      },
    ],
  };

  @override
  Future<Map<String, dynamic>?> getFarmerProfile(String farmerId) async {
    if (_inMemoryFarmers.containsKey(farmerId)) {
      return _inMemoryFarmers[farmerId];
    }
    return {
      'id': farmerId,
      'name': 'Ramesh Kumar',
      'phone': '9876543210',
      'preferred_language': 'hi',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>?> getFarmerByPhone(String phone) async {
    for (final f in _inMemoryFarmers.values) {
      if (f['phone'] == phone) return f;
    }
    return {
      'id': '22222222-2222-2222-2222-222222222222',
      'name': 'Ramesh Kumar',
      'phone': phone,
      'preferred_language': 'hi',
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>?> createOrUpdateProfile({
    required String id,
    required String phone,
    required String name,
    required String preferredLanguage,
  }) async {
    final record = {
      'id': id,
      'phone': phone,
      'name': name,
      'preferred_language': preferredLanguage,
      'updated_at': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    };
    _inMemoryFarmers[id] = record;
    return record;
  }

  @override
  Future<bool> updateFarmerLanguage(String farmerId, String languageCode) async {
    if (_inMemoryFarmers.containsKey(farmerId)) {
      _inMemoryFarmers[farmerId]!['preferred_language'] = languageCode;
    }
    debugPrint('LocalFarmerRepository: language updated to $languageCode for $farmerId');
    return true;
  }

  @override
  Future<bool> updateKycDetails({
    required String farmerId,
    required String state,
    required String district,
    required String village,
  }) async {
    final farmer = _inMemoryFarmers.putIfAbsent(farmerId, () => {
      'id': farmerId,
      'name': 'Ramesh Kumar',
      'phone': '9876543210',
      'preferred_language': 'hi',
    });
    farmer['state'] = state;
    farmer['district'] = district;
    farmer['village'] = village;
    farmer['updated_at'] = DateTime.now().toIso8601String();
    return true;
  }

  @override
  Future<bool> updateBankDetails({
    required String farmerId,
    required String bankName,
    required String accountNumberMasked,
    required String ifscCode,
  }) async {
    final farmer = _inMemoryFarmers.putIfAbsent(farmerId, () => {
      'id': farmerId,
      'name': 'Ramesh Kumar',
      'phone': '9876543210',
      'preferred_language': 'hi',
    });
    farmer['bank_name'] = bankName;
    farmer['account_number_masked'] = accountNumberMasked;
    farmer['ifsc_code'] = ifscCode;
    farmer['updated_at'] = DateTime.now().toIso8601String();
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> getFarmerProduce(String farmerId) async {
    if (_inMemoryProduce.containsKey(farmerId)) {
      return _inMemoryProduce[farmerId]!;
    }
    return [
      {
        'id': 'PROD-001',
        'farmer_id': farmerId,
        'crop': 'Wheat (गेहूं)',
        'quantity': 50.0,
        'created_at': DateTime.now().toIso8601String(),
      },
    ];
  }

  @override
  Future<Map<String, dynamic>?> saveFarmerProduce({
    required String farmerId,
    required String crop,
    required double quantity,
  }) async {
    final record = {
      'id': 'PROD-${DateTime.now().millisecondsSinceEpoch}',
      'farmer_id': farmerId,
      'crop': crop,
      'quantity': quantity,
      'created_at': DateTime.now().toIso8601String(),
    };
    final list = _inMemoryProduce.putIfAbsent(farmerId, () => []);
    list.insert(0, record);
    return record;
  }
}

/// Supabase persistent implementation of [FarmerRepository].
class SupabaseFarmerRepository implements FarmerRepository {
  final SupabaseService _supabase = SupabaseService.instance;

  @override
  Future<Map<String, dynamic>?> getFarmerProfile(String farmerId) async {
    if (!_supabase.isReady) {
      debugPrint('SupabaseFarmerRepository: client not ready, falling back to local');
      return await LocalFarmerRepository().getFarmerProfile(farmerId);
    }
    try {
      final response = await _supabase.client!
          .from('farmers')
          .select()
          .eq('id', farmerId)
          .maybeSingle();
      return response ?? await LocalFarmerRepository().getFarmerProfile(farmerId);
    } catch (e) {
      debugPrint('SupabaseFarmerRepository.getFarmerProfile error: $e');
      return await LocalFarmerRepository().getFarmerProfile(farmerId);
    }
  }

  @override
  Future<Map<String, dynamic>?> getFarmerByPhone(String phone) async {
    if (!_supabase.isReady) {
      return await LocalFarmerRepository().getFarmerByPhone(phone);
    }
    try {
      final response = await _supabase.client!
          .from('farmers')
          .select()
          .eq('phone', phone)
          .maybeSingle();
      return response ?? await LocalFarmerRepository().getFarmerByPhone(phone);
    } catch (e) {
      debugPrint('SupabaseFarmerRepository.getFarmerByPhone error: $e');
      return await LocalFarmerRepository().getFarmerByPhone(phone);
    }
  }

  @override
  Future<Map<String, dynamic>?> createOrUpdateProfile({
    required String id,
    required String phone,
    required String name,
    required String preferredLanguage,
  }) async {
    if (!_supabase.isReady) {
      return await LocalFarmerRepository().createOrUpdateProfile(
        id: id,
        phone: phone,
        name: name,
        preferredLanguage: preferredLanguage,
      );
    }
    try {
      final response = await _supabase.client!
          .from('farmers')
          .upsert({
            'id': id,
            'phone': phone,
            'name': name,
            'preferred_language': preferredLanguage,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      return response;
    } catch (e) {
      debugPrint('SupabaseFarmerRepository.createOrUpdateProfile error: $e');
      return await LocalFarmerRepository().createOrUpdateProfile(
        id: id,
        phone: phone,
        name: name,
        preferredLanguage: preferredLanguage,
      );
    }
  }

  @override
  Future<bool> updateFarmerLanguage(String farmerId, String languageCode) async {
    if (!_supabase.isReady) {
      return await LocalFarmerRepository().updateFarmerLanguage(farmerId, languageCode);
    }
    try {
      await _supabase.client!
          .from('farmers')
          .update({
            'preferred_language': languageCode,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', farmerId);
      return true;
    } catch (e) {
      debugPrint('SupabaseFarmerRepository.updateFarmerLanguage error: $e');
      return false;
    }
  }

  @override
  Future<bool> updateKycDetails({
    required String farmerId,
    required String state,
    required String district,
    required String village,
  }) async {
    if (!_supabase.isReady) {
      return await LocalFarmerRepository().updateKycDetails(
        farmerId: farmerId,
        state: state,
        district: district,
        village: village,
      );
    }
    try {
      await _supabase.client!
          .from('farmers')
          .update({
            'state': state,
            'district': district,
            'village': village,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', farmerId);
      return true;
    } catch (e) {
      debugPrint('SupabaseFarmerRepository.updateKycDetails error: $e');
      return await LocalFarmerRepository().updateKycDetails(
        farmerId: farmerId,
        state: state,
        district: district,
        village: village,
      );
    }
  }

  @override
  Future<bool> updateBankDetails({
    required String farmerId,
    required String bankName,
    required String accountNumberMasked,
    required String ifscCode,
  }) async {
    if (!_supabase.isReady) {
      return await LocalFarmerRepository().updateBankDetails(
        farmerId: farmerId,
        bankName: bankName,
        accountNumberMasked: accountNumberMasked,
        ifscCode: ifscCode,
      );
    }
    try {
      await _supabase.client!
          .from('farmers')
          .update({
            'bank_name': bankName,
            'account_number_masked': accountNumberMasked,
            'ifsc_code': ifscCode,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', farmerId);
      return true;
    } catch (e) {
      debugPrint('SupabaseFarmerRepository.updateBankDetails error: $e');
      return await LocalFarmerRepository().updateBankDetails(
        farmerId: farmerId,
        bankName: bankName,
        accountNumberMasked: accountNumberMasked,
        ifscCode: ifscCode,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getFarmerProduce(String farmerId) async {
    if (!_supabase.isReady) {
      return await LocalFarmerRepository().getFarmerProduce(farmerId);
    }
    try {
      final List<dynamic> response = await _supabase.client!
          .from('farmer_produce')
          .select()
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);
      if (response.isEmpty) {
        return await LocalFarmerRepository().getFarmerProduce(farmerId);
      }
      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('SupabaseFarmerRepository.getFarmerProduce error: $e');
      return await LocalFarmerRepository().getFarmerProduce(farmerId);
    }
  }

  @override
  Future<Map<String, dynamic>?> saveFarmerProduce({
    required String farmerId,
    required String crop,
    required double quantity,
  }) async {
    if (!_supabase.isReady) {
      return await LocalFarmerRepository().saveFarmerProduce(
        farmerId: farmerId,
        crop: crop,
        quantity: quantity,
      );
    }
    try {
      final response = await _supabase.client!
          .from('farmer_produce')
          .insert({
            'farmer_id': farmerId,
            'crop': crop,
            'quantity': quantity,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      return response;
    } catch (e) {
      debugPrint('SupabaseFarmerRepository.saveFarmerProduce error: $e');
      return await LocalFarmerRepository().saveFarmerProduce(
        farmerId: farmerId,
        crop: crop,
        quantity: quantity,
      );
    }
  }
}
