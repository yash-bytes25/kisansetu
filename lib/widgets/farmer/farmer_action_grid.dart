import 'package:flutter/material.dart';
import '../../screens/farmer_action_placeholder_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/responsive_layout.dart';

class FarmerActionItem {
  final String titleEn;
  final String titleHi;
  final String? titleTe;
  final IconData icon;

  const FarmerActionItem({
    required this.titleEn,
    required this.titleHi,
    this.titleTe,
    required this.icon,
  });
}

/// Responsive quick action grid for the Farmer Dashboard.
class FarmerActionGrid extends StatelessWidget {
  final bool isHindi;
  final bool isTelugu;
  final VoidCallback? onBookSlot;
  final VoidCallback? onMyToken;
  final VoidCallback? onPayment;
  final VoidCallback? onMyProduce;
  final VoidCallback? onMessages;
  final int unreadMessagesCount;
  final bool? isCompact;
  final int? crossAxisCount;

  const FarmerActionGrid({
    super.key,
    required this.isHindi,
    this.isTelugu = false,
    this.onBookSlot,
    this.onMyToken,
    this.onPayment,
    this.onMyProduce,
    this.onMessages,
    this.unreadMessagesCount = 0,
    this.isCompact,
    this.crossAxisCount,
  });

  static const List<FarmerActionItem> _actions = [
    FarmerActionItem(
      titleEn: 'Book Slot',
      titleHi: 'स्लॉट बुक करें',
      titleTe: 'స్లాట్ బుక్ చేయండి',
      icon: Icons.calendar_month_rounded,
    ),
    FarmerActionItem(
      titleEn: 'My Token',
      titleHi: 'मेरा टोकन',
      titleTe: 'నా టోకెన్',
      icon: Icons.confirmation_number_rounded,
    ),
    FarmerActionItem(
      titleEn: 'My Turn',
      titleHi: 'मेरी बारी',
      titleTe: 'నా వంతు',
      icon: Icons.access_time_filled_rounded,
    ),
    FarmerActionItem(
      titleEn: 'Payment',
      titleHi: 'भुगतान',
      titleTe: 'చెల్లింపు',
      icon: Icons.payments_rounded,
    ),
    FarmerActionItem(
      titleEn: 'Messages',
      titleHi: 'संदेश',
      titleTe: 'సందేశాలు',
      icon: Icons.notifications_active_rounded,
    ),
    FarmerActionItem(
      titleEn: 'My Produce',
      titleHi: 'मेरी उपज',
      titleTe: 'నా పంట',
      icon: Icons.grass_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = isCompact ??
            (ResponsiveLayout.isDesktop(context) || constraints.maxWidth >= 500);
        final cols = crossAxisCount ??
            (constraints.maxWidth >= 650 ? 3 : 2);
        final ratio = compact ? 2.0 : 1.5;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: compact ? 10 : 14,
            mainAxisSpacing: compact ? 10 : 14,
            childAspectRatio: ratio,
          ),
          itemBuilder: (context, index) {
            final item = _actions[index];
            final title = isTelugu
                ? (item.titleTe ?? item.titleEn)
                : (isHindi ? item.titleHi : item.titleEn);

            return Semantics(
              label: title,
              button: true,
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () {
                    if (item.titleEn == 'Book Slot' && onBookSlot != null) {
                      onBookSlot!();
                      return;
                    }
                    if ((item.titleEn == 'My Token' || item.titleEn == 'My Turn') &&
                        onMyToken != null) {
                      onMyToken!();
                      return;
                    }
                    if (item.titleEn == 'Payment' && onPayment != null) {
                      onPayment!();
                      return;
                    }
                    if (item.titleEn == 'My Produce' && onMyProduce != null) {
                      onMyProduce!();
                      return;
                    }
                    if (item.titleEn == 'Messages' && onMessages != null) {
                      onMessages!();
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => FarmerActionPlaceholderScreen(
                          title: title,
                          subtitle: isTelugu
                              ? '$title మాడ్యూల్ తదుపరి దశలో అందుబాటులోకి వస్తుంది.'
                              : (isHindi
                                  ? '$title मॉड्यूल आगामी विकास चरण के लिए तैयार है।'
                                  : '$title module scheduled for the subsequent phase.'),
                          icon: item.icon,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  splashColor: AppColors.primaryLight.withValues(alpha: 0.15),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 10 : 14,
                      vertical: compact ? 8 : 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: compact ? 36 : 46,
                          height: compact ? 36 : 46,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(compact ? 10 : 12),
                          ),
                          child: Icon(
                            item.icon,
                            size: compact ? 20 : 26,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        SizedBox(width: compact ? 8 : 12),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: compact ? 13 : 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (item.titleEn == 'Messages' &&
                                  unreadMessagesCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '[$unreadMessagesCount]',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
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
              ),
            );
          },
        );
      },
    );
  }
}
