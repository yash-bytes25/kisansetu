import '../models/farmer_dashboard_data.dart';
import '../models/notification_model.dart';
import '../models/offline_essential_info_model.dart';
import 'local_cache_store.dart';
import 'procurement_state_service.dart';
import 'qr_validation_service.dart';

/// Central service responsible for managing local offline caching and retrieval
/// of critical procurement information.
///
/// Ensures farmers can always see their digital QR pass, token number, centre location,
/// and last known queue/wait status without internet.
class OfflineEssentialInfoService {
  static final OfflineEssentialInfoService instance =
      OfflineEssentialInfoService();

  final LocalCacheStore _store;
  OfflineEssentialInfoModel? _memoryCache;

  OfflineEssentialInfoService({LocalCacheStore? cacheStore})
      : _store = cacheStore ?? LocalCacheStore.instance;

  static const String cacheKey = 'kisansetu_offline_essential_info_v1';

  /// Retrieves cached essential information.
  ///
  /// Gracefully handles missing, expired, or corrupted cache by returning null
  /// without crashing the application.
  OfflineEssentialInfoModel? getCachedInfo() {
    if (_memoryCache != null) {
      return _memoryCache;
    }

    final raw = _store.getString(cacheKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final model = OfflineEssentialInfoModel.tryFromJsonString(raw);
      _memoryCache = model;
      return model;
    } catch (_) {
      // Corrupted cache recovery: clear invalid data
      clearCache();
      return null;
    }
  }

  /// Whether valid cached data exists.
  bool get hasCachedData => getCachedInfo() != null;

  /// Test alias for hasCachedData.
  bool get hasCachedInfo => hasCachedData;

  /// The timestamp when essential info was last saved.
  DateTime? get lastUpdatedTimestamp => getCachedInfo()?.lastUpdatedTimestamp;

  /// Human-readable time: e.g. "10:42 AM"
  String get lastUpdatedFormatted =>
      getCachedInfo()?.lastUpdatedFormatted ?? 'Just now';

  /// Caches the current live state into the local storage layer.
  Future<void> cacheState({
    required FarmerDashboardData farmerData,
    required String centreName,
    List<NotificationModel> notifications = const [],
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();

    final qr = QrValidationService.generateQrPayload(
      bookingId: 'BK-${farmerData.tokenNumber.replaceAll('TK-', '')}',
      tokenNumber: farmerData.tokenNumber,
      centreName: centreName,
      slotTime: farmerData.bookedSlotTime ?? '11:30 AM',
    );

    final notifTexts = notifications
        .take(5)
        .map((n) => n.messageEn.isNotEmpty ? n.messageEn : n.titleEn)
        .toList();

    final model = OfflineEssentialInfoModel(
      farmerName: farmerData.farmerName,
      farmerPhone: '9876543210',
      cropName: farmerData.cropName,
      quantity: farmerData.quantity,
      centreName: centreName,
      tokenNumber: farmerData.tokenNumber,
      bookingId: 'BK-${farmerData.tokenNumber.replaceAll('TK-', '')}',
      bookingDate: '09 Sep 2026',
      bookedSlotTime: farmerData.bookedSlotTime ?? '11:30 AM',
      qrPayload: qr,
      lastKnownPeopleAhead: farmerData.peopleAhead,
      lastKnownTotalInQueue: farmerData.totalInQueue,
      lastKnownEstimatedWaitMinutes: farmerData.expectedWaitMinutes,
      lastKnownCentreStatus: farmerData.centreStatus,
      lastKnownGoTimeRecommendation: farmerData.recommendation.name,
      lastKnownRecommendedDepartureTime: farmerData.recommendedDepartureTime,
      lastKnownExpectedTurnTime: farmerData.expectedTurnTime,
      lastKnownWaitReason: farmerData.waitReason,
      lifecycleStatus: farmerData.lifecycleStatus,
      checkInStatus: farmerData.checkInStatus,
      paymentStatus: farmerData.paymentStatus,
      netPayable: farmerData.netPayable,
      paymentReference: farmerData.paymentReference,
      paymentDate: farmerData.paymentDate,
      importantNotifications: notifTexts,
      lastUpdatedTimestamp: now,
    );

    _memoryCache = model;
    await _store.saveString(cacheKey, model.toJsonString());
  }

  /// Synchronous caching for instant updates.
  void cacheStateSync({
    required FarmerDashboardData farmerData,
    required String centreName,
    List<NotificationModel> notifications = const [],
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();

    final qr = QrValidationService.generateQrPayload(
      bookingId: 'BK-${farmerData.tokenNumber.replaceAll('TK-', '')}',
      tokenNumber: farmerData.tokenNumber,
      centreName: centreName,
      slotTime: farmerData.bookedSlotTime ?? '11:30 AM',
    );

    final notifTexts = notifications
        .take(5)
        .map((n) => n.messageEn.isNotEmpty ? n.messageEn : n.titleEn)
        .toList();

    final model = OfflineEssentialInfoModel(
      farmerName: farmerData.farmerName,
      farmerPhone: '9876543210',
      cropName: farmerData.cropName,
      quantity: farmerData.quantity,
      centreName: centreName,
      tokenNumber: farmerData.tokenNumber,
      bookingId: 'BK-${farmerData.tokenNumber.replaceAll('TK-', '')}',
      bookingDate: '09 Sep 2026',
      bookedSlotTime: farmerData.bookedSlotTime ?? '11:30 AM',
      qrPayload: qr,
      lastKnownPeopleAhead: farmerData.peopleAhead,
      lastKnownTotalInQueue: farmerData.totalInQueue,
      lastKnownEstimatedWaitMinutes: farmerData.expectedWaitMinutes,
      lastKnownCentreStatus: farmerData.centreStatus,
      lastKnownGoTimeRecommendation: farmerData.recommendation.name,
      lastKnownRecommendedDepartureTime: farmerData.recommendedDepartureTime,
      lastKnownExpectedTurnTime: farmerData.expectedTurnTime,
      lastKnownWaitReason: farmerData.waitReason,
      lifecycleStatus: farmerData.lifecycleStatus,
      checkInStatus: farmerData.checkInStatus,
      paymentStatus: farmerData.paymentStatus,
      netPayable: farmerData.netPayable,
      paymentReference: farmerData.paymentReference,
      paymentDate: farmerData.paymentDate,
      importantNotifications: notifTexts,
      lastUpdatedTimestamp: now,
    );

    _memoryCache = model;
    _store.saveStringSync(cacheKey, model.toJsonString());
  }

  /// Refreshes local cache when connection returns.
  Future<void> refreshWhenOnline(ProcurementStateService state) async {
    await cacheState(
      farmerData: state.farmerData,
      centreName: state.centreName,
    );
  }

  /// Clears local cache.
  void clearCache() {
    _memoryCache = null;
    _store.reset();
  }

  /// Injects corrupt cache data for automated resilience testing.
  void injectCorruptedCacheForTesting(String badJson) {
    _memoryCache = null;
    _store.saveStringSync(cacheKey, badJson);
  }

  /// Generates trilingual speech summary from cached offline information.
  String getOfflineSpeechSummary({
    String? language,
    bool isHindi = false,
    bool isTelugu = false,
  }) {
    final cached = getCachedInfo();
    final useTelugu = isTelugu || language == 'te';
    final useHindi = isHindi || language == 'hi';

    if (cached == null) {
      if (useTelugu) return 'ఆఫ్‌లైన్ సమాచారం అందుబాటులో లేదు. దయచేసి ఇంటర్నెట్‌కి కనెక్ట్ చేయండి.';
      if (useHindi) return 'ऑफलाइन जानकारी उपलब्ध नहीं है। कृपया इंटरनेट से जुड़ें।';
      return 'No offline information available. Please connect to the internet.';
    }
    return cached.toSpeechSummary(
      language: language,
      isHindi: useHindi,
      isTelugu: useTelugu,
    );
  }
}
