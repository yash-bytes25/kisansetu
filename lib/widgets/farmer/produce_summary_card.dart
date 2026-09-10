import 'package:flutter/material.dart';
import '../../models/farmer_dashboard_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

import '../../theme/responsive_layout.dart';

/// Compact card showing the farmer's registered produce summary.
class ProduceSummaryCard extends StatelessWidget {
  final FarmerDashboardData data;
  final bool isHindi;
  final bool isTelugu;
  final VoidCallback? onTap;
  final VoidCallback? onChangeCrop;
  final bool? isCompact;

  const ProduceSummaryCard({
    super.key,
    required this.data,
    required this.isHindi,
    this.isTelugu = false,
    this.onTap,
    this.onChangeCrop,
    this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    final compact = isCompact ?? ResponsiveLayout.isDesktop(context);
    final iconBoxSize = compact ? 40.0 : 46.0;
    final iconSize = compact ? 22.0 : 26.0;
    final verticalPadding = compact ? 10.0 : 14.0;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: verticalPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: onTap,
                    child: Container(
                      width: iconBoxSize,
                      height: iconBoxSize,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.grass_rounded,
                        size: iconSize,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: onTap,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTelugu
                                    ? 'నా పంట'
                                    : (isHindi ? 'मेरी उपज' : 'My Produce'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${data.cropName} • ${data.quantity}',
                                style: AppTextStyles.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (onChangeCrop != null) ...[
                        const SizedBox(height: 4),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: const ValueKey('btn_change_crop'),
                            onTap: onChangeCrop,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.swap_horiz_rounded,
                                    size: 15,
                                    color: AppColors.primaryGreen,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isTelugu
                                        ? 'పంటను మార్చండి'
                                        : (isHindi ? 'फसल बदलें' : 'Change Crop'),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        data.centreName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.cardBorder),
            const SizedBox(height: 8),

            // Concise Status Row
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            isTelugu
                                ? 'పంట: '
                                : (isHindi ? 'उत्पाद: ' : 'Produce: '),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            data.lifecycleStatus,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            isTelugu
                                ? 'చెల్లింపు: '
                                : (isHindi ? 'भुगतान: ' : 'Payment: '),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            data.paymentStatus,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded,
                              size: 16, color: AppColors.textTertiary),
                        ],
                      ),
                    ],
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
