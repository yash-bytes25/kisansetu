import 'package:flutter/material.dart';
import '../models/farmer_dashboard_data.dart';
import '../models/procurement_centre.dart';
import '../models/procurement_slot.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/qr_validation_service.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../widgets/farmer/farmer_journey_tracker.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Screen displayed after a procurement slot is successfully confirmed.
class FarmerBookingSuccessScreen extends StatelessWidget {
  final String generatedToken;
  final ProcurementCentre centre;
  final ProcurementSlot slot;
  final FarmerDashboardData currentData;
  final bool isHindi;
  final bool isTelugu;

  const FarmerBookingSuccessScreen({
    super.key,
    required this.generatedToken,
    required this.centre,
    required this.slot,
    required this.currentData,
    required this.isHindi,
    this.isTelugu = false,
  });

  @override
  Widget build(BuildContext context) {
    // Construct the updated dashboard state
    final updatedData = currentData.copyWith(
      tokenNumber: generatedToken,
      centreName: centre.name,
      bookedSlotTime: slot.time,
      recommendedDepartureTime: '10:55 AM',
      expectedTurnTime: slot.time,
      expectedWaitMinutes: slot.expectedWaitMinutes,
      peopleAhead: 5,
      centreStatus: centre.status,
      isGoodTimeToLeave: true,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(updatedData);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 16,
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
              label: 'Listen to digital token details',
              button: true,
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: TextButton.icon(
                  onPressed: () {
                    final guideText = isTelugu
                        ? 'వాయిస్ గైడ్: మీ స్లాట్ విజయవంతంగా బుక్ చేయబడింది. మీ టోకెన్ $generatedToken. సిఫార్సు చేయబడిన రాక సమయం ${slot.recommendedArrival}.'
                        : (isHindi
                            ? 'आवाज गाइड: आपका स्लॉट सफलतापूर्वक बुक हो गया है। आपका टोकन $generatedToken है। अनुशंसित आगमन ${slot.recommendedArrival} है।'
                            : 'Voice Guide: Your slot is confirmed. Your token number is $generatedToken. Recommended arrival is ${slot.recommendedArrival}.');
                    final langCode =
                        isTelugu ? 'te-IN' : (isHindi ? 'hi-IN' : 'en-IN');
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
                  },
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Success Badge Icon
                Container(
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 52,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  isTelugu
                      ? 'మీ స్లాట్ నిర్ధారించబడింది'
                      : (isHindi
                          ? 'आपका स्लॉट पक्का हो गया है'
                          : 'Your slot is confirmed'),
                  style: AppTextStyles.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Digital Token Card with QR Code
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          isTelugu
                              ? 'డిజిటల్ టోకెన్'
                              : (isHindi ? 'डिजिटल टोकन' : 'DIGITAL TOKEN'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          generatedToken,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryGreen,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Phase 12: QR Code
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.cardBorder, width: 1.5),
                          ),
                          child: QrImageView(
                            data: QrValidationService.generateQrPayload(
                              bookingId:
                                  'BK-${generatedToken.replaceAll('TK-', '')}',
                              tokenNumber: generatedToken,
                              centreName: centre.name,
                              slotTime: slot.time,
                            ),
                            version: QrVersions.auto,
                            size: 160,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Status Badge: Not Checked In
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFF57F17),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.qr_code_2_rounded,
                                size: 15,
                                color: Color(0xFFF57F17),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isTelugu
                                    ? 'గేట్ వద్ద చెక్-ఇన్ కాలేదు'
                                    : (isHindi
                                        ? 'चेक-इन नहीं हुआ'
                                        : 'Not Checked In'),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF57F17),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isTelugu
                              ? 'వేగవంతమైన గేట్ ఎంట్రీ కోసం కేంద్రం అధికారికి ఈ QR కోడ్‌ను చూపించండి.'
                              : (isHindi
                                  ? 'तेज़ गेट प्रवेश के लिए केंद्र अधिकारी को यह क्यूआर कोड दिखाएं।'
                                  : 'Show this QR at the centre gate for fast check-in.'),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 14),
                        const Divider(),
                        const SizedBox(height: 12),

                        _buildInfoRow(
                          isTelugu
                              ? 'సేకరణ కేంద్రం:'
                              : (isHindi ? 'खरीद केंद्र:' : 'Centre:'),
                          centre.name,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          isTelugu
                              ? 'చేరుకోవాల్సిన సమయం:'
                              : (isHindi ? 'अनुशंसित आगमन:' : 'Arrival:'),
                          slot.recommendedArrival,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          isTelugu
                              ? 'కేటాయించిన స్లాట్:'
                              : (isHindi ? 'आरक्षित स्लॉट:' : 'Slot:'),
                          slot.time,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Phase 12: Journey Tracker (Compact)
                FarmerJourneyTracker(
                  currentStatus: 'Booked',
                  checkInStatus: 'Not Checked In',
                  paymentStatus: 'Pending',
                  isHindi: isHindi,
                  isTelugu: isTelugu,
                  isCompact: true,
                ),

                const SizedBox(height: 24),

                // View My Token Action (returns to dashboard with updated state)
                ElevatedButton.icon(
                  onPressed: () {
                    // Pop back through the booking stack returning the updatedData
                    Navigator.of(context).pop(updatedData);
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 22),
                  label: Text(
                    isTelugu
                        ? 'డాష్‌బోర్డ్‌కు తిరిగి వెళ్లండి'
                        : (isHindi ? 'डैशबोर्ड पर लौटें' : 'Return to Dashboard'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
