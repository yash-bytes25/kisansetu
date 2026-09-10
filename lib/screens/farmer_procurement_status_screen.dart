import 'package:flutter/material.dart';
import '../models/farmer_dashboard_data.dart';
import '../services/app_preferences_service.dart';
import '../services/payment_calculation_service.dart';
import '../services/procurement_state_service.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'farmer_crop_selection_screen.dart';
import 'farmer_dispute_screen.dart';
import 'farmer_payment_screen.dart';
import '../widgets/farmer/farmer_journey_tracker.dart';

/// Phase 8: KisanSetu Farmer Procurement Status Screen.
///
/// Designed with RECOGNIZE → TAP → UNDERSTAND philosophy:
/// - Provides complete transparency on produce intake and verification.
/// - 7-Stage sequential progress tracker (Booked -> Arrived -> Quality Check -> Weighment -> Accepted -> Payment Pending -> Payment Completed).
/// - Non-color-only indicators (icons, badges, check marks, stage names).
/// - Weighment verification and discrepancy detection with report action.
/// - Direct bridge to transparent payment breakdown.
class FarmerProcurementStatusScreen extends StatefulWidget {
  final bool isHindi;
  final bool isTelugu;

  const FarmerProcurementStatusScreen({
    super.key,
    this.isHindi = false,
    this.isTelugu = false,
  });

  @override
  State<FarmerProcurementStatusScreen> createState() =>
      _FarmerProcurementStatusScreenState();
}

class _FarmerProcurementStatusScreenState
    extends State<FarmerProcurementStatusScreen> {
  final _service = ProcurementStateService();
  final _prefs = AppPreferencesService.instance;

  bool get _isHindi  => _prefs.isHindi;
  bool get _isTelugu => _prefs.isTelugu;

  @override
  void initState() {
    super.initState();
    _service.addListener(_rebuild);
    _prefs.addListener(_rebuild);
  }

  @override
  void dispose() {
    _service.removeListener(_rebuild);
    _prefs.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() { if (mounted) setState(() {}); }

  static const List<Map<String, dynamic>> _lifecycleStages = [
    {
      'nameEn': 'Booked',
      'nameHi': 'बुक किया',
      'nameTe': 'బుక్ చేయబడింది',
      'icon': Icons.event_seat_rounded,
    },
    {
      'nameEn': 'Arrived',
      'nameHi': 'पहुंच गए',
      'nameTe': 'చేరుకున్నారు',
      'icon': Icons.how_to_reg_rounded,
    },
    {
      'nameEn': 'Quality Check',
      'nameHi': 'गुणवत्ता जांच',
      'nameTe': 'నాణ్యత తనిఖీ',
      'icon': Icons.science_rounded,
    },
    {
      'nameEn': 'Weighment',
      'nameHi': 'वजन माप',
      'nameTe': 'తూకం కొలత',
      'icon': Icons.scale_rounded,
    },
    {
      'nameEn': 'Accepted',
      'nameHi': 'स्वीकृत',
      'nameTe': 'ఆమోదించబడింది',
      'icon': Icons.task_alt_rounded,
    },
    {
      'nameEn': 'Payment Pending',
      'nameHi': 'भुगतान लंबित',
      'nameTe': 'చెల్లింపు పెండింగ్‌లో ఉంది',
      'icon': Icons.hourglass_top_rounded,
    },
    {
      'nameEn': 'Payment Completed',
      'nameHi': 'भुगतान पूर्ण',
      'nameTe': 'చెల్లింపు పూర్తయింది',
      'icon': Icons.verified_rounded,
    },
  ];

  int _getStageIndex(String status) {
    if (status == 'Booked') return 0;
    if (status == 'Arrived' || status == 'Waiting') return 1;
    if (status == 'Quality Check' || status == 'Sampling') return 2;
    if (status == 'Weighment') return 3;
    if (status == 'Accepted') return 4;
    if (status == 'Payment Pending') return 5;
    if (status == 'Completed' || status == 'Payment Completed') return 6;
    return 1;
  }

  void _showVoiceGuidance() {
    final farmer = _service.farmerData;
    final stageIdx = _getStageIndex(farmer.lifecycleStatus);
    final stageName = _isTelugu
        ? _lifecycleStages[stageIdx]['nameTe']
        : (_isHindi
            ? _lifecycleStages[stageIdx]['nameHi']
            : _lifecycleStages[stageIdx]['nameEn']);

    final guideText = _isTelugu
        ? 'పంట స్థితి: ${farmer.farmerName} గారూ, మీ పంట (${farmer.crop == 'Wheat' ? 'గోధుమ' : farmer.cropName}) ప్రస్తుతం "$stageName" దశలో ఉంది. వాస్తవ బరువు: ${farmer.actualQuantity}. చెల్లించవలసిన మొత్తం: ${PaymentCalculationService.formatCurrency(farmer.netPayable)}.'
        : (_isHindi
            ? 'उपज स्थिति: ${farmer.farmerName} जी, आपकी उपज (${farmer.cropName}) वर्तमान में "$stageName" चरण पर है। वजन: ${farmer.actualQuantity}। कुल मूल्य: ${PaymentCalculationService.formatCurrency(farmer.netPayable)}।'
            : 'Produce Status: ${farmer.farmerName}, your produce (${farmer.cropName}) is currently at the "$stageName" stage. Actual weight: ${farmer.actualQuantity}. Payable value: ${PaymentCalculationService.formatCurrency(farmer.netPayable)}.');
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
            const Icon(Icons.volume_up_rounded, color: Colors.white, size: 24),
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

  void _openPaymentScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FarmerPaymentScreen(
          isHindi: _isHindi,
          isTelugu: _isTelugu,
        ),
      ),
    );
  }

  void _openDisputeScreen() {
    final farmer = _service.farmerData;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FarmerDisputeScreen(
          tokenNumber: farmer.tokenNumber,
          isHindi: _isHindi,
          isTelugu: _isTelugu,
          initialReason: 'Quantity is incorrect',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final farmer = _service.farmerData;
        final currentStageIdx = _getStageIndex(farmer.lifecycleStatus);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: _isTelugu
                  ? 'వెనుకకు'
                  : (_isHindi ? 'वापस' : 'Back'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                const Text(
                  'KisanSetu • ',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen,
                  ),
                ),
                Text(
                  _isTelugu
                      ? 'సేకరణ స్థితి'
                      : (_isHindi ? 'उपज स्थिति' : 'Procurement Status'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            actions: [
              Semantics(
                label: _isTelugu
                    ? 'వాయిస్ వినండి'
                    : (_isHindi ? 'आवाज सुनें' : 'Listen to status'),
                button: true,
                child: TextButton.icon(
                  onPressed: _showVoiceGuidance,
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                  label: Text(
                    _isTelugu ? 'Listen / వినండి' : 'Listen / सुनें',
                    style: const TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Produce & Token Summary Card
                  _buildProduceSummaryCard(farmer),
                  const SizedBox(height: 20),

                  // 7-Stage Procurement Lifecycle Card
                  _buildLifecycleTrackerCard(farmer, currentStageIdx),
                  const SizedBox(height: 20),

                  // Weighment & Quality Verification Card
                  _buildWeighmentRecordCard(farmer),
                  const SizedBox(height: 20),

                  // Payment Shortcut Card
                  _buildPaymentShortcutCard(farmer),
                  const SizedBox(height: 16),

                  // Phase 12: 8-Stage Journey Tracker Modal Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(
                          color: AppColors.primaryGreen, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (ctx) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: SingleChildScrollView(
                              child: FarmerJourneyTracker(
                                currentStatus: farmer.lifecycleStatus,
                                checkInStatus: farmer.checkInStatus,
                                paymentStatus: farmer.paymentStatus,
                                isHindi: _isHindi,
                                isTelugu: _isTelugu,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.timeline_rounded),
                    label: Text(
                      _isTelugu
                          ? '8-దశల ప్రయాణం ట్రాకర్ చూడండి'
                          : (_isHindi
                              ? '8-चरणीय यात्रा ट्रैकर देखें'
                              : 'View 8-Stage Journey Tracker'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProduceSummaryCard(FarmerDashboardData farmer) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isTelugu
                        ? 'టోకెన్ నంబర్'
                        : (_isHindi ? 'टोकन संख्या' : 'TOKEN NUMBER'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    farmer.tokenNumber,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryGreen),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 16, color: AppColors.primaryGreen),
                    const SizedBox(width: 4),
                    Text(
                      farmer.lifecycleStatus,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 14),

          _buildRowInfo(
            icon: Icons.person_rounded,
            label: _isTelugu ? 'రైతు' : (_isHindi ? 'किसान' : 'Farmer'),
            value: _isTelugu ? 'రమేష్ కుమార్' : farmer.farmerName,
          ),
          const SizedBox(height: 10),
          _buildRowInfo(
            icon: Icons.grass_rounded,
            label: _isTelugu ? 'పంట' : (_isHindi ? 'फसल' : 'Crop'),
            value: _isTelugu && farmer.crop == 'Wheat'
                ? 'గోధుమ'
                : farmer.cropName,
          ),
          const SizedBox(height: 10),
          _buildRowInfo(
            icon: Icons.scale_rounded,
            label: _isTelugu
                ? 'రిజిస్టర్డ్ పరిమాణం'
                : (_isHindi ? 'पंजीकृत मात्रा' : 'Quantity'),
            value: _isTelugu
                ? '${farmer.quantityQuintals} క్వింటాళ్లు'
                : farmer.quantity,
          ),
          const SizedBox(height: 10),
          _buildRowInfo(
            icon: Icons.storefront_rounded,
            label: _isTelugu
                ? 'సేకరణ కేంద్రం'
                : (_isHindi ? 'प्रोक्योरमेंट केंद्र' : 'Centre'),
            value: farmer.centreName,
          ),
          const SizedBox(height: 10),
          _buildRowInfo(
            icon: Icons.access_time_rounded,
            label: _isTelugu
                ? 'బుక్ చేసిన స్లాట్'
                : (_isHindi ? 'बुक किया गया स्लॉट' : 'Booked Slot'),
            value: farmer.bookedSlotTime ?? '11:30 AM',
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const ValueKey('btn_procurement_change_crop'),
            onPressed: () async {
              final qtyStr = farmer.quantity.replaceAll(RegExp(r'[^0-9.]'), '');
              final currentQty = double.tryParse(qtyStr) ?? 50.0;
              await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (context) => FarmerCropSelectionScreen(
                    currentCropName: farmer.cropName,
                    currentQuantity: currentQty,
                    isHindi: _isHindi,
                    isTelugu: _isTelugu,
                  ),
                ),
              );
              if (mounted) {
                setState(() {});
              }
            },
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: Text(
              _isTelugu
                  ? 'పంటను మార్చండి'
                  : (_isHindi ? 'फसल बदलें' : 'Change Crop'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryGreen,
              side: const BorderSide(color: AppColors.primaryGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(double.infinity, 42),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleTrackerCard(
      FarmerDashboardData farmer, int currentStageIdx) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded,
                  color: AppColors.secondary, size: 22),
              const SizedBox(width: 8),
              Text(
                _isTelugu
                    ? 'సేకరణ పురోగతి'
                    : (_isHindi ? 'प्रोक्योरमेंट प्रगति' : 'Procurement Lifecycle'),
                style: AppTextStyles.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isTelugu
                ? 'మీ పంట ప్రస్తుత భౌతిక స్థితి మరియు తనిఖీ పురోగతి.'
                : (_isHindi
                    ? 'आपकी उपज की वर्तमान भौतिक स्थिति और जांच प्रगति।'
                    : 'What is happening to my produce right now?'),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),

          // 7 Stages
          Column(
            children: List.generate(_lifecycleStages.length, (i) {
              final stage = _lifecycleStages[i];
              final isPassed = currentStageIdx > i;
              final isCurrent = currentStageIdx == i;
              final isFuture = currentStageIdx < i;

              final name = _isTelugu
                  ? stage['nameTe']
                  : (_isHindi ? stage['nameHi'] : stage['nameEn']);
              final icon = stage['icon'] as IconData;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    // Indicator Icon Box
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isPassed
                            ? AppColors.primaryContainer
                            : (isCurrent
                                ? AppColors.secondaryContainer
                                : AppColors.surfaceVariant),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isPassed
                              ? AppColors.primaryGreen
                              : (isCurrent
                                  ? AppColors.secondary
                                  : AppColors.cardBorder),
                          width: isCurrent ? 2.2 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: isPassed
                            ? const Icon(Icons.check_rounded,
                                size: 20, color: AppColors.primaryGreen)
                            : (isCurrent
                                ? Icon(icon,
                                    size: 18, color: AppColors.secondary)
                                : Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textTertiary,
                                    ),
                                  )),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Stage Name and State
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isCurrent
                                  ? FontWeight.w800
                                  : (isPassed
                                      ? FontWeight.w700
                                      : FontWeight.w500),
                              color: isFuture
                                  ? AppColors.textTertiary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (isCurrent)
                            Text(
                              _isTelugu
                                  ? 'ప్రస్తుతం కేంద్రంలో ఈ ప్రక్రియ జరుగుతోంది'
                                  : (_isHindi
                                      ? 'वर्तमान में इस चरण पर प्रक्रियाधीन'
                                      : 'Currently underway at centre'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Stage Status Badge
                    if (isPassed)
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 16, color: AppColors.primaryGreen),
                          SizedBox(width: 4),
                          Text(
                            'DONE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      )
                    else if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'IN PROGRESS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeighmentRecordCard(FarmerDashboardData farmer) {
    final expectedVal = 50.0;
    final actualVal = double.tryParse(
            farmer.actualQuantity.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        50.2;
    final diff = actualVal - expectedVal;
    final hasDiscrepancy = diff.abs() > 0.05;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasDiscrepancy ? AppColors.warning : AppColors.cardBorder,
          width: hasDiscrepancy ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.scale_rounded,
                      color: AppColors.primaryGreen, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    _isTelugu
                        ? 'తూకం & నాణ్యత రికార్డు'
                        : (_isHindi
                            ? 'वजन व गुणवत्ता विवरण'
                            : 'Weighment & Quality Record'),
                    style: AppTextStyles.titleMedium,
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _isTelugu
                      ? 'ధృవీకరించబడింది'
                      : (_isHindi ? 'सत्यापित' : 'Verified'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildRowInfo(
            icon: Icons.receipt_long_rounded,
            label: _isTelugu
                ? 'అంచనా పరిమాణం'
                : (_isHindi ? 'अपेक्षित मात्रा' : 'Expected Quantity'),
            value: _isTelugu ? '50.0 క్వింటాళ్లు' : '50.0 Quintals',
          ),
          const SizedBox(height: 10),
          _buildRowInfo(
            icon: Icons.monitor_weight_rounded,
            label: _isTelugu
                ? 'వాస్తవ బరువు'
                : (_isHindi ? 'वास्तविक वजन' : 'Actual Weighment'),
            value: farmer.actualQuantity,
          ),
          const SizedBox(height: 10),
          _buildRowInfo(
            icon: Icons.difference_rounded,
            label: _isTelugu
                ? 'వ్యత్యాసం'
                : (_isHindi ? 'अंतर' : 'Difference'),
            value: diff >= 0
                ? '+${diff.toStringAsFixed(1)} Quintals'
                : '${diff.toStringAsFixed(1)} Quintals',
          ),
          const SizedBox(height: 10),
          _buildRowInfo(
            icon: Icons.verified_outlined,
            label: _isTelugu
                ? 'నాణ్యత గ్రేడ్'
                : (_isHindi ? 'गुणवत्ता ग्रेड' : 'Quality Grade'),
            value: farmer.qualityGrade,
          ),

          // Discrepancy Alert Box if difference detected
          if (hasDiscrepancy) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isTelugu
                              ? 'దయచేసి ఆమోదించే ముందు ఈ పరిమాణాన్ని సమీక్షించండి.'
                              : (_isHindi
                                  ? 'कृपया स्वीकार करने से पहले इस मात्रा की समीक्षा करें।'
                                  : 'Please review this quantity before accepting.'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: _openDisputeScreen,
                      icon: const Icon(Icons.report_problem_outlined, size: 18),
                      label: Text(
                        _isTelugu
                            ? 'వ్యత్యాసాన్ని నివేదించండి'
                            : (_isHindi
                                ? 'विसंगति दर्ज करें'
                                : 'Report a Discrepancy'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: const BorderSide(color: AppColors.warning),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentShortcutCard(FarmerDashboardData farmer) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isTelugu
                    ? 'చెల్లింపు సారాంశం'
                    : (_isHindi ? 'भुगतान विवरण' : 'Payment Summary'),
                style: AppTextStyles.titleMedium,
              ),
              Text(
                farmer.paymentStatus,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _isTelugu
                ? 'మొత్తం చెల్లించవలసిన మొత్తం: ${PaymentCalculationService.formatCurrency(farmer.netPayable)}'
                : (_isHindi
                    ? 'कुल देय राशि: ${PaymentCalculationService.formatCurrency(farmer.netPayable)}'
                    : 'Net Payable Amount: ${PaymentCalculationService.formatCurrency(farmer.netPayable)}'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _openPaymentScreen,
              icon: const Icon(Icons.payments_rounded, size: 20),
              label: Text(
                _isTelugu
                    ? 'చెల్లింపు వివరాలు & స్థితిని చూడండి'
                    : (_isHindi
                        ? 'भुगतान विवरण व स्थिति देखें'
                        : 'View Payment Details & Status'),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
