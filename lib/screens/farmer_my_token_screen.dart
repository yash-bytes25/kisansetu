import 'package:flutter/material.dart';
import '../models/farmer_dashboard_data.dart';
import '../services/procurement_state_service.dart';
import '../services/queue_prediction_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/qr_validation_service.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../widgets/farmer/farmer_journey_tracker.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Screen presenting the farmer's active digital procurement token and live queue status.
///
/// Features a transparent queue progression visualization and prototype controls
/// to simulate dock intake updates and centre status changes.
class FarmerMyTokenScreen extends StatefulWidget {
  final FarmerDashboardData data;
  final bool isHindi;
  final bool isTelugu;

  const FarmerMyTokenScreen({
    super.key,
    required this.data,
    required this.isHindi,
    this.isTelugu = false,
  });

  @override
  State<FarmerMyTokenScreen> createState() => _FarmerMyTokenScreenState();
}

class _FarmerMyTokenScreenState extends State<FarmerMyTokenScreen> {
  bool get _isHindi => widget.isHindi;
  bool get _isTelugu => widget.isTelugu;

  late FarmerDashboardData _currentData;
  late String _currentStatus;

  final _stateService = ProcurementStateService();

  @override
  void initState() {
    super.initState();
    _currentData = _stateService.farmerData;
    _currentStatus = _currentData.centreStatus;
    _stateService.addListener(_onStateUpdated);
  }

  @override
  void dispose() {
    _stateService.removeListener(_onStateUpdated);
    super.dispose();
  }

  void _onStateUpdated() {
    if (mounted) {
      setState(() {
        _currentData = _stateService.farmerData;
        _currentStatus = _currentData.centreStatus;
      });
    }
  }

  void _showVoiceGuidance() {
    final pos = _currentData.currentPosition;
    final wait = _currentData.expectedWaitMinutes;
    final people = _currentData.peopleAhead;

    final guideText = _isTelugu
        ? 'వాయిస్ గైడ్: మీ టోకెన్ ${_currentData.tokenNumber}. క్యూలో మీ స్థానం $pos, $people మంది ముందున్నారు, మరియు అంచనా వేచి ఉండే సమయం $wait నిమిషాలు.'
        : (_isHindi
            ? 'आवाज गाइड: आपका टोकन ${_currentData.tokenNumber} है। कतार में आपका स्थान $pos है, $people लोग आगे हैं, और अनुमानित प्रतीक्षा $wait मिनट है।'
            : 'Voice Guide: Your token is ${_currentData.tokenNumber}. Current position is $pos with $people people ahead. Estimated wait is $wait minutes.');
    final langCode =
        _isTelugu ? 'te-IN' : (_isHindi ? 'hi-IN' : 'en-IN');
    VoiceAssistantSpeechService.instance
        .speak(guideText, language: langCode);

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
                guideText,
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

  /// Triggers the next queue progression step.
  void _simulateQueueUpdate() {
    _stateService.simulateNextQueueStep();
    final nextAhead = _stateService.farmerData.peopleAhead;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Text(
          _isTelugu
              ? 'క్యూ అప్‌డేట్: ఇప్పుడు $nextAhead మంది ముందున్నారు (ప్రతీక్ష: ${_currentData.expectedWaitMinutes} నిమిషాలు)'
              : (_isHindi
                  ? 'कतार अपडेट: अब $nextAhead लोग आगे हैं (प्रतीक्षा: ${_currentData.expectedWaitMinutes} मिनट)'
                  : 'Queue Updated: $nextAhead people ahead now (Wait: ${_currentData.expectedWaitMinutes} min)'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// Updates the centre operating status.
  void _onStatusChanged(String newStatus) {
    if (_currentStatus == newStatus) return;
    _stateService.setCentreStatus(newStatus);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_currentData);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back to Dashboard',
            onPressed: () => Navigator.of(context).pop(_currentData),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'KisanSetu',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actions: [
            Semantics(
              label: 'Listen to token guidance',
              button: true,
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: TextButton.icon(
                  onPressed: _showVoiceGuidance,
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                  label: Text(
                    _isTelugu ? 'Listen / వినండి' : 'Listen / सुनें',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Headings
                Text(
                  _isTelugu
                      ? 'నా టోకెన్'
                      : (_isHindi ? 'मेरा टोकन' : 'My Token'),
                  style: AppTextStyles.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _isTelugu
                      ? 'లైవ్ క్యూ స్థానం & డిజిటల్ పాస్'
                      : (_isHindi
                          ? 'लाइव कतार स्थिति एवं डिजिटल पास'
                          : 'Live queue position & digital procurement pass'),
                  style: AppTextStyles.bodyMedium,
                ),
                // Operational status banner when stopped or disrupted
                if (_currentData.recommendation ==
                        GoTimeRecommendation.centreTemporarilyStopped ||
                    _currentData.centreStatus.contains('Stopped')) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pause_circle_outline_rounded,
                            color: AppColors.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isTelugu
                                ? 'కేంద్రం తాత్కాలికంగా ఆపివేయబడింది (CENTRE TEMPORARILY STOPPED)'
                                : (_isHindi
                                    ? 'केंद्र अस्थायी रूप से बंद है (CENTRE TEMPORARILY STOPPED)'
                                    : 'CENTRE TEMPORARILY STOPPED'),
                            style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 1. Digital Pass Card
                _buildDigitalPassCard(),
                const SizedBox(height: 20),

                // Phase 12: Visual 8-Stage Farmer Journey Tracker
                FarmerJourneyTracker(
                  currentStatus: _currentData.lifecycleStatus,
                  checkInStatus: _currentData.checkInStatus,
                  paymentStatus: _currentData.paymentStatus,
                  isHindi: _isHindi,
                  isTelugu: _isTelugu,
                ),
                const SizedBox(height: 20),

                // 2. Live Queue Progression Visualization
                _buildQueueVisualCard(),
                const SizedBox(height: 20),

                // 3. Demo / Prototype Simulation Controls Card
                _buildSimulationControlsCard(),
                const SizedBox(height: 24),

                // 4. Back to Dashboard Action Button (>= 56dp)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(_currentData),
                    icon: const Icon(Icons.arrow_back_rounded, size: 22),
                    label: Text(
                      _isTelugu
                          ? 'డాష్‌బోర్డ్‌కు తిరిగి వెళ్లండి'
                          : (_isHindi
                              ? 'डैशबोर्ड पर वापस जाएं'
                              : 'Back to Dashboard'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(
                          color: AppColors.primaryGreen, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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

  Widget _buildDigitalPassCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGreen, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Pass Banner
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isTelugu
                          ? 'నా టోకెన్'
                          : (_isHindi ? 'मेरा टोकन' : 'MY TOKEN'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentData.tokenNumber,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isTelugu
                            ? 'యాక్టివ్ పాస్'
                            : (_isHindi ? 'सक्रिय पास' : 'ACTIVE PASS'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 16),

            // Centre & Slot details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isTelugu
                            ? 'సేకరణ కేంద్రం:'
                            : (_isHindi
                                ? 'खरीद केंद्र:'
                                : 'Procurement Centre:'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _currentData.centreName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isTelugu
                            ? 'ఈ రోజు స్లాట్:'
                            : (_isHindi ? 'आज का स्लॉट:' : "Today's Slot:"),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _currentData.bookedSlotTime ?? '11:30 AM',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 16),

            // 4 Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.pin_drop_rounded,
                    label: _isTelugu
                        ? 'ప్రస్తుత స్థానం'
                        : (_isHindi ? 'वर्तमान स्थिति' : 'Current Position'),
                    value: '${_currentData.currentPosition}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.people_alt_rounded,
                    label: _isTelugu
                        ? 'ముందున్నవారు'
                        : (_isHindi ? 'लोग आगे' : 'People Ahead'),
                    value: '${_currentData.peopleAhead}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.timer_outlined,
                    label: _isTelugu
                        ? 'అంచనా వేచి ఉండే సమయం'
                        : (_isHindi ? 'अनुमानित प्रतीक्षा' : 'Estimated Wait'),
                    value: '${_currentData.expectedWaitMinutes} min',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    icon: Icons.schedule_send_rounded,
                    label: _isTelugu
                        ? 'ఆశించిన వంతు'
                        : (_isHindi ? 'अपेक्षित बारी' : 'Expected Turn'),
                    value: _currentData.expectedTurnTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 16),

            // Phase 12: Digital QR Pass View
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.cardBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: QrValidationService.generateQrPayload(
                        bookingId:
                            'BK-${_currentData.tokenNumber.replaceAll('TK-', '')}',
                        tokenNumber: _currentData.tokenNumber,
                        centreName: _currentData.centreName,
                        slotTime: _currentData.bookedSlotTime ?? '11:30 AM',
                      ),
                      version: QrVersions.auto,
                      size: 160,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _currentData.checkInStatus == 'Checked In'
                          ? const Color(0xFFE8F5E9)
                          : const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _currentData.checkInStatus == 'Checked In'
                            ? AppColors.success
                            : const Color(0xFFF57F17),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentData.checkInStatus == 'Checked In'
                              ? Icons.verified_rounded
                              : Icons.qr_code_2_rounded,
                          size: 16,
                          color: _currentData.checkInStatus == 'Checked In'
                              ? AppColors.success
                              : const Color(0xFFF57F17),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _currentData.checkInStatus == 'Checked In'
                              ? (_isTelugu
                                  ? 'గేట్ వద్ద చెక్-ఇన్ చేయబడింది'
                                  : (_isHindi
                                      ? 'गेट पर चेक-इन हुआ'
                                      : 'Checked In'))
                              : (_isTelugu
                                  ? 'గేట్ వద్ద చెక్-ఇన్ కాలేదు'
                                  : (_isHindi
                                      ? 'चेक-इन नहीं हुआ'
                                      : 'Not Checked In')),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _currentData.checkInStatus == 'Checked In'
                                ? AppColors.success
                                : const Color(0xFFF57F17),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isTelugu
                        ? 'వేగవంతమైన గేట్ ఎంట్రీ కోసం కేంద్రం అధికారికి ఈ QR కోడ్‌ను చూపించండి.'
                        : (_isHindi
                            ? 'तेज़ गेट प्रवेश के लिए केंद्र अधिकारी को यह क्यूआर कोड दिखाएं।'
                            : 'Show this QR at the centre gate for fast check-in.'),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primaryGreen),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueVisualCard() {
    final ahead = _currentData.peopleAhead;
    final progress = (1.0 - (ahead / 10.0)).clamp(0.1, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.linear_scale_rounded,
                color: AppColors.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isTelugu
                    ? 'క్యూ పురోగతి ట్రాకర్'
                    : (_isHindi ? 'कतार प्रगति ट्रैकर' : 'Queue Progress Tracker'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                ahead == 0
                    ? (_isTelugu
                        ? 'ఇప్పుడు మీ వంతు!'
                        : (_isHindi ? 'अब आपकी बारी' : 'Your Turn!'))
                    : (_isTelugu
                        ? '$ahead మంది మిగిలి ఉన్నారు'
                        : (_isHindi
                            ? '$ahead लोग बाकी'
                            : '$ahead ahead')),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ahead == 0
                      ? AppColors.primaryGreen
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                ahead == 0 ? AppColors.primaryGreen : AppColors.primaryLight,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isTelugu ? 'గేట్ ప్రవేశం' : (_isHindi ? 'गेट प्रवेश' : 'Gate Entry'),
                style: AppTextStyles.caption,
              ),
              Text(
                _isTelugu ? 'శాంప్లింగ్' : (_isHindi ? 'सैंपलिंग' : 'Sampling'),
                style: AppTextStyles.caption,
              ),
              Text(
                _isTelugu ? 'తూకం / బరువు' : (_isHindi ? 'धर्मकांटा / वजन' : 'Weighment'),
                style: AppTextStyles.caption,
              ),
              Text(
                _isTelugu ? 'చెల్లింపు రసీదు' : (_isHindi ? 'भुगतान पास' : 'Payment Slip'),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationControlsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PROTOTYPE DEMO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isTelugu
                      ? 'లైవ్ క్యూ సిమ్యులేషన్'
                      : (_isHindi
                          ? 'लाइव कतार सिमुलेशन'
                          : 'Live Queue Simulation'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isTelugu
                ? 'సేకరణ కేంద్రంలో క్యూ పురోగతి (7 → 5 → 3 → 1 → 0) అనుకరించడానికి క్రింద నొక్కండి.'
                : (_isHindi
                    ? 'खरीद केंद्र पर कतार प्रगति (7 → 5 → 3 → 1 → 0) का अनुकरण करने के लिए नीचे टैप करें।'
                    : 'Tap to simulate live intake progress (7 → 5 → 3 → 1 → 0) at the procurement dock.'),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),

          // Primary Simulation Button (>= 56dp height)
          ElevatedButton.icon(
            onPressed: _simulateQueueUpdate,
            icon: const Icon(Icons.fast_forward_rounded, size: 22),
            label: Text(
              _isTelugu
                  ? 'క్యూ అప్‌డేట్‌ను అనుకరించండి'
                  : (_isHindi
                      ? 'कतार अपडेट अनुकरण करें'
                      : 'Simulate Queue Update'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Status switcher
          Text(
            _isTelugu
                ? 'కేంద్ర స్థితిని మార్చండి:'
                : (_isHindi ? 'केंद्र स्थिति बदलें:' : 'Simulate Centre Status:'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildStatusChip('Open • Normal'),
              _buildStatusChip('Open • Busy'),
              _buildStatusChip('Temporarily Delayed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final isSelected = _currentStatus == status;
    return ChoiceChip(
      label: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: status == 'Temporarily Delayed'
          ? AppColors.error
          : (status == 'Open • Busy' ? AppColors.warning : AppColors.primaryGreen),
      backgroundColor: AppColors.surface,
      onSelected: (_) => _onStatusChanged(status),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? Colors.transparent : AppColors.cardBorder,
        ),
      ),
    );
  }
}
