import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Model for a stage in the 8-stage Farmer Procurement Journey.
class JourneyStageData {
  final int stageNumber;
  final String nameEn;
  final String nameHi;
  final String nameTe;
  final String descriptionEn;
  final String descriptionHi;
  final String descriptionTe;
  final IconData icon;

  const JourneyStageData({
    required this.stageNumber,
    required this.nameEn,
    required this.nameHi,
    required this.nameTe,
    required this.descriptionEn,
    required this.descriptionHi,
    required this.descriptionTe,
    required this.icon,
  });
}

/// Phase 12: Visual 8-Stage Farmer Journey Tracker.
///
/// Provides complete transparency on produce intake and verification.
/// Stages:
/// 1. Booked (स्लॉट बुक हुआ / స్లాట్ బుక్ చేయబడింది)
/// 2. Checked In (गेट चेक-इन / గేట్ చెక్-ఇన్)
/// 3. Waiting (कतार में / క్యూలో)
/// 4. Quality Check (गुणवत्ता जांच / నాణ్యత తనిఖీ)
/// 5. Weighment (वजन माप / తూకం కొలత)
/// 6. Accepted (स्वीकृत / ఆమోదించబడింది)
/// 7. Payment Initiated (भुगतान शुरू / చెల్లింపు ప్రారంభించబడింది)
/// 8. Payment Credited (भुगतान जमा / చెల్లింపు జమ చేయబడింది)
class FarmerJourneyTracker extends StatelessWidget {
  final String currentStatus;
  final String checkInStatus;
  final String paymentStatus;
  final bool isHindi;
  final bool isTelugu;
  final bool isCompact;

  const FarmerJourneyTracker({
    super.key,
    required this.currentStatus,
    this.checkInStatus = 'Not Checked In',
    this.paymentStatus = 'Pending',
    this.isHindi = false,
    this.isTelugu = false,
    this.isCompact = false,
  });

  static const List<JourneyStageData> stages = [
    JourneyStageData(
      stageNumber: 1,
      nameEn: 'Booked',
      nameHi: 'स्लॉट बुक हुआ',
      nameTe: 'స్లాట్ బుక్ చేయబడింది',
      descriptionEn: 'Slot confirmed with digital token',
      descriptionHi: 'डिजिटल टोकन के साथ स्लॉट पक्का हुआ',
      descriptionTe: 'డిజిటల్ టోకెన్‌తో స్లాట్ ధృవీకరించబడింది',
      icon: Icons.event_available_rounded,
    ),
    JourneyStageData(
      stageNumber: 2,
      nameEn: 'Checked In',
      nameHi: 'गेट चेक-इन',
      nameTe: 'గేట్ చెక్-ఇన్',
      descriptionEn: 'QR verified at centre gate',
      descriptionHi: 'गेट पर क्यूआर कोड सत्यापित हुआ',
      descriptionTe: 'గేట్ వద్ద QR కోడ్ ధృవీకరించబడింది',
      icon: Icons.qr_code_scanner_rounded,
    ),
    JourneyStageData(
      stageNumber: 3,
      nameEn: 'Waiting',
      nameHi: 'कतार में',
      nameTe: 'క్యూలో',
      descriptionEn: 'Queue position assigned',
      descriptionHi: 'कतार संख्या आवंटित की गई',
      descriptionTe: 'క్యూ స్థానం కేటాయించబడింది',
      icon: Icons.hourglass_top_rounded,
    ),
    JourneyStageData(
      stageNumber: 4,
      nameEn: 'Quality Check',
      nameHi: 'गुणवत्ता जांच',
      nameTe: 'నాణ్యత తనిఖీ',
      descriptionEn: 'Moisture & purity inspection',
      descriptionHi: 'नमी और शुद्धता की जांच',
      descriptionTe: 'తేమ మరియు నాణ్యత తనిఖీ',
      icon: Icons.science_rounded,
    ),
    JourneyStageData(
      stageNumber: 5,
      nameEn: 'Weighment',
      nameHi: 'वजन माप',
      nameTe: 'తూకం కొలత',
      descriptionEn: 'Electronic weighbridge scale',
      descriptionHi: 'इलेक्ट्रॉनिक तराजू से वास्तविक तौल',
      descriptionTe: 'ఎలక్ట్రానిక్ తూకం కొలత',
      icon: Icons.scale_rounded,
    ),
    JourneyStageData(
      stageNumber: 6,
      nameEn: 'Accepted',
      nameHi: 'स्वीकृत',
      nameTe: 'ఆమోదించబడింది',
      descriptionEn: 'Produce confirmed & signed',
      descriptionHi: 'उपज स्वीकार और ई-रसीद तैयार',
      descriptionTe: 'ఉత్పత్తి ఆమోదించబడింది మరియు నిర్ధారించబడింది',
      icon: Icons.task_alt_rounded,
    ),
    JourneyStageData(
      stageNumber: 7,
      nameEn: 'Payment Initiated',
      nameHi: 'भुगतान शुरू',
      nameTe: 'చెల్లింపు ప్రారంభించబడింది',
      descriptionEn: 'DBT advice sent to treasury',
      descriptionHi: 'डीबीटी भुगतान बैंक को भेजा गया',
      descriptionTe: 'DBT చెల్లింపు ప్రక్రియ ప్రారంభమైంది',
      icon: Icons.account_balance_rounded,
    ),
    JourneyStageData(
      stageNumber: 8,
      nameEn: 'Payment Credited',
      nameHi: 'भुगतान जमा',
      nameTe: 'చెల్లింపు జమ చేయబడింది',
      descriptionEn: 'Direct transfer to bank account',
      descriptionHi: 'खाते में राशि जमा हो गई',
      descriptionTe: 'ఖాతాలో మొత్తం జమ చేయబడింది',
      icon: Icons.verified_rounded,
    ),
  ];

  /// Computes the 0-indexed active stage based on lifecycleStatus, checkInStatus, and paymentStatus.
  int get activeStageIndex {
    final pay = paymentStatus.toLowerCase();
    final life = currentStatus.toLowerCase();
    final check = checkInStatus.toLowerCase();

    if (pay == 'completed' || life == 'completed') {
      return 7; // Stage 8
    }
    if (pay == 'initiated' ||
        life == 'payment pending' ||
        life == 'payment initiated') {
      return 6; // Stage 7
    }
    if (life == 'accepted') {
      return 5; // Stage 6
    }
    if (life == 'weighment') {
      return 4; // Stage 5
    }
    if (life == 'quality check' || life == 'sampling') {
      return 3; // Stage 4
    }
    if (life == 'waiting' || life == 'arrived') {
      return 2; // Stage 3
    }
    if (check == 'checked in') {
      return 1; // Stage 2
    }
    return 0; // Stage 1 (Booked)
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = activeStageIndex;
    final title = isTelugu
        ? 'సేకరణ ప్రయాణం ట్రాకర్'
        : (isHindi ? 'खरीद यात्रा ट्रैकर' : 'Procurement Journey Tracker');

    final subtitle = isTelugu
        ? '8-దశల పారదర్శక పురోగతి'
        : (isHindi ? '8-चरणीय पारदर्शी प्रगति' : '8-Stage Transparent Progress');

    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.timeline_rounded,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.titleMedium.copyWith(fontSize: 16),
                        ),
                        Text(
                          subtitle,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${activeIndex + 1}/8',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Horizontal Scrollable Timeline for Small Screens & High Density
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(stages.length, (index) {
                  final stage = stages[index];
                  final isCompleted = index < activeIndex;
                  final isCurrent = index == activeIndex;
                  final stageName = isTelugu
                      ? stage.nameTe
                      : (isHindi ? stage.nameHi : stage.nameEn);

                  Color circleBg;
                  Color borderColor;
                  Widget iconWidget;

                  if (isCompleted) {
                    circleBg = AppColors.success;
                    borderColor = AppColors.success;
                    iconWidget = const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    );
                  } else if (isCurrent) {
                    circleBg = AppColors.primaryDark;
                    borderColor = AppColors.accentAmber;
                    iconWidget = Icon(
                      stage.icon,
                      color: Colors.white,
                      size: 16,
                    );
                  } else {
                    circleBg = const Color(0xFFECEFF1);
                    borderColor = const Color(0xFFCFD8DC);
                    iconWidget = Icon(
                      stage.icon,
                      size: 14,
                      color: const Color(0xFF90A4AE),
                    );
                  }

                  return Row(
                    children: [
                      Container(
                        width: 90,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primaryGreen.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isCurrent
                              ? Border.all(
                                  color: AppColors.primaryGreen
                                      .withValues(alpha: 0.4),
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Indicator Circle
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: circleBg,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: borderColor,
                                  width: isCurrent ? 2.5 : 1.5,
                                ),
                                boxShadow: isCurrent
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryGreen
                                              .withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(child: iconWidget),
                            ),
                            const SizedBox(height: 6),
                            // Stage Name
                            Text(
                              stageName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isCurrent
                                    ? FontWeight.bold
                                    : (isCompleted
                                        ? FontWeight.w600
                                        : FontWeight.normal),
                                color: isCurrent
                                    ? AppColors.primaryDark
                                    : (isCompleted
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            // Non-color badge
                            if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentAmber
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isTelugu
                                      ? 'ప్రస్తుతం'
                                      : (isHindi ? 'सक्रिय' : 'Current'),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB78103),
                                  ),
                                ),
                              )
                            else if (isCompleted)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 12,
                                color: AppColors.success,
                              ),
                          ],
                        ),
                      ),
                      // Connector line between stages
                      if (index < stages.length - 1)
                        Container(
                          width: 16,
                          height: 2,
                          color: index < activeIndex
                              ? AppColors.success
                              : const Color(0xFFCFD8DC),
                        ),
                    ],
                  );
                }),
              ),
            ),

            if (!isCompact) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Active Stage Description Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDark,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        stages[activeIndex].icon,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${isTelugu ? "ప్రస్తుత దశ" : (isHindi ? "वर्तमान चरण" : "Active Stage")}: ${isTelugu ? stages[activeIndex].nameTe : (isHindi ? stages[activeIndex].nameHi : stages[activeIndex].nameEn)}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isTelugu
                                ? stages[activeIndex].descriptionTe
                                : (isHindi
                                    ? stages[activeIndex].descriptionHi
                                    : stages[activeIndex].descriptionEn),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}
