import 'package:flutter/material.dart';
import '../models/farmer_dashboard_data.dart';
import '../services/app_preferences_service.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/notification_service.dart';
import '../services/offline_essential_info_service.dart';
import '../services/procurement_state_service.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/responsive_layout.dart';
import '../widgets/common/connectivity_banner.dart';
import '../widgets/farmer/farmer_action_grid.dart';
import '../widgets/farmer/go_time_card.dart';
import '../widgets/farmer/produce_summary_card.dart';
import '../widgets/farmer/token_card.dart';
import '../widgets/farmer/farmer_journey_tracker.dart';
import 'farmer_book_slot_screen.dart';
import 'farmer/farmer_voice_assistant_screen.dart';
import 'farmer_crop_selection_screen.dart';
import 'farmer_digital_pass_screen.dart';
import 'farmer_messages_screen.dart';
import 'farmer_my_token_screen.dart';
import 'farmer_payment_history_screen.dart';
import 'farmer_payment_screen.dart';
import 'farmer_procurement_status_screen.dart';
import 'farmer_profile_screen.dart';
import 'language_preferences_screen.dart';
import 'role_selection_screen.dart';

/// Phase 4, Phase 6 & Phase 7: KisanSetu Farmer Dashboard Screen.
///
/// Designed with RECOGNIZE → TAP → UNDERSTAND philosophy:
/// - Immediate answer to: "What do I need to do now?"
/// - Flagship "When Should I Go?" prediction card
/// - My Token card with dynamic queue progress
/// - Registered produce summary
/// - 2-column quick action grid
/// - 5-item bottom navigation
/// - Live synchronization with ProcurementStateService
class FarmerDashboardScreen extends StatefulWidget {
  final String phoneNumber;
  final String selectedLanguage;

  const FarmerDashboardScreen({
    super.key,
    required this.phoneNumber,
    required this.selectedLanguage,
  });

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  int _currentTabIndex = 0;
  late FarmerDashboardData _dashboardData;
  final _service = ProcurementStateService();
  final _notifService = NotificationService();

  /// Global language + voice preferences — single source of truth.
  final _prefs = AppPreferencesService.instance;

  @override
  void initState() {
    super.initState();
    // Seed the global prefs from the language selected at login so they start
    // in sync; only applied if the user hasn't already picked something else.
    final loginCode = AppPreferencesService.codeFromLegacy(widget.selectedLanguage);
    _prefs.setUiLanguage(loginCode);

    _dashboardData = _service.farmerData;
    _service.addListener(_onStateUpdated);
    _notifService.addListener(_onStateUpdated);
    _prefs.addListener(_onStateUpdated);
    AppConnectivityService.instance.addListener(_onConnectivityUpdated);
  }

  @override
  void didUpdateWidget(FarmerDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLanguage != widget.selectedLanguage) {
      final loginCode = AppPreferencesService.codeFromLegacy(widget.selectedLanguage);
      _prefs.setUiLanguage(loginCode);
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onStateUpdated);
    _notifService.removeListener(_onStateUpdated);
    _prefs.removeListener(_onStateUpdated);
    AppConnectivityService.instance.removeListener(_onConnectivityUpdated);
    super.dispose();
  }

  void _onConnectivityUpdated() {
    if (AppConnectivityService.instance.isOnline) {
      _service.syncOfflineCache();
    }
    if (mounted) setState(() {});
  }

  void _onStateUpdated() {
    if (mounted) setState(() { _dashboardData = _service.farmerData; });
  }

  FarmerDashboardData get _effectiveData {
    if (AppConnectivityService.instance.isOnline) {
      return _dashboardData;
    }
    final cached = OfflineEssentialInfoService.instance.getCachedInfo();
    if (cached != null) {
      return FarmerDashboardData(
        farmerName: cached.farmerName,
        cropName: cached.cropName,
        quantity: cached.quantity,
        centreName: cached.centreName,
        tokenNumber: cached.tokenNumber,
        peopleAhead: cached.lastKnownPeopleAhead,
        totalInQueue: cached.lastKnownTotalInQueue,
        travelTimeMinutes: 25,
        expectedWaitMinutes: cached.lastKnownEstimatedWaitMinutes,
        recommendedDepartureTime: cached.lastKnownRecommendedDepartureTime,
        expectedTurnTime: cached.lastKnownExpectedTurnTime,
        centreStatus: cached.lastKnownCentreStatus,
        paymentStatus: cached.paymentStatus,
        bookedSlotTime: cached.bookedSlotTime,
        lifecycleStatus: cached.lifecycleStatus,
        checkInStatus: cached.checkInStatus,
        netPayable: cached.netPayable,
        paymentReference: cached.paymentReference,
        paymentDate: cached.paymentDate,
        waitReason: cached.lastKnownWaitReason,
        waitRecommendedArrival: cached.lastKnownRecommendedDepartureTime,
      );
    }
    return _dashboardData;
  }

  void _openMessages() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FarmerMessagesScreen(
          isHindi: _isHindi,
          isTelugu: _isTelugu,
        ),
      ),
    );
  }

  void _openBookSlot() async {
    if (!AppConnectivityService.instance.isOnline) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: Colors.orange.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isTelugu
                      ? 'ఆఫ్‌లైన్ మోడ్ • బుకింగ్ నిరోధించబడింది'
                      : (_isHindi ? 'ऑफलाइन मोड • बुकिंग अवरुद्ध' : 'Offline Mode'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(_isTelugu
              ? 'ఆఫ్‌లైన్‌లో ఉన్నప్పుడు కొత్త బుకింగ్‌లను నిర్ధారించడం సాధ్యం కాదు. దయచేసి ఇంటర్నెట్‌కి కనెక్ట్ చేయండి.'
              : (_isHindi
                  ? 'ऑफलाइन होने पर नई बुकिंग की पुष्टि नहीं की जा सकती। कृपया इंटरनेट से जुड़ें।'
                  : 'New bookings cannot be confirmed while offline. Please connect to the internet to book a slot.')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_isTelugu ? 'సరే' : (_isHindi ? 'ठीक है' : 'OK')),
            ),
          ],
        ),
      );
      return;
    }
    final updatedData = await Navigator.of(context).push<FarmerDashboardData?>(
      MaterialPageRoute<FarmerDashboardData?>(
        builder: (context) => FarmerBookSlotScreen(
          currentData: _dashboardData,
          isHindi: _isHindi,
          isTelugu: _isTelugu,
        ),
      ),
    );

    if (updatedData != null && mounted) {
      _service.updateFarmerBooking(
        centreName: updatedData.centreName,
        bookedSlot: updatedData.bookedSlotTime ?? '11:30 AM',
        tokenNumber: updatedData.tokenNumber,
        crop: updatedData.cropName,
        quantity: updatedData.quantity,
      );
    }
    if (mounted) {
      setState(() {
        _dashboardData = _service.farmerData;
      });
    }
  }

  void _openMyToken() async {
    final updatedData = await Navigator.of(context).push<FarmerDashboardData?>(
      MaterialPageRoute<FarmerDashboardData?>(
        builder: (context) => FarmerMyTokenScreen(
          data: _dashboardData,
          isHindi: _isHindi,
          isTelugu: _isTelugu,
        ),
      ),
    );

    if (updatedData != null && mounted) {
      setState(() {
        _dashboardData = updatedData;
      });
    }
  }

  void _openProcurementStatus() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FarmerProcurementStatusScreen(
          isHindi: _isHindi,
          isTelugu: _isTelugu,
        ),
      ),
    );
  }

  void _openChangeCrop() async {
    final qtyStr = _dashboardData.quantity.replaceAll(RegExp(r'[^0-9.]'), '');
    final currentQty = double.tryParse(qtyStr) ?? 50.0;

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => FarmerCropSelectionScreen(
          currentCropName: _dashboardData.cropName,
          currentQuantity: currentQty,
          isHindi: _isHindi,
          isTelugu: _isTelugu,
          showProminentOnly: true,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _dashboardData = _service.farmerData;
      });
    }
  }

  void _openPayment() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FarmerPaymentScreen(
          isHindi: _isHindi,
          isTelugu: _isTelugu,
        ),
      ),
    );
  }

  void _openDigitalPass() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FarmerDigitalPassScreen(
          bookingData: _effectiveData,
          isHindi: _isHindi,
          isTelugu: _isTelugu,
          onBookSlot: _openBookSlot,
        ),
      ),
    );
  }

  void _openDownloadReceipt() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FarmerPaymentHistoryScreen(
          isHindi: _isHindi,
          isTelugu: _isTelugu,
        ),
      ),
    );
  }

  void _openProfile() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => FarmerProfileScreen(
          isHindi: _isHindi,
          isTelugu: _isTelugu,
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _dashboardData = _service.farmerData;
      });
    }
  }

  void _openVoiceAssistant() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FarmerVoiceAssistantScreen(
          isHindi: _isHindi,
          isTelugu: _isTelugu,
        ),
      ),
    );
  }

  bool get _isTelugu => _prefs.isTelugu;
  bool get _isHindi  => _prefs.isHindi;

  /// BCP-47 locale for the voice assistant.
  String get _activeLocale => _prefs.voiceLocale;

  /// Short label shown on the Listen button.
  String get _listenLabel {
    if (_isTelugu) return 'Listen / వినండి';
    return 'Listen / सुनें';
  }

  /// Language options shown in the inline picker dropdown.
  static const _languages = [
    _LangOption(code: 'en', label: 'English', nativeLabel: 'English', flag: '🇮🇳'),
    _LangOption(code: 'hi', label: 'Hindi',   nativeLabel: 'हिंदी',   flag: '🇮🇳'),
    _LangOption(code: 'te', label: 'Telugu',  nativeLabel: 'తెలుగు',  flag: '🇮🇳'),
  ];

  /// Writes the selected language to the global [AppPreferencesService].
  void _onLanguageSelected(String code) {
    _prefs.setUiLanguage(code);
  }

  void _showVoiceGuidance() {
    final isOffline = !AppConnectivityService.instance.isOnline;
    final message = isOffline
        ? OfflineEssentialInfoService.instance
            .getOfflineSpeechSummary(isHindi: _isHindi, isTelugu: _isTelugu)
        : (_isTelugu
            ? 'వాయిస్ సహాయకుడు: నమస్కారం ${_effectiveData.farmerName} గారూ, బయలుదేరవలసిన సమయం ${_effectiveData.recommendedDepartureTime}. మీ టోకెన్ ${_effectiveData.tokenNumber} మరియు క్యూలో ${_effectiveData.peopleAhead} మంది ముందున్నారు.'
            : (_isHindi
                ? 'आवाज सहायक: ${_effectiveData.farmerName} जी, निकलने का सही समय ${_effectiveData.recommendedDepartureTime} है। आपका टोकन ${_effectiveData.tokenNumber} है और कतार में ${_effectiveData.peopleAhead} लोग आगे हैं।'
                : 'Voice Assistant: Welcome ${_effectiveData.farmerName}. Good time to leave is ${_effectiveData.recommendedDepartureTime}. Your token is ${_effectiveData.tokenNumber} with ${_effectiveData.peopleAhead} people ahead.'));

    VoiceAssistantSpeechService.instance.speak(
      message,
      language: _activeLocale,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            const Icon(
              Icons.volume_up_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onBottomNavTapped(int index) {
    if (index == 0) {
      setState(() { _currentTabIndex = 0; });
      return;
    }
    if (index == 1) {
      setState(() { _currentTabIndex = 1; });
      _openPayment();
      if (mounted) setState(() { _currentTabIndex = 0; });
      return;
    }
    if (index == 2) {
      setState(() { _currentTabIndex = 2; });
      _openMessages();
      if (mounted) setState(() { _currentTabIndex = 0; });
      return;
    }
    if (index == 3) {
      // index == 3: More — open Language & Voice Preferences
      LanguagePreferencesScreen.show(context).then((_) {
        if (mounted) setState(() { _currentTabIndex = 0; });
      });
      return;
    }
    if (index == 4) {
      // index == 4: My Profile
      setState(() { _currentTabIndex = 4; });
      _openProfile();
      if (mounted) setState(() { _currentTabIndex = 0; });
      return;
    }

    setState(() { _currentTabIndex = index; });
  }

  Widget _buildNotificationPreview() {
    final notifications = _notifService.notifications;
    final latest = notifications.isNotEmpty ? notifications.first : null;
    final previewText = latest != null
        ? (_isTelugu
            ? (latest.messageTe.isNotEmpty
                ? (latest.messageTe.contains('\n')
                    ? latest.messageTe.split('\n').first
                    : latest.messageTe)
                : (latest.messageEn.contains('\n')
                    ? latest.messageEn.split('\n').first
                    : latest.messageEn))
            : (_isHindi
                ? (latest.messageHi.contains('\n')
                    ? latest.messageHi.split('\n').first
                    : latest.messageHi)
                : (latest.messageEn.contains('\n')
                    ? latest.messageEn.split('\n').first
                    : latest.messageEn)))
        : (_isTelugu
            ? 'అన్ని సేకరణ ప్రక్రియలు సాధారణంగా ఉన్నాయి'
            : (_isHindi
                ? 'सभी खरीद प्रक्रियाएं सामान्य हैं'
                : 'All procurement systems normal'));

    return Semantics(
      label: _isTelugu
          ? 'తాజా సందేశ అప్‌డేట్'
          : (_isHindi ? 'नवीनतम संदेश अपडेट' : 'Latest message update'),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _openMessages,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder, width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            _isTelugu
                                ? 'తాజా అప్‌డేట్'
                                : (_isHindi ? 'नवीनतम अपडेट' : 'Latest Update'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          const Spacer(),
                          if (_notifService.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.accentAmber,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isTelugu
                                    ? '${_notifService.unreadCount} కొత్తవి'
                                    : (_isHindi
                                        ? '${_notifService.unreadCount} नए'
                                        : '${_notifService.unreadCount} New'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        previewText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _openMessages,
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(0, 32),
                    backgroundColor:
                        AppColors.primaryContainer.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isTelugu
                        ? 'సందేశాలు చూడండి'
                        : (_isHindi ? 'संदेश देखें' : 'View Messages'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceAssistantBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        key: const Key('btn_voice_assistant'),
        onTap: _openVoiceAssistant,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isTelugu
                          ? '🎤 కిసాన్ సేతు వాయిస్ అసిస్టెంట్'
                          : (_isHindi
                              ? '🎤 किसानसेतु वॉइस असिस्टेंट'
                              : '🎤 Ask KisanSetu'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _isTelugu
                          ? 'స్లాట్ బుకింగ్, క్యూ, లేదా చెల్లింపు వివరాల కోసం మాట్లాడండి'
                          : (_isHindi
                              ? 'स्लॉट बुकिंग, कतार या भुगतान के लिए बोलें'
                              : 'Speak naturally to book slot, check queue or payment'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (context) => const RoleSelectionScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: AppColors.primaryGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'KisanSetu • ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            _isTelugu
                                ? 'రమేష్ కుమార్'
                                : (_isHindi
                                    ? 'रमेश कुमार'
                                    : _dashboardData.farmerName),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'SIH26032 • Team ODE TO CODE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // ── Listen button + Language picker ──────────────────────────
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Listen button
                  Semantics(
                    label: 'Listen to dashboard voice guidance',
                    button: true,
                    child: TextButton.icon(
                      onPressed: _showVoiceGuidance,
                      icon: const Icon(
                        Icons.volume_up_rounded,
                        color: AppColors.primaryGreen,
                        size: 18,
                      ),
                      label: Text(
                        _listenLabel,
                        style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.only(
                            left: 10, right: 6, top: 6, bottom: 6),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Divider
                  Container(
                    width: 1,
                    height: 20,
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                  ),

                  // Language picker dropdown
                  PopupMenuButton<String>(
                    tooltip: 'Change voice language',
                    padding: EdgeInsets.zero,
                    onSelected: _onLanguageSelected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    offset: const Offset(0, 44),
                    color: AppColors.surface,
                    itemBuilder: (ctx) => _languages.map((opt) {
                      final isActive = (_isTelugu && opt.code == 'te') ||
                          (_isHindi && opt.code == 'hi') ||
                          (!_isTelugu && !_isHindi && opt.code == 'en');
                      return PopupMenuItem<String>(
                        value: opt.code,
                        child: Row(
                          children: [
                            Text(opt.flag,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  opt.nativeLabel,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: isActive
                                        ? AppColors.primaryGreen
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  opt.label,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                            if (isActive) ...[  
                              const Spacer(),
                              const Icon(Icons.check_rounded,
                                  color: AppColors.primaryGreen, size: 18),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.language_rounded,
                            color: AppColors.primaryGreen,
                            size: 16,
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: AppColors.primaryGreen,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Logout icon button
            IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ConnectivityBanner(
              isHindi: _isHindi,
              isTelugu: _isTelugu,
              onRefresh: () {
                if (AppConnectivityService.instance.isOnline) {
                  _service.syncOfflineCache();
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isTelugu
                          ? 'తాజా డేటా నవీకరించబడింది'
                          : (_isHindi
                              ? 'ताजा डेटा अपडेट किया गया'
                              : 'Data refreshed with live server')),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_isTelugu
                          ? 'ఇంకా ఆఫ్‌లైన్‌లో ఉంది. కనెక్షన్ వచ్చినప్పుడు రిఫ్రెష్ అవుతుంది.'
                          : (_isHindi
                              ? 'अभी भी ऑफ़लाइन है। कनेक्शन आने पर रीफ़्रेश होगा।'
                              : 'Still offline. Data will refresh when connection returns.')),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop =
                      constraints.maxWidth >= ResponsiveLayout.desktopMin;
                  final isOnline = AppConnectivityService.instance.isOnline;
                  final data = _effectiveData;

                  if (isDesktop) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24.0, vertical: 14.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Column: Operations & Recommendations
                                  Expanded(
                                    flex: 6,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (!isOnline) ...[
                                          TokenCard(
                                            data: data,
                                            isHindi: _isHindi,
                                            isTelugu: _isTelugu,
                                            onViewToken: _openMyToken,
                                            isCompact: true,
                                          ),
                                          const SizedBox(height: 12),
                                        ],
                                        ProduceSummaryCard(
                                          data: data,
                                          isHindi: _isHindi,
                                          isTelugu: _isTelugu,
                                          onTap: _openProcurementStatus,
                                          onChangeCrop: _openChangeCrop,
                                          isCompact: true,
                                        ),
                                        const SizedBox(height: 12),
                                        GoTimeCard(
                                          data: data,
                                          isHindi: _isHindi,
                                          isTelugu: _isTelugu,
                                          isCompact: true,
                                        ),
                                        const SizedBox(height: 12),
                                        _buildNotificationPreview(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 18),

                                  // Right Column: My Token & Quick Actions
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        if (isOnline) ...[
                                          TokenCard(
                                            data: data,
                                            isHindi: _isHindi,
                                            isTelugu: _isTelugu,
                                            onViewToken: _openMyToken,
                                            isCompact: true,
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                        _buildVoiceAssistantBanner(),
                                        Text(
                                          _isTelugu
                                              ? 'త్వరిత చర్యలు'
                                              : (_isHindi
                                                  ? 'त्वरित कार्य'
                                                  : 'Quick Actions'),
                                          style: AppTextStyles.titleMedium,
                                        ),
                                        const SizedBox(height: 10),
                                        FarmerActionGrid(
                                          isHindi: _isHindi,
                                          isTelugu: _isTelugu,
                                          onBookSlot: _openBookSlot,
                                          onPayment: _openPayment,
                                          onDigitalPass: _openDigitalPass,
                                          onDownloadReceipt:
                                              _openDownloadReceipt,
                                          isCompact: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Full-width Procurement Journey Tracker
                              InkWell(
                                onTap: _openMyToken,
                                borderRadius: BorderRadius.circular(16),
                                child: FarmerJourneyTracker(
                                  currentStatus: data.lifecycleStatus,
                                  checkInStatus: data.checkInStatus,
                                  paymentStatus: data.paymentStatus,
                                  isHindi: _isHindi,
                                  isTelugu: _isTelugu,
                                  isCompact: false,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Mobile / Tablet (< 850px width)
                  // Offline prioritization:
                  // 1. Token / QR
                  // 2. Booking slot & Last known Go-Time
                  // 3. Centre details & Produce
                  // 4. Procurement status
                  // 5. Notifications
                  // 6. Quick Actions / Payment
                  if (!isOnline) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18.0, vertical: 14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Token / QR Card (High Priority Offline)
                          TokenCard(
                            data: data,
                            isHindi: _isHindi,
                            isTelugu: _isTelugu,
                            onViewToken: _openMyToken,
                          ),
                          const SizedBox(height: 16),

                          // 2. Booking slot & Last known Go-Time
                          GoTimeCard(
                            data: data,
                            isHindi: _isHindi,
                            isTelugu: _isTelugu,
                          ),
                          const SizedBox(height: 16),

                          // 3. Centre details & Produce Summary
                          ProduceSummaryCard(
                            data: data,
                            isHindi: _isHindi,
                            isTelugu: _isTelugu,
                            onTap: _openProcurementStatus,
                            onChangeCrop: _openChangeCrop,
                          ),
                          const SizedBox(height: 16),

                          // 4. Procurement status (Journey Tracker)
                          InkWell(
                            onTap: _openMyToken,
                            borderRadius: BorderRadius.circular(16),
                            child: FarmerJourneyTracker(
                              currentStatus: data.lifecycleStatus,
                              checkInStatus: data.checkInStatus,
                              paymentStatus: data.paymentStatus,
                              isHindi: _isHindi,
                              isTelugu: _isTelugu,
                              isCompact: true,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 5. Latest Notification Preview
                          _buildNotificationPreview(),
                          const SizedBox(height: 16),

                          // 6. Voice Assistant & Quick Actions
                          _buildVoiceAssistantBanner(),
                          Text(
                            _isTelugu
                                ? 'త్వరిత చర్యలు'
                                : (_isHindi ? 'त्वरित कार्य' : 'Quick Actions'),
                            style: AppTextStyles.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          FarmerActionGrid(
                            isHindi: _isHindi,
                            isTelugu: _isTelugu,
                            onBookSlot: _openBookSlot,
                            onPayment: _openPayment,
                            onDigitalPass: _openDigitalPass,
                            onDownloadReceipt: _openDownloadReceipt,
                            onMyToken: _openMyToken,
                            onMyProduce: _openProcurementStatus,
                            onMessages: _openMessages,
                            unreadMessagesCount: _notifService.unreadCount,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  }

                  // Mobile / Tablet: Online standard single-column flow
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18.0, vertical: 14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Produce Summary Card
                        ProduceSummaryCard(
                          data: data,
                          isHindi: _isHindi,
                          isTelugu: _isTelugu,
                          onTap: _openProcurementStatus,
                          onChangeCrop: _openChangeCrop,
                        ),
                        const SizedBox(height: 16),

                        // 2. FLAGSHIP: "When Should I Go?" Card
                        GoTimeCard(
                          data: data,
                          isHindi: _isHindi,
                          isTelugu: _isTelugu,
                        ),
                        const SizedBox(height: 14),

                        // 3. Compact Latest Notification Preview
                        _buildNotificationPreview(),
                        const SizedBox(height: 14),

                        // 4. My Token Card
                        TokenCard(
                          data: data,
                          isHindi: _isHindi,
                          isTelugu: _isTelugu,
                          onViewToken: _openMyToken,
                        ),
                        const SizedBox(height: 22),

                        // Voice Assistant
                        _buildVoiceAssistantBanner(),

                        // Section Heading for Quick Actions
                        Text(
                          _isTelugu
                              ? 'త్వరిత చర్యలు'
                              : (_isHindi ? 'त्वरित कार्य' : 'Quick Actions'),
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 12),

                        // 5. Quick Action 2-Column Grid
                        FarmerActionGrid(
                          isHindi: _isHindi,
                          isTelugu: _isTelugu,
                          onBookSlot: _openBookSlot,
                          onPayment: _openPayment,
                          onDigitalPass: _openDigitalPass,
                          onDownloadReceipt: _openDownloadReceipt,
                          onMyToken: _openMyToken,
                          onMyProduce: _openProcurementStatus,
                          onMessages: _openMessages,
                          unreadMessagesCount: _notifService.unreadCount,
                        ),
                        const SizedBox(height: 20),

                        // Phase 12: Visual 8-Stage Farmer Journey Tracker
                        InkWell(
                          onTap: _openMyToken,
                          borderRadius: BorderRadius.circular(16),
                          child: FarmerJourneyTracker(
                            currentStatus: data.lifecycleStatus,
                            checkInStatus: data.checkInStatus,
                            paymentStatus: data.paymentStatus,
                            isHindi: _isHindi,
                            isTelugu: _isTelugu,
                            isCompact: true,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // 5. Bottom Navigation Bar (Non-color-only indication)
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: _onBottomNavTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primaryGreen,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: AppColors.primaryGreen,
                ),
              ),
              label: _isTelugu ? 'హోమ్' : (_isHindi ? 'होम' : 'Home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.payments_outlined),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: AppColors.primaryGreen,
                ),
              ),
              label: _isTelugu ? 'చెల్లింపు' : (_isHindi ? 'भुगतान' : 'Payment'),
            ),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined),
                  if (_notifService.unreadCount > 0)
                    Positioned(
                      right: -6,
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.accentAmber,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Text(
                          '${_notifService.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_rounded,
                      color: AppColors.primaryGreen,
                    ),
                    if (_notifService.unreadCount > 0)
                      Positioned(
                        right: -6,
                        top: -3,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.accentAmber,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '${_notifService.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              label: _isTelugu
                  ? (_notifService.unreadCount > 0
                      ? 'సందేశాలు [${_notifService.unreadCount}]'
                      : 'సందేశాలు')
                  : (_isHindi
                      ? (_notifService.unreadCount > 0
                          ? 'संदेश [${_notifService.unreadCount}]'
                          : 'संदेश')
                      : (_notifService.unreadCount > 0
                          ? 'Messages [${_notifService.unreadCount}]'
                          : 'Messages')),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.more_horiz_rounded),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.primaryGreen,
                ),
              ),
              label: _isTelugu ? 'మరిన్ని' : (_isHindi ? 'अधिक' : 'More'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline_rounded),
              activeIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.primaryGreen,
                ),
              ),
              label: _isTelugu
                  ? 'నా ప్రొఫైల్'
                  : (_isHindi ? 'मेरी प्रोफ़ाइल' : 'My Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Language option model ────────────────────────────────────────────────────

/// Immutable descriptor for a language entry in the voice-language picker.
class _LangOption {
  final String code;        // BCP-47 prefix: 'en', 'hi', 'te'
  final String label;       // English name shown as subtitle
  final String nativeLabel; // Native script label shown as title
  final String flag;        // Flag emoji

  const _LangOption({
    required this.code,
    required this.label,
    required this.nativeLabel,
    required this.flag,
  });
}
