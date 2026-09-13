import 'package:flutter/material.dart';
import '../models/farmer_dashboard_data.dart';
import '../services/app_preferences_service.dart';
import '../services/payment_calculation_service.dart';
import '../services/procurement_state_service.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'farmer_dispute_screen.dart';

/// Phase 8: KisanSetu Farmer Payment Tracking & Transparency Screen.
///
/// Designed with RECOGNIZE → TAP → UNDERSTAND philosophy:
/// - Plain-language transparency on produce valuation and deductions.
/// - Clear lifecycle status (Payment Pending -> Payment Processing -> Payment Completed).
/// - Displays DBT simulated transaction reference, timestamp, and amount.
/// - Includes "Report a Problem" grievance action.
class FarmerPaymentScreen extends StatefulWidget {
  final bool isHindi;
  final bool isTelugu;
  final FarmerDashboardData? paymentData;

  const FarmerPaymentScreen({
    super.key,
    this.isHindi = false,
    this.isTelugu = false,
    this.paymentData,
  });

  @override
  State<FarmerPaymentScreen> createState() => _FarmerPaymentScreenState();
}

class _FarmerPaymentScreenState extends State<FarmerPaymentScreen> {
  final _service = ProcurementStateService();
  final _prefs = AppPreferencesService.instance;

  bool get _isHindi => widget.isHindi || (!widget.isTelugu && _prefs.isHindi);
  bool get _isTelugu => widget.isTelugu || (!widget.isHindi && _prefs.isTelugu);

  FarmerDashboardData get _effectiveFarmer =>
      widget.paymentData ?? _service.farmerData;

  void _showVoiceGuidance() {
    final farmer = _effectiveFarmer;
    final isCompleted = farmer.paymentStatus == 'Completed' ||
        farmer.paymentStatus == 'Payment Completed';
    final guideText = _isTelugu
        ? 'చెల్లింపు సమాచారం: మీ నికర మొత్తం ${PaymentCalculationService.formatCurrency(farmer.netPayable)}. స్థితి: ${isCompleted ? "ఖాతాలో జమ చేయబడింది" : "చెల్లింపు ప్రక్రియలో ఉంది"}.'
        : (_isHindi
            ? 'भुगतान जानकारी: आपकी शुद्ध देय राशि ${PaymentCalculationService.formatCurrency(farmer.netPayable)} है। स्थिति: ${isCompleted ? "खाते में जमा" : "प्रक्रिया में"}।'
            : 'Payment Information: Your net payable amount is ${PaymentCalculationService.formatCurrency(farmer.netPayable)}. Status: ${isCompleted ? "Deposited" : "In Process"}.');
    final langCode = _isTelugu ? 'te-IN' : (_isHindi ? 'hi-IN' : 'en-IN');
    VoiceAssistantSpeechService.instance.speak(guideText, language: langCode);

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

  void _openDisputeScreen() {
    final farmer = _effectiveFarmer;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => FarmerDisputeScreen(
          tokenNumber: farmer.tokenNumber,
          isHindi: _isHindi,
          isTelugu: _isTelugu,
          initialReason: 'Payment amount is incorrect',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final farmer = _effectiveFarmer;
        final isCompleted = farmer.paymentStatus == 'Completed' ||
            farmer.paymentStatus == 'Payment Completed';
        final isProcessing = farmer.paymentStatus == 'Processing' ||
            farmer.paymentStatus == 'Payment Initiated';

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
                      ? 'చెల్లింపు ట్రాకర్'
                      : (_isHindi ? 'भुगतान ट्रैकर' : 'Payment Tracker'),
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
                  // Main Status & Amount Card
                  _buildPaymentStatusCard(farmer, isCompleted, isProcessing),
                  const SizedBox(height: 20),

                  // Payment Transparency Breakdown
                  _buildTransparencyCard(farmer),
                  const SizedBox(height: 20),

                  // Banking / Transaction Details Card
                  _buildTransactionDetailsCard(farmer, isCompleted),
                  const SizedBox(height: 22),

                  // Download Invoice / Receipt Action Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isTelugu
                                  ? 'రసీదు విజయవంతంగా డౌన్‌లోడ్ చేయబడింది (${farmer.paymentReference})'
                                  : (_isHindi
                                      ? 'रसीद सफलतापूर्वक डाउनलोड की गई (${farmer.paymentReference})'
                                      : 'Receipt downloaded successfully (${farmer.paymentReference})'),
                            ),
                            backgroundColor: AppColors.primaryGreen,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                      icon: const Icon(Icons.download_rounded, size: 20),
                      label: Text(
                        _isTelugu
                            ? 'రసీదు డౌన్‌లోడ్ చేయండి'
                            : (_isHindi
                                ? 'रसीद / इनवॉयस डाउनलोड करें'
                                : 'Download Invoice / Receipt'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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
                  const SizedBox(height: 12),

                  // Dispute Action Button
                  SizedBox(
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: _openDisputeScreen,
                      icon: const Icon(Icons.help_outline_rounded, size: 20),
                      label: Text(
                        _isTelugu
                            ? 'సమస్యను నివేదించండి'
                            : (_isHindi
                                ? 'समस्या की रिपोर्ट करें'
                                : 'Report a Problem'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        side: const BorderSide(
                            color: AppColors.secondary, width: 1.5),
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
        );
      },
    );
  }

  Widget _buildPaymentStatusCard(
      FarmerDashboardData farmer, bool isCompleted, bool isProcessing) {
    Color bg = AppColors.surface;
    Color borderColor = AppColors.cardBorder;
    Color badgeColor = AppColors.warning;
    IconData statusIcon = Icons.hourglass_top_rounded;
    String statusTitle = _isTelugu
        ? 'చెల్లింపు పెండింగ్‌లో ఉంది'
        : (_isHindi ? 'भुगतान लंबित' : 'Payment Pending');

    if (isCompleted) {
      bg = AppColors.primaryContainer.withValues(alpha: 0.3);
      borderColor = AppColors.primaryGreen;
      badgeColor = AppColors.primaryGreen;
      statusIcon = Icons.verified_rounded;
      statusTitle = _isTelugu
          ? 'చెల్లింపు పూర్తయింది'
          : (_isHindi ? 'भुगतान पूर्ण हो गया' : 'Payment Completed');
    } else if (isProcessing) {
      borderColor = AppColors.secondary;
      badgeColor = AppColors.secondary;
      statusIcon = Icons.sync_rounded;
      statusTitle = _isTelugu
          ? 'చెల్లింపు ప్రక్రియలో ఉంది'
          : (_isHindi ? 'भुगतान प्रक्रियाधीन' : 'Payment Processing');
    }

    final formattedAmt =
        PaymentCalculationService.formatCurrency(farmer.netPayable);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor, width: 1.2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 18, color: badgeColor),
                const SizedBox(width: 8),
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(
            _isTelugu
                ? 'మొత్తం చెల్లించవలసిన మొత్తం'
                : (_isHindi ? 'कुल देय राशि' : 'Net Payable Amount'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formattedAmt,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isTelugu
                ? 'ఆమోదించబడింది: ${farmer.actualQuantity} • గ్రేడ్: ${farmer.qualityGrade}'
                : (_isHindi
                    ? 'स्वीकृत मात्रा: ${farmer.actualQuantity} • ग्रेड: ${farmer.qualityGrade}'
                    : 'Accepted: ${farmer.actualQuantity} • Grade: ${farmer.qualityGrade}'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransparencyCard(FarmerDashboardData farmer) {
    final grossStr =
        PaymentCalculationService.formatCurrency(farmer.grossAmount);
    final netStr =
        PaymentCalculationService.formatCurrency(farmer.netPayable);
    final mspRate = PaymentCalculationService.getMspRate(farmer.cropName);
    final formattedRate =
        PaymentCalculationService.formatCurrency(mspRate);
    final mspFormatted = _isTelugu
        ? '$formattedRate / క్వింటాల్'
        : '$formattedRate / Quintal';

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
              const Icon(Icons.receipt_long_rounded,
                  color: AppColors.primaryGreen, size: 22),
              const SizedBox(width: 8),
              Text(
                _isTelugu
                    ? 'స్పష్టమైన చెల్లింపు వివరాలు'
                    : (_isHindi
                        ? 'पारदर्शी भुगतान विवरण'
                        : 'Payment Transparency'),
                style: AppTextStyles.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _isTelugu
                ? 'ప్రభుత్వ మార్గదర్శకాల ప్రకారం పూర్తి వివరాలు (CCEA బెంచ్‌మార్క్ ధరలు).'
                : (_isHindi
                    ? 'सरकारी दिशानिर्देशों के अनुसार पूर्ण विवरण (CCEA बेंचमार्क दरें)।'
                    : 'Clear breakdown based on official CCEA benchmark rates.'),
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),

          _buildBreakdownRow(
            label: _isTelugu
                ? 'పంట విలువ (స్థూల)'
                : (_isHindi ? 'उपज मूल्य (ग्रॉस)' : 'Produce Value'),
            value: grossStr,
            isBold: false,
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow(
            label: _isTelugu
                ? 'తగ్గింపులు (డిడక్షన్స్)'
                : (_isHindi ? 'कटौतियां (डिडक्शन)' : 'Deductions'),
            value: '₹0',
            isBold: false,
            valueColor: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          _buildBreakdownRow(
            label: _isTelugu
                ? 'వర్తించే MSP ధర'
                : (_isHindi ? 'लागू एमएसपी दर' : 'Applicable MSP'),
            value: mspFormatted,
            isBold: false,
            valueColor: AppColors.secondary,
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 14),

          _buildBreakdownRow(
            label: _isTelugu
                ? 'నికర చెల్లించవలసిన మొత్తం'
                : (_isHindi ? 'शुद्ध देय राशि' : 'Net Payable'),
            value: netStr,
            isBold: true,
            valueColor: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetailsCard(
      FarmerDashboardData farmer, bool isCompleted) {
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
              const Icon(Icons.account_balance_rounded,
                  color: AppColors.secondary, size: 22),
              const SizedBox(width: 8),
              Text(
                _isTelugu
                    ? 'లావాదేవీ వివరాలు'
                    : (_isHindi
                        ? 'लेन-देन संदर्भ'
                        : 'Transaction Details'),
                style: AppTextStyles.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildDetailRow(
            label: _isTelugu
                ? 'చెల్లింపు స్థితి'
                : (_isHindi ? 'भुगतान स्थिति' : 'Payment Status'),
            value: farmer.paymentStatus,
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            label: _isTelugu
                ? 'చెల్లింపు రిఫరెన్స్'
                : (_isHindi ? 'भुगतान संदर्भ' : 'Payment Reference'),
            value: farmer.paymentReference,
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            label: _isTelugu
                ? 'చెల్లింపు తేదీ'
                : (_isHindi ? 'भुगतान तिथि' : 'Payment Date'),
            value: farmer.paymentDate,
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            label: _isTelugu
                ? 'చెల్లింపు విధానం'
                : (_isHindi ? 'भुगतान माध्यम' : 'Payment Mode'),
            value: 'Direct Benefit Transfer (DBT - Demo)',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _isTelugu
                        ? 'ప్రోటోటైప్ రిఫరెన్స్ సంఖ్య సురక్షిత సిమ్యులేషన్ కోసం మాత్రమే.'
                        : (_isHindi
                            ? 'प्रोटोटाइप संदर्भ संख्या सुरक्षित सिमुलेशन हेतु है।'
                            : 'Simulated demo reference for SIH26032 prototype evaluation.'),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow({
    required String label,
    required String value,
    required bool isBold,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 17 : 14,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              fontSize: 13,
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
