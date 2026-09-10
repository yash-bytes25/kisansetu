import 'package:flutter/material.dart';
import '../../models/farmer_dashboard_data.dart';
import '../../screens/farmer_alternative_centres_screen.dart';
import '../../screens/farmer_go_time_details_screen.dart';
import '../../services/connectivity_service.dart';
import '../../services/queue_prediction_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/responsive_layout.dart';

/// Flagship "When Should I Go?" decision-support card.
///
/// Indicates real-time dynamic queue guidance, travel adjustments,
/// and explainable recommendations.
class GoTimeCard extends StatelessWidget {
  final FarmerDashboardData data;
  final bool isHindi;
  final bool isTelugu;
  final bool? isCompact;

  const GoTimeCard({
    super.key,
    required this.data,
    required this.isHindi,
    this.isTelugu = false,
    this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final compact = isCompact ?? ResponsiveLayout.isDesktop(context);
    final rec = data.recommendation;
    final isGoodTime = data.isGoodTimeToLeave;

    Color borderColor;
    Color containerColor;
    IconData statusIcon;
    String badgeText;
    Color textColor;

    switch (rec) {
      case GoTimeRecommendation.centreTemporarilyStopped:
        borderColor = AppColors.error;
        containerColor = AppColors.errorContainer;
        statusIcon = Icons.pause_circle_filled_rounded;
        textColor = AppColors.error;
        badgeText = isTelugu
            ? 'కేంద్రం నిలిపివేయబడింది'
            : (isHindi ? 'केंद्र अस्थायी रूप से बंद' : 'CENTRE TEMPORARILY STOPPED');
        break;
      case GoTimeRecommendation.delay:
        borderColor = AppColors.warning;
        containerColor = AppColors.errorContainer;
        statusIcon = Icons.warning_amber_rounded;
        textColor = Colors.deepOrange;
        badgeText = isTelugu
            ? 'కేంద్రం ఆలస్యమైంది'
            : (isHindi ? 'केंद्र विलंबित' : 'CENTRE DELAYED');
        break;
      case GoTimeRecommendation.wait:
        borderColor = AppColors.warning;
        containerColor = AppColors.errorContainer;
        statusIcon = Icons.hourglass_top_rounded;
        textColor = AppColors.warning;
        badgeText = isTelugu
            ? 'కాసేపు వేచి ఉండండి'
            : (isHindi ? 'थोड़ा प्रतीक्षा करें' : 'WAIT A LITTLE');
        break;
      case GoTimeRecommendation.slotApproaching:
        borderColor = AppColors.primaryGreen;
        containerColor = AppColors.primaryContainer;
        statusIcon = Icons.notifications_active_rounded;
        textColor = AppColors.primaryGreen;
        badgeText = isTelugu
            ? 'స్లాట్ సమయం సమీపించింది'
            : (isHindi ? 'स्लॉट निकट है' : 'SLOT APPROACHING');
        break;
      case GoTimeRecommendation.checkInRequired:
        borderColor = AppColors.primaryGreen;
        containerColor = AppColors.primaryContainer;
        statusIcon = Icons.how_to_reg_rounded;
        textColor = AppColors.primaryGreen;
        badgeText = isTelugu
            ? 'చెక్-ఇన్ అవసరం'
            : (isHindi ? 'चेक-इन आवश्यक' : 'CHECK-IN REQUIRED');
        break;
      case GoTimeRecommendation.goNow:
        borderColor = AppColors.primaryGreen;
        containerColor = AppColors.primaryContainer;
        statusIcon = Icons.check_circle_rounded;
        textColor = AppColors.primaryGreen;
        badgeText = isTelugu
            ? 'బయలుదేరడానికి మంచి సమయం'
            : (isHindi ? 'निकलने का सही समय' : 'GOOD TIME TO LEAVE');
        break;
    }

    return Semantics(
      label: 'When Should I Go? $badgeText. Recommended departure is ${data.recommendedDepartureTime}.',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 14.0 : 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with Title and Dynamic Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTelugu
                              ? 'నేను ఎప్పుడు వెళ్ళాలి?'
                              : (isHindi
                                  ? 'मुझे कब जाना चाहिए?'
                                  : 'When Should I Go?'),
                          style: compact
                              ? AppTextStyles.titleLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                )
                              : AppTextStyles.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isTelugu
                              ? 'స్మార్ట్ క్యూ & ప్రయాణ మార్గదర్శకం'
                              : (isHindi
                                  ? 'स्मार्ट कतार व प्रस्थान गाइड'
                                  : 'Smart Queue & Travel Guidance'),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),

                  // Dynamic Badge (Non-color-only: icon + text + pill border)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: borderColor,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: textColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 12 : 18),

              // Main Guidance Callout
              if (rec == GoTimeRecommendation.centreTemporarilyStopped) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.pause_circle_outline_rounded,
                        size: 34,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          isTelugu
                              ? 'కేంద్రంలో సేకరణ తాత్కాలికంగా ఆపివేయబడింది. దయచేసి బయలుదేరవద్దు.'
                              : (isHindi
                                  ? 'केंद्र में खरीद प्रक्रिया अस्थायी रूप से बंद है। कृपया अभी न निकलें।'
                                  : 'Procurement is temporarily stopped. Do not travel yet.'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (rec == GoTimeRecommendation.delay) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 34,
                        color: Colors.deepOrange,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'WAIT A LITTLE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.deepOrange,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isTelugu
                                  ? 'అప్‌డేట్ చేసిన బయలుదేరే సమయం: ${data.recommendedDepartureTime}'
                                  : ('${isHindi ? 'अद्यतन प्रस्थान समय:' : 'UPDATED DEPARTURE:'} ${data.recommendedDepartureTime}'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isTelugu
                                  ? 'సేకరణ ఆలస్యం (ధర్మకాంటా अंशांकन): రాక సమయం ${data.waitRecommendedArrival}కి మారింది.'
                                  : (isHindi
                                      ? 'धर्मकांटा अंशांकन के कारण नया आगमन समय ${data.waitRecommendedArrival} है।'
                                      : 'Intake temporarily paused for weighbridge calibration. Recommended arrival: ${data.waitRecommendedArrival}.'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (!isGoodTime) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 30,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isTelugu
                              ? 'కేంద్రం ప్రస్తుతం రద్దీగా ఉంది. సూచించిన రాక సమయం: ${data.waitRecommendedArrival}। బయలుదేరడానికి సమయం అయినప్పుడు మేము మీకు తెలియజేస్తాము.'
                              : (isHindi
                                  ? 'केंद्र वर्तमान में व्यस्त है। अनुशंसित आगमन: ${data.waitRecommendedArrival}। निकलने का समय होने पर हम आपको सूचित करेंगे।'
                                  : data.waitReason),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.directions_run_rounded,
                        size: 34,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTelugu
                                  ? 'బయలుదేరండి: ${data.recommendedDepartureTime}'
                                  : ('${isHindi ? 'प्रस्थान करें:' : 'LEAVE AT'} ${data.recommendedDepartureTime}'),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isTelugu
                                  ? 'మీ సేకరణ వంతు సుమారు ${data.expectedTurnTime}'
                                  : (isHindi
                                      ? 'आपकी खरीद की बारी लगभग ${data.expectedTurnTime} है'
                                      : 'Your procurement turn is around ${data.expectedTurnTime}'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: compact ? 10 : 16),

              if (!AppConnectivityService.instance.isOnline) ...[
                Container(
                  key: const Key('stale_queue_data_indicator'),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade700, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded, size: 14, color: Colors.orange.shade900),
                      const SizedBox(width: 6),
                      Text(
                        isTelugu
                            ? 'చివరిగా తెలిసిన క్యూ సమాచారం (ప్రత్యక్షంగా లేదు)'
                            : (isHindi
                                ? 'अंतिम ज्ञात कतार स्थिति (लाइव नहीं)'
                                : 'Last Known Queue Status (Not Live)'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Supporting Metrics Row (Travel time, People ahead, Expected wait, Load)
              Container(
                padding: EdgeInsets.symmetric(
                    vertical: compact ? 8 : 12, horizontal: compact ? 6 : 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        icon: Icons.directions_car_rounded,
                        label: isTelugu
                            ? 'ప్రయాణం'
                            : (isHindi ? 'यात्रा' : 'Travel'),
                        value: isTelugu
                            ? '${data.travelTimeMinutes} నిమి'
                            : '${data.travelTimeMinutes} min',
                      ),
                    ),
                    Container(height: 28, width: 1, color: AppColors.cardBorder),
                    Expanded(
                      child: _buildMetricItem(
                        icon: Icons.people_rounded,
                        label: isTelugu
                            ? 'ముందున్నవారు'
                            : (isHindi ? 'आगे लोग' : 'Ahead'),
                        value: '${data.peopleAhead}',
                      ),
                    ),
                    Container(height: 28, width: 1, color: AppColors.cardBorder),
                    Expanded(
                      child: _buildMetricItem(
                        icon: Icons.access_time_rounded,
                        label: isTelugu
                            ? 'నిరీక్షణ'
                            : (isHindi ? 'प्रतीक्षा' : 'Wait'),
                        value: isTelugu
                            ? '${data.expectedWaitMinutes} నిమి'
                            : '${data.expectedWaitMinutes} min',
                      ),
                    ),
                    Container(height: 28, width: 1, color: AppColors.cardBorder),
                    Expanded(
                      child: _buildMetricItem(
                        icon: Icons.speed_rounded,
                        label: isTelugu
                            ? 'లోడ్'
                            : (isHindi ? 'लोड' : 'Load'),
                        value: '${data.centreLoadPercentage}%',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 12 : 18),

              // View Details Primary Action (Minimum 48/56dp touch target)
              SizedBox(
                width: double.infinity,
                height: compact ? 48 : 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => FarmerGoTimeDetailsScreen(
                          data: data,
                          isHindi: isHindi,
                          isTelugu: isTelugu,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.insights_rounded, size: 22),
                  label: Text(
                    isTelugu
                        ? 'వివరాలు చూడండి'
                        : (isHindi ? 'विवरण देखें' : 'View Details'),
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
              if (data.recommendation == GoTimeRecommendation.delay ||
                  data.recommendation ==
                      GoTimeRecommendation.centreTemporarilyStopped ||
                  data.recommendation == GoTimeRecommendation.wait ||
                  data.centreLoadPercentage >= 85 ||
                  data.expectedWaitMinutes >= 45) ...[
                SizedBox(height: compact ? 8 : 12),
                SizedBox(
                  width: double.infinity,
                  height: compact ? 46 : 52,
                  child: ElevatedButton.icon(
                    key: const Key('btn_find_better_centre'),
                    onPressed: () {
                      if (!AppConnectivityService.instance.isOnline) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isTelugu
                                ? 'ఆఫ్‌లైన్‌లో ఉన్నప్పుడు కేంద్రాన్ని మార్చడం సాధ్యం కాదు.'
                                : (isHindi
                                    ? 'ऑफ़लाइन होने पर केंद्र बदलना संभव नहीं है।'
                                    : 'Centre switching is blocked while offline. Please connect to the internet.')),
                            backgroundColor: AppColors.textPrimary,
                          ),
                        );
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => FarmerAlternativeCentresScreen(
                            isHindi: isHindi,
                            isTelugu: isTelugu,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                    label: Text(
                      isTelugu
                          ? 'మంచి కేంద్రాన్ని కనుగొనండి'
                          : (isHindi ? 'बेहतर केंद्र खोजें' : 'Find Better Centre'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryGreen),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
