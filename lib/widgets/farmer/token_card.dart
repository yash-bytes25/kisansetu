import 'package:flutter/material.dart';
import '../../models/farmer_dashboard_data.dart';
import '../../screens/farmer_action_placeholder_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/responsive_layout.dart';

/// Prominent My Token card with queue progress bar and details.
class TokenCard extends StatelessWidget {
  final FarmerDashboardData data;
  final bool isHindi;
  final bool isTelugu;
  final VoidCallback? onViewToken;
  final bool? isCompact;

  const TokenCard({
    super.key,
    required this.data,
    required this.isHindi,
    this.isTelugu = false,
    this.onViewToken,
    this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final compact = isCompact ?? ResponsiveLayout.isDesktop(context);
    // Progress calculation: lower people ahead means closer to turn
    final progress =
        (1.0 - (data.peopleAhead / data.totalInQueue)).clamp(0.0, 1.0);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(compact ? 14.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Title & Token Number
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTelugu
                          ? 'నా టోకెన్'
                          : (isHindi ? 'मेरा टोकन' : 'MY TOKEN'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.tokenNumber,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people_alt_rounded,
                        size: 18,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isTelugu
                            ? '${data.peopleAhead} మంది ముందున్నారు'
                            : (isHindi
                                ? '${data.peopleAhead} लोग आगे'
                                : '${data.peopleAhead} people ahead'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 10 : 16),

            // Queue progress indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTelugu
                          ? 'క్యూ పురోగతి'
                          : (isHindi ? 'कतार की प्रगति' : 'Queue Progress'),
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      isTelugu
                          ? 'అంచనా వేచి ఉండే సమయం: ${data.expectedWaitMinutes} నిమి'
                          : (isHindi
                              ? 'अपेक्षित प्रतीक्षा: ${data.expectedWaitMinutes} मिनट'
                              : 'Estimated wait: ${data.expectedWaitMinutes} min'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 12 : 18),

            // View Token Button (compact: 48dp, standard: 56dp)
            SizedBox(
              width: double.infinity,
              height: compact ? 48 : 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (onViewToken != null) {
                    onViewToken!();
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => FarmerActionPlaceholderScreen(
                        title: isTelugu
                            ? 'టోకెన్ వివరాలు'
                            : (isHindi ? 'टोकन विवरण' : 'Token Details'),
                        subtitle:
                            'Token: ${data.tokenNumber} • Status: ${data.centreStatus}',
                        icon: Icons.confirmation_number_rounded,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.confirmation_number_rounded, size: 22),
                label: Text(
                  isTelugu
                      ? 'టోకెన్ చూడండి'
                      : (isHindi ? 'टोकन देखें' : 'View Token'),
                  style: const TextStyle(
                    fontSize: 16,
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
}
