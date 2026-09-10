// KisanSetu (SIH26032) - Supabase Service
// Handles client initialization, lifecycle, and realtime channels.
// Keeps all backend initialization isolated from the UI layer.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Service managing Supabase client initialization, lifecycle, and Realtime streams.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient? _client;
  bool _isInitialized = false;
  String? _initError;

  // Realtime subscription trackers
  final List<StreamSubscription> _subscriptions = [];

  /// Exposes the initialized Supabase client, or null if uninitialized or in local mode.
  SupabaseClient? get client => _client;

  /// Whether Supabase was initialized successfully and is ready to accept requests.
  bool get isReady => _isInitialized && _client != null;

  /// Initialization error message if initialization was attempted and failed.
  String? get initError => _initError;

  /// Safely initializes Supabase if configured and not already initialized.
  /// Does NOT crash the application if credentials are not configured or network fails.
  Future<bool> initialize({
    String? urlOverride,
    String? anonKeyOverride,
    bool forceInit = false,
  }) async {
    if (_isInitialized && !forceInit) {
      return true;
    }

    final String url = urlOverride ?? SupabaseConfig.supabaseUrl;
    final String anonKey =
        anonKeyOverride ?? SupabaseConfig.supabasePublishableKey;

    // In local mode with placeholder credentials, skip client creation gracefully.
    final bool hasValidCredentials =
        (urlOverride != null && anonKeyOverride != null) ||
            SupabaseConfig.isConfigured;

    if (!forceInit && !hasValidCredentials) {
      debugPrint(
        'KisanSetu: Supabase credentials not configured (placeholders active). '
        'Running in ${SupabaseConfig.backendMode.name.toUpperCase()} mode.',
      );
      return false;
    }

    try {
      debugPrint('KisanSetu: Initializing Supabase client at $url');
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        debug: kDebugMode,
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      _initError = null;
      debugPrint('KisanSetu: Supabase client initialized successfully.');
      return true;
    } catch (e, stack) {
      _initError = e.toString();
      _isInitialized = false;
      _client = null;
      debugPrint('KisanSetu: Supabase initialization failed gracefully: $e');
      debugPrint('$stack');
      return false;
    }
  }

  // =========================================================================
  // REALTIME FOUNDATION (PHASE 10 & 22)
  // Provides clean stream subscriptions for key procurement entities.
  // =========================================================================

  /// Stream updates for queue entries for a given booking or centre.
  Stream<List<Map<String, dynamic>>>? streamQueueEntries({
    String? bookingId,
    String? centreId,
  }) {
    if (!isReady) return null;
    var query = _client!.from('queue_entries').stream(primaryKey: ['id']);
    if (bookingId != null) {
      query = query.eq('booking_id', bookingId);
    }
    return query;
  }

  /// Stream updates for bookings for a specific farmer.
  Stream<List<Map<String, dynamic>>>? streamFarmerBookings(String farmerId) {
    if (!isReady) return null;
    return _client!
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('farmer_id', farmerId);
  }

  /// Stream updates for bookings assigned to a specific centre.
  Stream<List<Map<String, dynamic>>>? streamCentreBookings(String centreId) {
    if (!isReady) return null;
    return _client!
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('centre_id', centreId);
  }

  /// Stream procurement records for a specific booking.
  Stream<List<Map<String, dynamic>>>? streamProcurementRecord(String bookingId) {
    if (!isReady) return null;
    return _client!
        .from('procurement_records')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId);
  }

  /// Stream payment status for a specific booking.
  Stream<List<Map<String, dynamic>>>? streamPayment(String bookingId) {
    if (!isReady) return null;
    return _client!
        .from('payments')
        .stream(primaryKey: ['id'])
        .eq('booking_id', bookingId);
  }

  /// Stream notifications for a specific farmer.
  Stream<List<Map<String, dynamic>>>? streamNotifications(String farmerId) {
    if (!isReady) return null;
    return _client!
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('farmer_id', farmerId)
        .order('created_at', ascending: false);
  }

  /// Cancels all active realtime subscriptions.
  void cancelAllSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}
