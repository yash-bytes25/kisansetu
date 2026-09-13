// KisanSetu (SIH26032) - Authentication Service
// Bridges Local Demo and Supabase Auth sessions while enforcing RLS ownership.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'repositories/repository_provider.dart';
import 'supabase_service.dart';

/// Role of the authenticated user in KisanSetu.
enum UserRole { farmer, officer }

/// Result wrapper for authentication attempts.
class AuthResult {
  final bool isSuccess;
  final String? userId;
  final String? phone;
  final String? officerId;
  final String? centreId;
  final String? errorMessage;

  const AuthResult({
    required this.isSuccess,
    this.userId,
    this.phone,
    this.officerId,
    this.centreId,
    this.errorMessage,
  });
}

/// Immutable representation of the restored session state on app launch / browser refresh.
class AuthSessionState {
  final bool isAuthenticated;
  final UserRole? role;
  final String? userId;
  final String? officerId;
  final String? centreId;
  final String? phone;

  const AuthSessionState({
    required this.isAuthenticated,
    this.role,
    this.userId,
    this.officerId,
    this.centreId,
    this.phone,
  });

  static const unauthenticated = AuthSessionState(isAuthenticated: false);
}

/// Authentication service managing user sessions, Supabase Auth tokens, and local demo logins.
class AuthService {
  AuthService._() {
    _initializeAuthListener();
  }
  static final AuthService instance = AuthService._();

  String? _currentUserId;
  String? _currentPhone;
  String? _currentOfficerId;
  String? _currentCentreId;
  UserRole? _currentRole;

  String? get currentUserId => _currentUserId;
  String? get currentPhone => _currentPhone;
  String? get currentOfficerId => _currentOfficerId;
  String? get currentCentreId => _currentCentreId;
  UserRole? get currentRole => _currentRole;
  bool get isOfficer => _currentRole == UserRole.officer;
  bool get isFarmer => _currentRole == UserRole.farmer;
  bool get isDemoMode => SupabaseConfig.backendMode == BackendMode.local;

  bool get isAuthenticated =>
      _currentUserId != null || _currentOfficerId != null;

  /// Sets officer session directly for testing or demo role selection.
  void setOfficerSession({required String officerId, required String centreId}) {
    _currentOfficerId = officerId;
    _currentCentreId = centreId;
    _currentRole = UserRole.officer;
    _currentUserId = null;
    _currentPhone = null;
  }

  /// Sets demo role for testing.
  void setDemoRole(String role, {String? officerId, String? centreId}) {
    if (role.toLowerCase() == 'officer') {
      _currentRole = UserRole.officer;
      _currentOfficerId = officerId ?? 'OFFICER001';
      _currentCentreId = centreId ?? '11111111-1111-1111-1111-111111111111';
      _currentUserId = null;
      _currentPhone = null;
    } else {
      _currentRole = UserRole.farmer;
      _currentUserId = '22222222-2222-2222-2222-222222222222';
      _currentPhone = '9876543210';
      _currentOfficerId = null;
      _currentCentreId = null;
    }
  }

  void _initializeAuthListener() {
    if (SupabaseConfig.shouldUseSupabase && SupabaseService.instance.isReady) {
      SupabaseService.instance.client?.auth.onAuthStateChange.listen((data) {
        if (data.event == AuthChangeEvent.signedOut) {
          _currentUserId = null;
          _currentPhone = null;
          _currentOfficerId = null;
          _currentCentreId = null;
          _currentRole = null;
        }
      });
    }
  }

  /// Restores existing authentication session on application launch or browser refresh.
  ///
  /// In Supabase mode, the active session is read from Supabase Auth storage.
  /// If valid, the farmer or officer profile is restored into state so the user
  /// immediately transitions to the appropriate dashboard without flashing login.
  Future<AuthSessionState> restoreSession() async {
    if (!SupabaseConfig.shouldUseSupabase) {
      return AuthSessionState.unauthenticated;
    }

    final supabase = SupabaseService.instance;
    if (!supabase.isReady || supabase.client == null) {
      return AuthSessionState.unauthenticated;
    }

    try {
      final session = supabase.client!.auth.currentSession;
      if (session == null || session.isExpired) {
        return AuthSessionState.unauthenticated;
      }

      final user = session.user;
      final metadata = user.userMetadata ?? {};
      final roleStr = (metadata['role'] ?? '').toString().toLowerCase();

      final isOfficer = roleStr == 'officer' ||
          user.email?.toLowerCase().contains('officer') == true;

      if (isOfficer) {
        final officerId = metadata['officer_id']?.toString() ?? 'OFFICER001';
        final centreId = metadata['centre_id']?.toString() ??
            '11111111-1111-1111-1111-111111111111';

        _currentOfficerId = officerId;
        _currentCentreId = centreId;
        _currentRole = UserRole.officer;
        _currentUserId = null;
        _currentPhone = null;

        return AuthSessionState(
          isAuthenticated: true,
          role: UserRole.officer,
          officerId: officerId,
          centreId: centreId,
        );
      } else {
        final phone =
            metadata['phone']?.toString() ?? user.phone ?? '9876543210';
        final farmerId = metadata['farmer_id']?.toString() ??
            '22222222-2222-2222-2222-222222222222';

        _currentUserId = farmerId;
        _currentPhone = phone;
        _currentRole = UserRole.farmer;
        _currentOfficerId = null;
        _currentCentreId = null;

        return AuthSessionState(
          isAuthenticated: true,
          role: UserRole.farmer,
          userId: farmerId,
          phone: phone,
        );
      }
    } catch (e) {
      debugPrint('AuthService.restoreSession error: $e');
      return AuthSessionState.unauthenticated;
    }
  }

  /// Helper to establish a persistent Supabase Auth session for farmer demo login.
  Future<void> _establishSupabaseFarmerSession(
      String cleanPhone, String farmerId) async {
    final supabase = SupabaseService.instance;
    if (!supabase.isReady || supabase.client == null) return;

    final phoneDigits = cleanPhone.isEmpty ? '9876543210' : cleanPhone;
    final email = 'farmer_$phoneDigits@kisansetu.gov.in';
    const pwd = 'KisanFarmer#2026';

    try {
      await supabase.client!.auth.signInWithPassword(
        email: email,
        password: pwd,
      );
    } catch (_) {
      try {
        await supabase.client!.auth.signUp(
          email: email,
          password: pwd,
          data: {
            'role': 'farmer',
            'farmer_id': farmerId,
            'phone': phoneDigits,
          },
        );
      } catch (_) {
        try {
          await supabase.client!.auth.signInAnonymously(
            data: {
              'role': 'farmer',
              'farmer_id': farmerId,
              'phone': phoneDigits,
            },
          );
        } catch (err) {
          debugPrint('Supabase farmer demo session notice: $err');
        }
      }
    }
  }

  /// Helper to establish a persistent Supabase Auth session for officer demo login.
  Future<void> _establishSupabaseOfficerSession(
      String officerId, String centreId) async {
    final supabase = SupabaseService.instance;
    if (!supabase.isReady || supabase.client == null) return;

    final email = '${officerId.toLowerCase()}@kisansetu.gov.in';
    const pwd = 'KisanOfficer#2026';

    try {
      await supabase.client!.auth.signInWithPassword(
        email: email,
        password: pwd,
      );
    } catch (_) {
      try {
        await supabase.client!.auth.signUp(
          email: email,
          password: pwd,
          data: {
            'role': 'officer',
            'officer_id': officerId,
            'centre_id': centreId,
          },
        );
      } catch (_) {
        try {
          await supabase.client!.auth.signInAnonymously(
            data: {
              'role': 'officer',
              'officer_id': officerId,
              'centre_id': centreId,
            },
          );
        } catch (err) {
          debugPrint('Supabase officer demo session notice: $err');
        }
      }
    }
  }

  /// Verifies farmer phone OTP.
  Future<AuthResult> verifyFarmerOtp({
    required String phoneNumber,
    required String otp,
    String preferredLanguage = 'hi',
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // In Local Mode (or when not using Supabase), enforce prototype demo rules
    if (!SupabaseConfig.shouldUseSupabase) {
      if (otp == '123456') {
        _currentUserId = '22222222-2222-2222-2222-222222222222';
        _currentPhone = cleanPhone.isEmpty ? '9876543210' : cleanPhone;
        _currentRole = UserRole.farmer;
        _currentOfficerId = null;
        _currentCentreId = null;
        return AuthResult(
          isSuccess: true,
          userId: _currentUserId,
          phone: _currentPhone,
        );
      } else {
        return const AuthResult(
          isSuccess: false,
          errorMessage: 'Invalid OTP. For demo prototype, please use 123456.',
        );
      }
    }

    // In Supabase Mode
    final supabase = SupabaseService.instance;
    if (!supabase.isReady) {
      // Graceful fallback to local demo verification if Supabase is temporarily unreachable
      debugPrint(
          'AuthService: Supabase not ready, evaluating with demo credentials');
      if (otp == '123456') {
        _currentUserId = '22222222-2222-2222-2222-222222222222';
        _currentPhone = cleanPhone.isEmpty ? '9876543210' : cleanPhone;
        _currentRole = UserRole.farmer;
        _currentOfficerId = null;
        _currentCentreId = null;
        return AuthResult(
          isSuccess: true,
          userId: _currentUserId,
          phone: _currentPhone,
        );
      }
      return const AuthResult(
        isSuccess: false,
        errorMessage:
            'Authentication service unavailable. Please check connectivity.',
      );
    }

    try {
      // If demo credentials used in Supabase mode for testing/staging
      if (otp == '123456') {
        final existing =
            await RepositoryProvider.farmer.getFarmerByPhone(cleanPhone);
        final farmerId = existing?['id']?.toString() ??
            '22222222-2222-2222-2222-222222222222';

        await _establishSupabaseFarmerSession(cleanPhone, farmerId);

        _currentUserId = farmerId;
        _currentPhone = cleanPhone.isEmpty ? '9876543210' : cleanPhone;
        _currentRole = UserRole.farmer;
        _currentOfficerId = null;
        _currentCentreId = null;
        return AuthResult(
          isSuccess: true,
          userId: farmerId,
          phone: _currentPhone,
        );
      }

      // Verify OTP via Supabase Auth
      final formattedPhone =
          cleanPhone.startsWith('91') ? '+$cleanPhone' : '+91$cleanPhone';
      final authResponse = await supabase.client!.auth.verifyOTP(
        phone: formattedPhone,
        token: otp,
        type: OtpType.sms,
      );

      final user = authResponse.user;
      if (user != null) {
        _currentUserId = user.id;
        _currentPhone = user.phone ?? cleanPhone;
        _currentRole = UserRole.farmer;
        _currentOfficerId = null;
        _currentCentreId = null;

        // Ensure farmer profile exists in public.farmers table
        await RepositoryProvider.farmer.createOrUpdateProfile(
          id: user.id,
          phone: _currentPhone!,
          name: 'Ramesh Kumar',
          preferredLanguage: preferredLanguage,
        );

        return AuthResult(
          isSuccess: true,
          userId: user.id,
          phone: _currentPhone,
        );
      }
      return const AuthResult(
        isSuccess: false,
        errorMessage: 'Invalid OTP entered. Please try again.',
      );
    } catch (e) {
      debugPrint('AuthService.verifyFarmerOtp error: $e');
      // Graceful demo fallback for testing environments
      if (otp == '123456') {
        _currentUserId = '22222222-2222-2222-2222-222222222222';
        _currentPhone = cleanPhone.isEmpty ? '9876543210' : cleanPhone;
        _currentRole = UserRole.farmer;
        _currentOfficerId = null;
        _currentCentreId = null;
        return AuthResult(
          isSuccess: true,
          userId: _currentUserId,
          phone: _currentPhone,
        );
      }
      return AuthResult(
        isSuccess: false,
        errorMessage:
            'Authentication error: ${e.toString().split('\n').first}',
      );
    }
  }

  /// Verifies procurement officer credentials.
  Future<AuthResult> loginOfficer({
    required String officerId,
    required String password,
  }) async {
    final cleanOfficerId = officerId.trim().toUpperCase();

    // Local mode verification
    if (!SupabaseConfig.shouldUseSupabase) {
      if (cleanOfficerId == 'OFFICER001' && password == '123456') {
        _currentOfficerId = cleanOfficerId;
        _currentCentreId = '11111111-1111-1111-1111-111111111111';
        _currentRole = UserRole.officer;
        _currentUserId = null;
        _currentPhone = null;
        return AuthResult(
          isSuccess: true,
          officerId: _currentOfficerId,
          centreId: _currentCentreId,
        );
      } else {
        return const AuthResult(
          isSuccess: false,
          errorMessage:
              'Invalid Officer ID or Password (Demo: OFFICER001 / 123456).',
        );
      }
    }

    // Supabase mode verification
    final supabase = SupabaseService.instance;
    if (!supabase.isReady) {
      if (cleanOfficerId == 'OFFICER001' && password == '123456') {
        _currentOfficerId = cleanOfficerId;
        _currentCentreId = '11111111-1111-1111-1111-111111111111';
        _currentRole = UserRole.officer;
        _currentUserId = null;
        _currentPhone = null;
        return AuthResult(
          isSuccess: true,
          officerId: _currentOfficerId,
          centreId: _currentCentreId,
        );
      }
      return const AuthResult(
        isSuccess: false,
        errorMessage: 'Authentication service unavailable.',
      );
    }

    try {
      if (cleanOfficerId == 'OFFICER001' && password == '123456') {
        await _establishSupabaseOfficerSession(
            cleanOfficerId, '11111111-1111-1111-1111-111111111111');
        _currentOfficerId = cleanOfficerId;
        _currentCentreId = '11111111-1111-1111-1111-111111111111';
        _currentRole = UserRole.officer;
        _currentUserId = null;
        _currentPhone = null;
        return AuthResult(
          isSuccess: true,
          officerId: _currentOfficerId,
          centreId: _currentCentreId,
        );
      }

      // Check officer profiles in Supabase
      final email = '$cleanOfficerId@kisansetu.gov.in'.toLowerCase();
      final authResponse = await supabase.client!.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user != null) {
        final profile = await supabase.client!
            .from('officer_profiles')
            .select()
            .eq('officer_id', user.id)
            .maybeSingle();

        final centreId = profile?['centre_id']?.toString() ??
            '11111111-1111-1111-1111-111111111111';

        _currentOfficerId = cleanOfficerId;
        _currentCentreId = centreId;
        _currentRole = UserRole.officer;
        _currentUserId = null;
        _currentPhone = null;
        return AuthResult(
          isSuccess: true,
          officerId: _currentOfficerId,
          centreId: centreId,
        );
      }
      return const AuthResult(
        isSuccess: false,
        errorMessage: 'Invalid officer credentials.',
      );
    } catch (e) {
      debugPrint('AuthService.loginOfficer error: $e');
      if (cleanOfficerId == 'OFFICER001' && password == '123456') {
        _currentOfficerId = cleanOfficerId;
        _currentCentreId = '11111111-1111-1111-1111-111111111111';
        _currentRole = UserRole.officer;
        _currentUserId = null;
        _currentPhone = null;
        return AuthResult(
          isSuccess: true,
          officerId: _currentOfficerId,
          centreId: _currentCentreId,
        );
      }
      return AuthResult(
        isSuccess: false,
        errorMessage:
            'Authentication error: ${e.toString().split('\n').first}',
      );
    }
  }

  /// Clears active session and signs out of Supabase if running in cloud mode.
  Future<void> logout() async {
    _currentUserId = null;
    _currentPhone = null;
    _currentOfficerId = null;
    _currentCentreId = null;
    _currentRole = null;
    if (SupabaseConfig.shouldUseSupabase && SupabaseService.instance.isReady) {
      try {
        await SupabaseService.instance.client!.auth.signOut();
      } catch (e) {
        debugPrint('AuthService.logout error: $e');
      }
    }
  }
}
