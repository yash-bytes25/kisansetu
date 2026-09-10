import 'package:flutter/material.dart';
import '../models/farmer_dashboard_data.dart';
import '../models/procurement_centre.dart';
import '../models/procurement_slot.dart';
import '../services/smart_slot_service.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'farmer_booking_success_screen.dart';

/// Screen summarizing the chosen procurement slot before final confirmation.
class FarmerSlotConfirmationScreen extends StatelessWidget {
  final ProcurementCentre centre;
  final ProcurementSlot slot;
  final FarmerDashboardData currentData;
  final bool isHindi;
  final bool isTelugu;

  const FarmerSlotConfirmationScreen({
    super.key,
    required this.centre,
    required this.slot,
    required this.currentData,
    required this.isHindi,
    this.isTelugu = false,
  });

  void _showVoiceGuidance(BuildContext context) {
    final message = isTelugu
        ? 'వాయిస్ గైడ్: దయచేసి వివరాలను తనిఖీ చేయండి. కేంద్రం: ${centre.name}, స్లాట్: ${slot.time}. స్లాట్ నిర్ధారించడానికి క్రింది ఆకుపచ్చ బటన్‌ను నొక్కండి.'
        : (isHindi
            ? 'आवाज गाइड: कृपया विवरण जांचें। केंद्र: ${centre.name}, स्लॉट: ${slot.time}। स्लॉट पक्का करने के लिए नीचे हरा बटन दबाएं।'
            : 'Voice Guide: Please review your details. Centre: ${centre.name}, Slot: ${slot.time}. Tap Confirm Slot to book.');

    VoiceAssistantSpeechService.instance.speak(
      message,
      language: isTelugu
          ? 'te-IN'
          : (isHindi ? 'hi-IN' : 'en-IN'),
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        duration: const Duration(seconds: 5),
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

  void _onConfirmSlot(BuildContext context) async {
    // Generate sequential token deterministically (TK-8492 -> TK-8493)
    final generatedToken =
        SmartSlotService.generateNextToken(currentData.tokenNumber);

    final result = await Navigator.of(context).push<FarmerDashboardData?>(
      MaterialPageRoute<FarmerDashboardData?>(
        builder: (context) => FarmerBookingSuccessScreen(
          generatedToken: generatedToken,
          centre: centre,
          slot: slot,
          currentData: currentData,
          isHindi: isHindi,
          isTelugu: isTelugu,
        ),
      ),
    );

    if (result != null && context.mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Smart Slots',
          onPressed: () => Navigator.of(context).pop(),
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
            label: 'Listen to confirmation voice guidance',
            button: true,
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: TextButton.icon(
                onPressed: () => _showVoiceGuidance(context),
                icon: const Icon(
                  Icons.volume_up_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                label: Text(
                  isTelugu ? 'Listen / వినండి' : 'Listen / सुनें',
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isTelugu
                          ? 'మీ స్లాట్ నిర్ధారించండి'
                          : (isHindi ? 'स्लॉट की पुष्टि करें' : 'Confirm Your Slot'),
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTelugu
                          ? 'దయచేసి సేకరణ బుకింగ్ వివరాలను సరిచూసుకోండి.'
                          : (isHindi
                              ? 'कृपया खरीद स्लॉट विवरण की पुष्टि करें।'
                              : 'Please verify the procurement booking details.'),
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 20),

                    // Confirmation Summary Card
                    Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              icon: Icons.store_rounded,
                              label: isTelugu
                                  ? 'సేకరణ కేంద్రం'
                                  : (isHindi
                                      ? 'खरीद केंद्र'
                                      : 'Procurement Centre'),
                              value: centre.name,
                            ),
                            const Divider(height: 24),
                            _buildSummaryRow(
                              icon: Icons.grass_rounded,
                              label: isTelugu
                                  ? 'పంట'
                                  : (isHindi ? 'फसल' : 'Crop'),
                              value: isTelugu && currentData.crop == 'Wheat'
                                  ? 'గోధుమ'
                                  : currentData.cropName,
                            ),
                            const Divider(height: 24),
                            _buildSummaryRow(
                              icon: Icons.scale_rounded,
                              label: isTelugu
                                  ? 'పరిమాణం'
                                  : (isHindi ? 'मात्रा' : 'Quantity'),
                              value: isTelugu
                                  ? '${currentData.quantityQuintals} క్వింటాళ్లు'
                                  : currentData.quantity,
                            ),
                            const Divider(height: 24),
                            _buildSummaryRow(
                              icon: Icons.event_available_rounded,
                              label: isTelugu
                                  ? 'ఎంచుకున్న స్లాట్'
                                  : (isHindi ? 'चयनित स्लॉट' : 'Selected Slot'),
                              value: slot.time,
                              isHighlighted: true,
                            ),
                            const Divider(height: 24),
                            _buildSummaryRow(
                              icon: Icons.schedule_rounded,
                              label: isTelugu
                                  ? 'చేరుకోవాల్సిన సమయం'
                                  : (isHindi
                                      ? 'अपेक्षित आगमन'
                                      : 'Expected Arrival'),
                              value: slot.recommendedArrival,
                            ),
                            const Divider(height: 24),
                            _buildSummaryRow(
                              icon: Icons.timer_outlined,
                              label: isTelugu
                                  ? 'వేచి ఉండే సమయం'
                                  : (isHindi
                                      ? 'अपेक्षित प्रतीक्षा'
                                      : 'Expected Wait'),
                              value: slot.expectedWait,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Info Callout
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.primaryGreen,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isTelugu
                                  ? 'నిర్ధారించిన వెంటనే మీ డిజిటల్ టోకెన్ జారీ చేయబడుతుంది.'
                                  : (isHindi
                                      ? 'पुष्टि के तुरंत बाद आपका डिजिटल टोकन जारी किया जाएगा।'
                                      : 'Your digital procurement token will be generated immediately upon confirmation.'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Confirm Button (56dp height)
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: () => _onConfirmSlot(context),
                icon: const Icon(Icons.check_rounded, size: 22),
                label: Text(
                  isTelugu
                      ? 'స్లాట్ నిర్ధారించండి'
                      : (isHindi ? 'स्लॉट पक्का करें' : 'Confirm Slot'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlighted ? 17 : 15,
            fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w700,
            color: isHighlighted ? AppColors.primaryGreen : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
