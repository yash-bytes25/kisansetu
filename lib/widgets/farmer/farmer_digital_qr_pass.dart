import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/qr_validation_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Phase 12: Farmer Digital QR Pass Widget.
///
/// Displays a high-contrast, scan-friendly digital pass with:
/// - Clear Token Number & Farmer Details
/// - Trilingual Labels & Status Badge (Not Checked In, Checked In, Already Used, Expired)
/// - Scan-friendly QR code using pure Dart [QrImageView]
/// - Centre Gate Instruction and Voice Assistance
class FarmerDigitalQrPass extends StatelessWidget {
  final String tokenNumber;
  final String farmerName;
  final String crop;
  final String quantity;
  final String centreName;
  final String bookedSlot;
  final String checkInStatus;
  final String? actualArrivalTime;
  final bool isHindi;
  final bool isTelugu;
  final VoidCallback? onVoiceGuide;

  const FarmerDigitalQrPass({
    super.key,
    required this.tokenNumber,
    required this.farmerName,
    required this.crop,
    required this.quantity,
    required this.centreName,
    required this.bookedSlot,
    this.checkInStatus = 'Not Checked In',
    this.actualArrivalTime,
    this.isHindi = false,
    this.isTelugu = false,
    this.onVoiceGuide,
  });

  @override
  Widget build(BuildContext context) {
    final payload = QrValidationService.generateQrPayload(
      bookingId: 'BK-${tokenNumber.replaceAll('TK-', '')}',
      tokenNumber: tokenNumber,
      centreName: centreName,
      slotTime: bookedSlot,
    );

    final isCheckedIn = checkInStatus.toLowerCase() == 'checked in';
    final isUsed = checkInStatus.toLowerCase() == 'already used';
    final isExpired = checkInStatus.toLowerCase() == 'expired';

    Color badgeBg;
    Color badgeText;
    IconData badgeIcon;
    String badgeLabel;

    if (isCheckedIn) {
      badgeBg = const Color(0xFFE8F5E9);
      badgeText = AppColors.success;
      badgeIcon = Icons.verified_rounded;
      badgeLabel = isTelugu
          ? 'గేట్ వద్ద చెక్-ఇన్ చేయబడింది'
          : (isHindi ? 'गेट पर चेक-इन हुआ' : 'Checked In');
    } else if (isUsed) {
      badgeBg = const Color(0xFFECEFF1);
      badgeText = const Color(0xFF546E7A);
      badgeIcon = Icons.done_all_rounded;
      badgeLabel = isTelugu
          ? 'ఇప్పటికే ఉపయోగించబడింది'
          : (isHindi ? 'पहले से उपयोग किया गया' : 'Already Used');
    } else if (isExpired) {
      badgeBg = const Color(0xFFFFEBEE);
      badgeText = AppColors.error;
      badgeIcon = Icons.timer_off_rounded;
      badgeLabel = isTelugu
          ? 'గడువు ముగిసింది'
          : (isHindi ? 'समय समाप्त' : 'Expired');
    } else {
      badgeBg = const Color(0xFFFFF8E1);
      badgeText = const Color(0xFFF57F17);
      badgeIcon = Icons.qr_code_2_rounded;
      badgeLabel = isTelugu
          ? 'గేట్ వద్ద చెక్-ఇన్ కాలేదు'
          : (isHindi ? 'चेक-इन नहीं हुआ' : 'Not Checked In');
    }

    final passTitle = isTelugu
        ? 'డిజిటల్ క్యూ పాస్'
        : (isHindi ? 'डिजिटल क्यू पास' : 'DIGITAL ENTRY PASS');

    final gateInstruction = isTelugu
        ? 'వేగవంతమైన గేట్ ఎంట్రీ కోసం కేంద్రం అధికారికి ఈ QR కోడ్‌ను చూపించండి.'
        : (isHindi
            ? 'तेज़ गेट प्रवेश के लिए केंद्र अधिकारी को यह क्यूआर कोड दिखाएं।'
            : 'Show this QR at the centre gate for fast contactless entry.');

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isCheckedIn
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.cardBorder,
          width: 1.5,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number_rounded,
                      color: AppColors.primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      passTitle,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: badgeText.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 14, color: badgeText),
                      const SizedBox(width: 4),
                      Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24, thickness: 1),

            // Farmer & Crop summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farmerName,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$crop • $quantity',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isTelugu ? 'స్లాట్' : (isHindi ? 'स्लॉट' : 'Slot'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      bookedSlot,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // High-contrast QR Code Display
            Semantics(
              label: 'QR Code for Token $tokenNumber',
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: payload,
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.textPrimary,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Large Token Number Display
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tokenNumber,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Centre Name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    centreName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            if (actualArrivalTime != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.access_time_filled_rounded,
                    size: 14,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isTelugu ? "చేరుకున్న సమయం" : (isHindi ? "आगमन समय" : "Arrival Time")}: $actualArrivalTime',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // Gate Instruction Note
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isCheckedIn
                    ? const Color(0xFFE8F5E9)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isCheckedIn
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    size: 18,
                    color: isCheckedIn
                        ? AppColors.success
                        : AppColors.primaryGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isCheckedIn
                          ? (isTelugu
                              ? 'గేట్ చెక్-ఇన్ విజయవంతమైంది! మీరు క్యూలో ఉన్నారు.'
                              : (isHindi
                                  ? 'गेट चेक-इन सफल! आप कतार में हैं।'
                                  : 'Gate check-in complete! You are in the active queue.'))
                          : gateInstruction,
                      style: AppTextStyles.caption.copyWith(
                        color: isCheckedIn
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
