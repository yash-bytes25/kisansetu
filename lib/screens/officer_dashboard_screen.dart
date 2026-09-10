import 'package:flutter/material.dart';
import '../models/alternative_centre_recommendation.dart';
import '../models/capacity_forecast_model.dart';
import '../models/officer_exception_model.dart';
import '../models/procurement_slot_info.dart';
import '../models/slot_reallocation_model.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../services/procurement_state_service.dart';
import '../services/slot_reallocation_service.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/responsive_layout.dart';
import '../widgets/officer/officer_exception_detail_sheet.dart';
import 'officer_farmer_detail_screen.dart';
import 'officer_qr_scanner_screen.dart';
import 'role_selection_screen.dart';

/// Phase 7: KisanSetu Procurement Officer Operations Dashboard.
///
/// Designed with INFORMATION → DECIDE → CONTROL operational philosophy:
/// - Real-time operational header with centre status and date.
/// - 7-metric KPI summary grid.
/// - Interactive Live Queue list with instant stage inspection.
/// - Call Next Farmer and queue operational actions.
/// - Real-time Centre Status & Capacity controls.
/// - Slot capacity management section.
class OfficerDashboardScreen extends StatefulWidget {
  final String officerId;

  const OfficerDashboardScreen({
    super.key,
    required this.officerId,
  });

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  final _service = ProcurementStateService();

  void _showVoiceGuidance() {
    final text =
        'Procurement Operations Dashboard. Centre: ${_service.centreName}. Status: ${_service.centreStatus}. ${_service.todayBookingsCount} bookings today, ${_service.waitingCount} waiting in queue. Tap Call Next Farmer to advance dock intake.';
    VoiceAssistantSpeechService.instance.speak(text, language: 'en');

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
                text,
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

  void _openFarmerDetail(String tokenNumber) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => OfficerFarmerDetailScreen(
          tokenNumber: tokenNumber,
        ),
      ),
    );
  }

  void _showAdjustSlotCapacityDialog(ProcurementSlotInfo slot) {
    int currentCap = slot.capacity;
    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  const Icon(Icons.tune_rounded,
                      color: AppColors.secondary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Adjust Slot Capacity (${slot.time})'),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Bookings: ${slot.bookingsCount} farmers',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Dock Capacity:',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: currentCap > slot.bookingsCount
                                ? () {
                                    setDialogState(() {
                                      currentCap--;
                                    });
                                  }
                                : null,
                          ),
                          Text(
                            '$currentCap',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () {
                              setDialogState(() {
                                currentCap++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _service.adjustSlotCapacity(slot.time, currentCap);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save Capacity'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (context) => const RoleSelectionScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(68),
            child: AppBar(
              automaticallyImplyLeading: false,
              elevation: 0,
              backgroundColor: AppColors.surface,
              titleSpacing: 12,
              title: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'KisanSetu • ',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondary,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                'Operations',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_service.centreName} • Today',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                Semantics(
                  label: 'Listen to operations status',
                  button: true,
                  child: IconButton(
                    tooltip: 'Listen / सुनें',
                    icon: const Icon(
                      Icons.volume_up_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                    onPressed: _showVoiceGuidance,
                  ),
                ),
                IconButton(
                  tooltip: 'Logout',
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: _logout,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable:
                      AppConnectivityService.instance.isOnlineListenable,
                  builder: (context, isOnline, _) {
                    if (isOnline) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      key: const Key('officer_offline_pause_banner'),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      color: const Color(0xFFFFF3E0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_off_rounded,
                            color: Colors.orange.shade900,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'OPERATIONAL DATA PAUSED (OFFLINE)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Live queue updates, check-in validation, and state synchronization are paused until internet connection returns.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.brown.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop =
                          constraints.maxWidth >= ResponsiveLayout.desktopMin;

                if (isDesktop) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 14.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1440),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Top Bar: Centre Status Banner
                            _buildCentreStatusBanner(),
                            const SizedBox(height: 12),

                            // 2. High-Density Horizontal KPI Row
                            _buildKpiSummarySection(isCompact: true),
                            const SizedBox(height: 16),

                            // 3. Two-Column Command Operations Layout
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column: Critical Attention & Live Queue
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildNeedsAttentionSection(),
                                      const SizedBox(height: 14),
                                      _buildLiveQueueSection(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 18),

                                // Right Column: Operational Controls, Capacity, Slot Management
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildOperationalControlsSection(
                                          isCompact: true),
                                      const SizedBox(height: 14),
                                      _buildControlsSection(),
                                      const SizedBox(height: 14),
                                      _buildSlotManagementSection(),
                                      const SizedBox(height: 14),
                                      _buildSlotReallocationSection(),
                                      const SizedBox(height: 14),
                                      _buildAlternativeCentresSection(),
                                      const SizedBox(height: 14),
                                      _buildCapacityForecastSection(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Mobile / Tablet (< 850px) Layout: Sequential
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Operational Centre Status Banner
                      _buildCentreStatusBanner(),
                      const SizedBox(height: 16),

                      // Phase 14: "Needs Attention" Priority Exception Panel
                      _buildNeedsAttentionSection(),
                      const SizedBox(height: 16),

                      // 2. KPI Summary Cards Grid
                      _buildKpiSummarySection(),
                      const SizedBox(height: 20),

                      // 3. Primary Operational Actions Toolbar
                      _buildOperationalControlsSection(),
                      const SizedBox(height: 22),

                      // 4. Live Queue Table/List
                      _buildLiveQueueSection(),
                      const SizedBox(height: 22),

                      // 5. Centre Status & Capacity Control
                      _buildControlsSection(),
                      const SizedBox(height: 22),

                      // 6. Slot Management Section
                      _buildSlotManagementSection(),
                      const SizedBox(height: 20),

                      // 7. Dynamic Slot Reallocation Section
                      _buildSlotReallocationSection(),
                      const SizedBox(height: 20),

                      // 8. Catchment Alternative Centres Section
                      _buildAlternativeCentresSection(),
                      const SizedBox(height: 20),

                      // 9. Capacity Forecast Section
                      _buildCapacityForecastSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildCentreStatusBanner() {
    Color bg = AppColors.primaryContainer;
    Color border = AppColors.primaryGreen;
    Color text = AppColors.primaryGreen;
    IconData icon = Icons.check_circle_rounded;

    if (_service.centreStatus == 'Open • Busy') {
      bg = AppColors.warning.withValues(alpha: 0.12);
      border = AppColors.warning;
      text = AppColors.warning;
      icon = Icons.hourglass_top_rounded;
    } else if (_service.centreStatus == 'Temporarily Delayed') {
      bg = AppColors.errorContainer;
      border = AppColors.error;
      text = AppColors.error;
      icon = Icons.pause_circle_filled_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: text, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _service.centreName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Operating Status: ${_service.centreStatus} • Capacity: ${_service.centreCapacityPercent}% (${_service.capacityMode})',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedsAttentionSection() {
    final exceptions = _service.exceptions;
    final criticalCount = _service.criticalExceptionCount;
    final warningCount = _service.warningExceptionCount;
    final openCount = _service.openExceptionCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: criticalCount > 0
              ? AppColors.error.withValues(alpha: 0.6)
              : warningCount > 0
                  ? AppColors.warning.withValues(alpha: 0.5)
                  : AppColors.cardBorder,
          width: criticalCount > 0 ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: criticalCount > 0
                ? AppColors.error.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title and count pills
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: criticalCount > 0
                      ? AppColors.errorContainer
                      : warningCount > 0
                          ? AppColors.warningContainer
                          : AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  criticalCount > 0
                      ? Icons.crisis_alert_rounded
                      : warningCount > 0
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline_rounded,
                  size: 18,
                  color: criticalCount > 0
                      ? AppColors.error
                      : warningCount > 0
                          ? AppColors.warning
                          : AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Needs Attention',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (criticalCount > 0)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Critical: $criticalCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (warningCount > 0)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Warnings: $warningCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Open: $openCount',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Body: Either empty state or list of open exceptions
          if (openCount == 0)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.primaryGreen, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '✓ No critical issues • Centre operating normally',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'All queue loads, waiting times, and DBT processing are within normal parameters.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: exceptions
                  .where((e) => e.status != ExceptionStatus.resolved)
                  .map((ex) => _buildExceptionCard(ex))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildExceptionCard(OfficerExceptionModel ex) {
    Color cardColor;
    Color borderColor;
    Color tagColor;
    Color tagBg;
    IconData icon;

    switch (ex.severity) {
      case ExceptionSeverity.critical:
        cardColor = AppColors.errorContainer.withValues(alpha: 0.25);
        borderColor = AppColors.error.withValues(alpha: 0.5);
        tagColor = AppColors.error;
        tagBg = AppColors.errorContainer;
        icon = Icons.error_rounded;
        break;
      case ExceptionSeverity.warning:
        cardColor = AppColors.warningContainer.withValues(alpha: 0.25);
        borderColor = AppColors.warning.withValues(alpha: 0.5);
        tagColor = AppColors.warning;
        tagBg = AppColors.warningContainer;
        icon = Icons.warning_amber_rounded;
        break;
      case ExceptionSeverity.info:
        cardColor = const Color(0xFFE1F5FE).withValues(alpha: 0.4);
        borderColor = const Color(0xFF0277BD).withValues(alpha: 0.4);
        tagColor = const Color(0xFF0277BD);
        tagBg = const Color(0xFFE1F5FE);
        icon = Icons.info_outline_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            OfficerExceptionDetailSheet.show(context, exception: ex);
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 12, color: tagColor),
                          const SizedBox(width: 3),
                          Text(
                            ex.severityLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: tagColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ex.title,
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (ex.status == ExceptionStatus.acknowledged)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE7F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Acknowledged',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5E35B1),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  ex.shortDescription,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (ex.tokenNumber != null || ex.farmerName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (ex.farmerName != null)
                        Text(
                          ex.farmerName!,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (ex.farmerName != null && ex.tokenNumber != null)
                        const Text(' • '),
                      if (ex.tokenNumber != null)
                        Text(
                          'Token: ${ex.tokenNumber}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Action: ${ex.recommendedAction}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: tagColor,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (ex.status == ExceptionStatus.open)
                      InkWell(
                        onTap: () {
                          _service.acknowledgeException(ex.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: const Text(
                            'Acknowledge',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () {
                        _service.resolveException(ex.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Resolve',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiSummarySection({bool isCompact = false}) {
    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operational KPIs',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.calendar_today_rounded,
                  label: "Today's Bookings",
                  value: '${_service.todayBookingsCount}',
                  color: AppColors.primaryGreen,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.how_to_reg_rounded,
                  label: 'Arrived',
                  value: '${_service.arrivedCount}',
                  color: AppColors.secondary,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.hourglass_bottom_rounded,
                  label: 'Waiting',
                  value: '${_service.waitingCount}',
                  color: AppColors.warning,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.task_alt_rounded,
                  label: 'Completed',
                  value: '${_service.completedCount}',
                  color: AppColors.primaryGreen,
                  isCompact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.access_time_rounded,
                  label: 'Average Wait',
                  value: _service.averageWait,
                  color: AppColors.textPrimary,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.speed_rounded,
                  label: 'Processing Rate',
                  value: _service.processingRate,
                  color: AppColors.secondary,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.pie_chart_rounded,
                  label: 'Capacity',
                  value: '${_service.centreCapacityPercent}%',
                  color: _service.centreCapacityPercent > 80
                      ? AppColors.warning
                      : AppColors.primaryGreen,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.timelapse_rounded,
                  label: 'Delay (min)',
                  value: '${_service.centreDelayMinutes} min',
                  color: _service.centreDelayMinutes > 0
                      ? AppColors.warning
                      : AppColors.primaryGreen,
                  isCompact: true,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Operational KPIs',
          style: AppTextStyles.titleMedium,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                icon: Icons.calendar_today_rounded,
                label: "Today's Bookings",
                value: '${_service.todayBookingsCount}',
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.how_to_reg_rounded,
                label: 'Arrived',
                value: '${_service.arrivedCount}',
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.hourglass_bottom_rounded,
                label: 'Waiting',
                value: '${_service.waitingCount}',
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                icon: Icons.task_alt_rounded,
                label: 'Completed',
                value: '${_service.completedCount}',
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.access_time_rounded,
                label: 'Average Wait',
                value: _service.averageWait,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                icon: Icons.speed_rounded,
                label: 'Processing Rate',
                value: _service.processingRate,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.pie_chart_rounded,
                label: 'Capacity',
                value: '${_service.centreCapacityPercent}%',
                color: _service.centreCapacityPercent > 80
                    ? AppColors.warning
                    : AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.timelapse_rounded,
                label: 'Delay (min)',
                value: '${_service.centreDelayMinutes} min',
                color: _service.centreDelayMinutes > 0
                    ? AppColors.warning
                    : AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isCompact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 10 : 12,
        vertical: isCompact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isCompact ? 16 : 18, color: color),
          SizedBox(height: isCompact ? 4 : 6),
          Text(
            value,
            style: TextStyle(
              fontSize: isCompact ? 16 : 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalControlsSection({bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Queue Operations',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isCompact ? 8 : 12),

          if (isCompact) ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OfficerQrScannerScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                      label: const Text(
                        'Scan Farmer QR',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _service.callNextFarmer(),
                      icon: const Icon(Icons.record_voice_over_rounded, size: 20),
                      label: const Text(
                        'Call Next Farmer',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ] else ...[
            // Phase 12: Primary Scan Farmer QR Button (>= 56dp)
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OfficerQrScannerScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                label: const Text(
                  'Scan Farmer QR',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Call Next Farmer Button (>= 56dp)
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _service.callNextFarmer(),
                icon: const Icon(Icons.record_voice_over_rounded, size: 22),
                label: const Text(
                  'Call Next Farmer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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
            const SizedBox(height: 10),
          ],

          // Secondary Quick Controls
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Quick mark next booked farmer arrived
                    final booked = _service.queue
                        .where((q) => q.status == 'Booked')
                        .toList();
                    if (booked.isNotEmpty) {
                      _service.markArrived(booked.first.tokenNumber);
                    }
                  },
                  icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                  label: const Text('Mark Arrived'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final waiting = _service.queue
                        .where((q) => q.status == 'Waiting')
                        .toList();
                    if (waiting.isNotEmpty) {
                      _service.startProcessing(waiting.first.tokenNumber);
                    }
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Start Processing'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveQueueSection() {
    final queue = _service.queue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'LIVE QUEUE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              '${queue.length} Total Registered',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Live Queue Cards List
        Column(
          children: queue.map((farmer) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: farmer.farmerName == 'Ramesh Kumar'
                      ? AppColors.primaryGreen
                      : AppColors.cardBorder,
                  width: farmer.farmerName == 'Ramesh Kumar' ? 2.0 : 1.0,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _openFarmerDetail(farmer.tokenNumber),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      // Token Badge
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Center(
                          child: Text(
                            farmer.tokenNumber.replaceAll('TK-', ''),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Details Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  farmer.tokenNumber,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (farmer.farmerName == 'Ramesh Kumar')
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'FARMER APP',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${farmer.farmerName} • ${farmer.crop} (${farmer.quantity})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  farmer.status == 'Booked'
                                      ? 'Not arrived'
                                      : '${farmer.peopleAhead} ahead',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const Text(' • '),
                                Text(
                                  'Slot: ${farmer.bookedSlot}',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Status & Action
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildQueueStatusPill(farmer.status),
                          const SizedBox(height: 6),
                          Text(
                            farmer.status == 'Completed'
                                ? 'Done'
                                : '~${farmer.approxWaitMinutes} min',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.textTertiary),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQueueStatusPill(String status) {
    Color bg = AppColors.surfaceVariant;
    Color text = AppColors.textPrimary;
    IconData icon = Icons.info_outline_rounded;

    if (status == 'Waiting') {
      bg = AppColors.warning.withValues(alpha: 0.15);
      text = AppColors.warning;
      icon = Icons.hourglass_top_rounded;
    } else if (status == 'Sampling' || status == 'Quality Check') {
      bg = AppColors.secondaryContainer;
      text = AppColors.secondary;
      icon = Icons.science_rounded;
    } else if (status == 'Completed') {
      bg = AppColors.primaryContainer;
      text = AppColors.primaryGreen;
      icon = Icons.check_circle_rounded;
    } else if (status == 'Booked') {
      bg = AppColors.surfaceVariant;
      text = AppColors.textSecondary;
      icon = Icons.event_seat_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: text),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Centre Status & Capacity Control',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Changes instantly update queue velocity and farmer-facing Go-Time advice.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 14),

          // Centre Status Chips
          const Text(
            'Operating Status:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildStatusChoiceChip('Open • Normal'),
              _buildStatusChoiceChip('Open • Busy'),
              _buildStatusChoiceChip('Temporarily Delayed'),
              _buildStatusChoiceChip('Temporarily Stopped'),
            ],
          ),
          const SizedBox(height: 16),

          // Capacity Mode
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Centre Capacity Utilisation:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${_service.centreCapacityPercent}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildCapacityChoiceChip('Normal', 75),
              _buildCapacityChoiceChip('Busy', 85),
              _buildCapacityChoiceChip('High Load', 95),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChoiceChip(String status) {
    final isSelected = _service.centreStatus == status;
    return ChoiceChip(
      label: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: status == 'Temporarily Delayed'
          ? AppColors.error
          : (status == 'Open • Busy'
              ? AppColors.warning
              : AppColors.primaryGreen),
      backgroundColor: AppColors.surfaceVariant,
      onSelected: (_) => _service.setCentreStatus(status),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildCapacityChoiceChip(String mode, int percent) {
    final isSelected = _service.capacityMode == mode;
    return ChoiceChip(
      label: Text(
        '$mode ($percent%)',
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.secondary,
      backgroundColor: AppColors.surfaceVariant,
      onSelected: (_) => _service.setCapacityMode(mode),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildSlotManagementSection() {
    final slots = _service.slots;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Slots",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${slots.length} Active Windows',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: slots.map((slot) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded,
                        size: 18, color: AppColors.secondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slot.time,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${slot.bookingsCount} bookings • Capacity: ${slot.capacity} • Tag: ${slot.recommendationTag}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showAdjustSlotCapacityDialog(slot),
                      child: const Text(
                        'Adjust Slot Capacity',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotReallocationSection() {
    final recommendations = _service.slotReallocations;
    final pendingCount = _service.pendingSlotReallocationsCount;

    return Container(
      key: const Key('officer_slot_reallocation_section'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pendingCount > 0
              ? AppColors.warning.withValues(alpha: 0.6)
              : AppColors.cardBorder,
          width: pendingCount > 0 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: pendingCount > 0
                ? AppColors.warning.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: pendingCount > 0
                      ? AppColors.warningContainer
                      : AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  pendingCount > 0
                      ? Icons.swap_horiz_rounded
                      : Icons.schedule_rounded,
                  size: 18,
                  color: pendingCount > 0
                      ? AppColors.warning
                      : AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Slot Reallocation',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pendingCount > 0
                      ? AppColors.warningContainer
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: pendingCount > 0
                        ? AppColors.warning.withValues(alpha: 0.5)
                        : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  pendingCount > 0
                      ? '$pendingCount Recommended'
                      : 'No Actions Needed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: pendingCount > 0
                        ? AppColors.warning
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (recommendations.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 16, color: AppColors.primaryGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Centre load and queues are normal. No upcoming booking reallocations recommended.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: recommendations.map((rec) {
                return _buildReallocationCard(rec);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildReallocationCard(SlotReallocationRecommendation rec) {
    return Container(
      key: Key('card_reallocation_${rec.tokenNumber}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rec.isPending
              ? AppColors.warning.withValues(alpha: 0.4)
              : (rec.isReallocated
                  ? AppColors.primaryGreen.withValues(alpha: 0.4)
                  : AppColors.cardBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Farmer & Token Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    rec.tokenNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    rec.farmerName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: rec.isPending
                      ? AppColors.warningContainer
                      : (rec.isReallocated
                          ? AppColors.primaryContainer
                          : AppColors.surfaceVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  rec.isPending
                      ? 'Recommended'
                      : (rec.isReallocated ? 'Reallocated' : 'Dismissed'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: rec.isPending
                        ? AppColors.warning
                        : (rec.isReallocated
                            ? AppColors.primaryGreen
                            : AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${rec.crop} • ${rec.quantity}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const Divider(height: 16, thickness: 0.8),

          // Current Slot -> Recommended New Slot
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Slot',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rec.currentSlot,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended Slot',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rec.recommendedSlot,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Reason Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    rec.reasonEn,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Action buttons
          if (rec.isPending)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  key: Key('btn_dismiss_realloc_${rec.tokenNumber}'),
                  onPressed: () {
                    SlotReallocationService().dismissRecommendation(rec.id);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  key: Key('btn_confirm_realloc_${rec.tokenNumber}'),
                  icon: const Icon(Icons.check_rounded, size: 14),
                  label: const Text(
                    'Confirm Reallocation',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    final ok = SlotReallocationService().confirmReallocation(
                      recommendationId: rec.id,
                      stateService: _service,
                    );
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Reallocated ${rec.tokenNumber} to ${rec.recommendedSlot}. Farmer notified.',
                          ),
                          backgroundColor: AppColors.primaryGreen,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            )
          else if (rec.isReallocated)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: AppColors.primaryGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Reallocated to ${rec.recommendedSlot}. Farmer notified.',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAlternativeCentresSection() {
    final alternatives = _service.alternativeCentres;
    final isBusy = _service.isCurrentCentreOverloadedOrDelayed;

    return Container(
      key: const Key('officer_alternative_centres_section'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isBusy ? const Color(0xFFFFB74D) : AppColors.cardBorder,
          width: isBusy ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.share_location_rounded,
                    color: Color(0xFF1B5E20), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Catchment Alternative Centres',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      isBusy
                          ? 'Active advisory: High load detected at this centre'
                          : 'Advisory options for farmers in catchment area',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isBusy ? Colors.deepOrange : AppColors.textSecondary,
                        fontWeight:
                            isBusy ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE7F6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD1C4E9)),
                ),
                child: const Text(
                  'Farmer Choice Only',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF512DA8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBE7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE6EE9C)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: Color(0xFF827717)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Procurement Policy: Officers do not automatically transfer farmers across centres. These alternatives are recommended to farmers for self-selected transfer.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF558B2F)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (alternatives.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No alternative centres available in current catchment.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          else
            ...alternatives.map((rec) => _buildOfficerAlternativeCard(rec)),
        ],
      ),
    );
  }

  Widget _buildOfficerAlternativeCard(AlternativeCentreRecommendation rec) {
    return Container(
      key: Key('officer_alt_card_${rec.centre.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rec.isTopPick ? const Color(0xFFF1F8E9) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              rec.isTopPick ? const Color(0xFFA5D6A7) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rec.centre.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ),
              if (rec.isTopPick)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Top Alternative',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                '${rec.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1565C0),
                ),
              ),
              Text('•',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              Text(
                '${rec.estimatedWaitMinutes} min wait',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: rec.estimatedWaitMinutes <= 20
                      ? const Color(0xFF2E7D32)
                      : Colors.deepOrange,
                ),
              ),
              Text('•',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              Text(
                '${rec.capacityPercent}% load',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5D4037),
                ),
              ),
              Text('•',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              Text(
                'Next: ${rec.nextAvailableSlot}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4527A0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCapacityForecastSection() {
    final summary = _service.capacityForecastSummary;
    final isCritical =
        summary.peakCongestionLevel == CapacityCongestionLevel.critical;
    final isHigh =
        summary.peakCongestionLevel == CapacityCongestionLevel.highRisk;

    return Container(
      key: const Key('officer_capacity_forecast_section'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical
              ? const Color(0xFFC62828)
              : (isHigh ? const Color(0xFFE65100) : AppColors.cardBorder),
          width: (isCritical || isHigh) ? 1.8 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCritical
                      ? const Color(0xFFFFEBEE)
                      : (isHigh
                          ? const Color(0xFFFBE9E7)
                          : const Color(0xFFE8F5E9)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: summary.peakCongestionLevel.color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Capacity Forecast & Risk',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Current Load: ${_service.centreCapacityPercent}% • Peak Risk: ${summary.peakRiskTime}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: summary.peakCongestionLevel.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: summary.peakCongestionLevel.color,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  summary.peakCongestionLevel.nameEn.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: summary.peakCongestionLevel.color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Forecast Timeline Horizontal Cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: summary.forecasts
                  .map((f) => _buildForecastTimelineCard(f))
                  .toList(),
            ),
          ),

          const SizedBox(height: 14),

          // Recommended Officer Interventions Callout
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: summary.peakCongestionLevel.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: summary.peakCongestionLevel.color
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: summary.peakCongestionLevel.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Recommended Officer Interventions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: summary.peakCongestionLevel.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  summary.overallRecommendedAction,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastTimelineCard(CapacityForecastModel f) {
    return Container(
      key: Key('card_forecast_${f.window.name}'),
      width: 195,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: f.congestionLevel.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: f.congestionLevel.color.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time & Window
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  f.predictedTime,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: f.congestionLevel.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: f.congestionLevel.color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  f.congestionLevel.nameEn,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            f.windowLabel,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Load & Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Load', style: TextStyle(fontSize: 11)),
              Text(
                '${f.predictedLoadPercent}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: f.congestionLevel.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (f.predictedLoadPercent / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              valueColor:
                  AlwaysStoppedAnimation<Color>(f.congestionLevel.color),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 8),

          // Queue & Wait Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Queue: ~${f.predictedQueueCount}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Wait: ~${f.estimatedWaitMinutes}m',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            f.confidenceBasis,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade700,
              height: 1.2,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
