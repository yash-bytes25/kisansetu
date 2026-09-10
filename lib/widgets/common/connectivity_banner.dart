import 'package:flutter/material.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_essential_info_service.dart';
import '../../theme/app_colors.dart';

/// Reusable connectivity banner for KisanSetu.
///
/// Communicates ONLINE / OFFLINE state with high-contrast icons, text labels,
/// and last-updated timestamps so farmers always know whether information is live.
class ConnectivityBanner extends StatelessWidget {
  final bool isHindi;
  final bool isTelugu;
  final VoidCallback? onRefresh;

  const ConnectivityBanner({
    super.key,
    this.isHindi = false,
    this.isTelugu = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppConnectivityService.instance.isOnlineListenable,
      builder: (context, isOnline, _) {
        final lastUpdated =
            OfflineEssentialInfoService.instance.lastUpdatedFormatted;

        if (isOnline) {
          return Container(
            key: const Key('connectivity_banner_online'),
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primaryGreen.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_rounded,
                  color: AppColors.primaryGreen,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  isTelugu
                      ? 'ఆన్‌లైన్ • ప్రత్యక్ష డేటా'
                      : (isHindi
                          ? 'ऑनलाइन • लाइव डेटा'
                          : 'ONLINE • Live Data'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const Spacer(),
                Text(
                  isTelugu
                      ? 'ప్రత్యక్షంగా సమకాలీకరించబడింది'
                      : (isHindi ? 'लाइव सिंक' : 'Live Sync'),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          );
        }

        // OFFLINE BANNER
        return Container(
          key: const Key('connectivity_banner_offline'),
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0), // Warm amber
            border: Border(
              bottom: BorderSide(
                color: Colors.orange.shade700,
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off_rounded,
                  color: Colors.orange.shade900,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isTelugu
                          ? 'ఆఫ్‌లైన్ • చివరిగా నవీకరించబడిన సమాచారాన్ని చూపుతోంది'
                          : (isHindi
                              ? 'ऑफलाइन • अंतिम अपडेट की गई जानकारी दिखाई जा रही है'
                              : 'OFFLINE • Showing last updated information'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isTelugu
                          ? 'చివరి నవీకరణ: $lastUpdated (ప్రత్యక్షంగా లేదు)'
                          : (isHindi
                              ? 'अंतिम अपडेट: $lastUpdated (लाइव नहीं है)'
                              : 'Last updated: $lastUpdated (Not Live)'),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.brown.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onRefresh != null) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  key: const Key('btn_refresh_connectivity'),
                  onPressed: onRefresh,
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 32),
                    side: BorderSide(color: Colors.orange.shade800),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    isTelugu
                        ? 'రిఫ్రెష్'
                        : (isHindi ? 'रिफ्रेश' : 'Refresh'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
