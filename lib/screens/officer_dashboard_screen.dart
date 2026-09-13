import 'package:flutter/material.dart';
import '../config/supabase_config.dart';
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
import 'officer_centre_admin_screen.dart';
import 'officer_dispute_console_screen.dart';
import 'officer_farmer_detail_screen.dart';
import 'officer_payment_oversight_screen.dart';
import 'officer_qr_scanner_screen.dart';
import 'role_selection_screen.dart';

/// Phase 7 & Phase A: KisanSetu Procurement Officer Operations Dashboard.
///
/// Designed with INFORMATION → DECIDE → CONTROL operational philosophy:
/// - Real-time operational header with centre status, live load, and date.
/// - Comprehensive 11-metric operational KPI summary grid.
/// - 8 Core Operational Action Areas (Command Center).
/// - Interactive Live Queue list with instant stage inspection.
/// - Call Next Farmer and queue operational actions.
/// - Real-time Centre Status & Capacity controls.
/// - Slot capacity management section.
class OfficerDashboardScreen extends StatefulWidget {
  final String officerId;
  final String? centreId;

  const OfficerDashboardScreen({
    super.key,
    required this.officerId,
    this.centreId,
  });

  @override
  State<OfficerDashboardScreen> createState() => _OfficerDashboardScreenState();
}

class _OfficerDashboardScreenState extends State<OfficerDashboardScreen> {
  final _service = ProcurementStateService();
  final GlobalKey _liveQueueKey = GlobalKey();
  bool _isActionExecuting = false;

  bool _verifyOfficerAuthorization([String? targetCentreId]) {
    final authCentreId = AuthService.instance.currentCentreId;
    final activeCentreId =
        widget.centreId ?? '11111111-1111-1111-1111-111111111111';

    if (authCentreId != null && authCentreId != activeCentreId) {
      _showAccessRestrictedDialog();
      return false;
    }
    if (targetCentreId != null &&
        authCentreId != null &&
        targetCentreId != authCentreId) {
      _showAccessRestrictedDialog();
      return false;
    }
    return true;
  }

  void _showAccessRestrictedDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.gpp_bad_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Access Restricted'),
          ],
        ),
        content: const Text(
          'You are not authorized to modify this procurement centre.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScanFarmerQr() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OfficerQrScannerScreen(),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleCallNextFarmer() async {
    if (_isActionExecuting) return;
    if (!_verifyOfficerAuthorization()) return;

    final eligible = _service.queue.where((q) {
      final s = q.status;
      return (s == 'Waiting' ||
          s == 'Arrived' ||
          (s == 'Booked' && q.checkInStatus == 'Checked In'));
    }).toList();

    if (eligible.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No eligible farmer is currently waiting.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final nextFarmer = eligible.first;
    final queuePosition = eligible.indexOf(nextFarmer) + 1;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.record_voice_over_rounded, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Call next farmer?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Farmer:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary),
            ),
            Text(
              nextFarmer.farmerName,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Token:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary),
            ),
            Text(
              nextFarmer.tokenNumber,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.primaryDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Queue position:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary),
            ),
            Text(
              '$queuePosition',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.primaryGreen),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('CALL FARMER'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isActionExecuting = true);
      try {
        _service.callNextFarmer();
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Calling farmer: ${nextFarmer.farmerName} (${nextFarmer.tokenNumber})'),
              backgroundColor: AppColors.primaryGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isActionExecuting = false);
        }
      }
    }
  }

  Future<void> _handleMarkArrived() async {
    if (_isActionExecuting) return;
    if (!_verifyOfficerAuthorization()) return;

    final unarrived = _service.queue.where((q) {
      return q.status == 'Booked' || q.checkInStatus != 'Checked In';
    }).toList();

    if (unarrived.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending arrival found.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    String selectedToken = unarrived.first.tokenNumber;

    final confirmedToken = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.how_to_reg_rounded, color: AppColors.secondary),
                  SizedBox(width: 8),
                  Text('Mark Farmer Arrived'),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primaryContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                AppColors.primaryGreen.withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: AppColors.primaryGreen),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Use Scan Farmer QR for QR-based check-in.',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Select Farmer / Token for Manual Arrival:',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: unarrived.length,
                        itemBuilder: (context, index) {
                          final f = unarrived[index];
                          final isSel = f.tokenNumber == selectedToken;
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSel
                                    ? AppColors.primaryGreen
                                    : AppColors.cardBorder,
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            tileColor: isSel
                                ? AppColors.primaryContainer
                                    .withValues(alpha: 0.2)
                                : null,
                            leading: Icon(
                              isSel
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: isSel
                                  ? AppColors.primaryGreen
                                  : AppColors.textTertiary,
                            ),
                            title: Text(
                              '${f.farmerName} (${f.tokenNumber})',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            subtitle: Text(
                              '${f.crop} • ${f.quantity} • Slot: ${f.bookedSlot}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () {
                              setDialogState(() {
                                selectedToken = f.tokenNumber;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(selectedToken),
                  child: const Text('MARK ARRIVED'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmedToken != null) {
      setState(() => _isActionExecuting = true);
      try {
        final farmer =
            unarrived.firstWhere((q) => q.tokenNumber == confirmedToken);
        _service.markArrived(confirmedToken);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Farmer ${farmer.farmerName} (${farmer.tokenNumber}) marked arrived.'),
              backgroundColor: AppColors.primaryGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isActionExecuting = false);
        }
      }
    }
  }

  Future<void> _handleStartProcessing() async {
    if (_isActionExecuting) return;
    if (!_verifyOfficerAuthorization()) return;

    final ready = _service.queue.where((q) {
      final s = q.status;
      return (s == 'Waiting' ||
          s == 'Arrived' ||
          (s == 'Booked' && q.checkInStatus == 'Checked In'));
    }).toList();

    if (ready.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No eligible farmer is ready for processing.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final farmer = ready.first;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.play_circle_filled_rounded,
                color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Start procurement processing?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Farmer:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary),
            ),
            Text(
              farmer.farmerName,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Token:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary),
            ),
            Text(
              farmer.tokenNumber,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.primaryDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crop:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary),
            ),
            Text(
              farmer.crop,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quantity:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textSecondary),
            ),
            Text(
              farmer.quantity,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('START PROCESSING'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isActionExecuting = true);
      try {
        _service.startProcurement(farmer.tokenNumber);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Procurement started for ${farmer.farmerName} (${farmer.tokenNumber}).'),
              backgroundColor: AppColors.primaryGreen,
              duration: const Duration(seconds: 3),
            ),
          );
          _openFarmerDetail(farmer.tokenNumber);
        }
      } finally {
        if (mounted) {
          setState(() => _isActionExecuting = false);
        }
      }
    }
  }

  void _handleAcknowledgeAlert(OfficerExceptionModel ex) {
    if (!_verifyOfficerAuthorization()) return;
    _service.acknowledgeException(ex.id);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alert acknowledged.'),
        backgroundColor: AppColors.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
    setState(() {});
  }

  Future<void> _handleResolveAlert(OfficerExceptionModel ex) async {
    if (!_verifyOfficerAuthorization()) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resolve Exception?'),
        content: Text(
          'Confirm resolution of "${ex.title}"?\nThis will mark the exception resolved and update the dashboard counts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final officerId = widget.officerId.isNotEmpty
          ? widget.officerId
          : (AuthService.instance.currentUserId ?? 'OFF-101');
      _service.resolveException(ex.id, officerId: officerId);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exception resolved.'),
            backgroundColor: AppColors.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
        setState(() {});
      }
    }
  }

  Future<void> _handleCentreStatusChange(String status) async {
    if (!_verifyOfficerAuthorization()) return;

    if (status == 'Temporarily Stopped') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error),
              SizedBox(width: 8),
              Text('Temporarily Stop Centre?'),
            ],
          ),
          content: const Text(
            'New arrivals and processing may be affected.\n\nAre you sure you want to stop centre intake temporarily?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('CONFIRM STOP'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    _service.setCentreStatus(status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Centre status updated: $status'),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() {});
  }

  Future<void> _handleUpdateDailyCapacity() async {
    if (!_verifyOfficerAuthorization()) return;
    final controller =
        TextEditingController(text: _service.centreCapacity.toString());
    final newCap = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Daily Capacity'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Capacity (Farmers/day)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                Navigator.of(ctx).pop(val);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (newCap != null && newCap > 0) {
      final oldCap = _service.centreCapacity;
      _service.updateCentreParameters(capacity: newCap);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Daily Capacity updated: $oldCap → $newCap Farmers/day'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() {});
    }
  }

  Future<void> _handleUpdateProcessingRate() async {
    if (!_verifyOfficerAuthorization()) return;
    final controller = TextEditingController(
        text: _service.configuredProcessingRate.toString());
    final newRate = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Processing Rate'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hourly Rate (Qtl/hr)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                Navigator.of(ctx).pop(val);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (newRate != null && newRate > 0) {
      final oldRate = _service.configuredProcessingRate;
      _service.updateCentreParameters(processingRatePerHour: newRate);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Processing Rate: $oldRate Qtl/hr → $newRate Qtl/hr. Queue and Go-Time recommendations updated.'),
          backgroundColor: AppColors.primaryGreen,
          duration: const Duration(seconds: 3),
        ),
      );
      setState(() {});
    }
  }

  void _showVoiceGuidance() {
    final text =
        'Procurement Operations Dashboard. Centre: ${_service.centreName}. Status: ${_service.centreStatus}. ${_service.todayBookingsCount} bookings today, ${_service.waitingCount} waiting in queue, ${_service.paymentPendingCount} payments pending DBT authorization. Access the 8 action areas below to manage gate check-in, intake, slots, and payout approvals.';
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

  void _showOfficerPaymentsDialog() {
    final queue = _service.queue;
    final pendingPayments =
        queue.where((q) => q.paymentStatus == 'Pending').toList();
    final totalPendingAmount = pendingPayments.fold<double>(
        0.0, (acc, item) => acc + item.netPayable);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payments_rounded,
                    color: AppColors.secondary, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('DBT Payments & Settlements',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              AppColors.primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Pending Clearance',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                  '₹${totalPendingAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primaryGreen)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.warningContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                              '${pendingPayments.length} Pending DBT',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.warning)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Farmer Disbursement Roster',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  ...queue.map((item) {
                    final isPending = item.paymentStatus == 'Pending';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${item.farmerName} (${item.tokenNumber})',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                                Text(
                                    'Net: ₹${item.netPayable.toStringAsFixed(2)} • Ref: ${item.paymentReference}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPending
                                  ? AppColors.warningContainer
                                  : AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isPending ? 'Pending' : 'Completed',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isPending
                                    ? AppColors.warning
                                    : AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OfficerPaymentOversightScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Full Oversight Console'),
            ),
            if (pendingPayments.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  for (final p in pendingPayments) {
                    _service.markPaymentCompleted(p.tokenNumber);
                  }
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Authorized and dispatched ${pendingPayments.length} DBT payment settlements.'),
                      backgroundColor: AppColors.primaryGreen,
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text('Authorize DBT Batch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        );
      },
    );
  }

  void _showOfficerAnalyticsDialog() {
    final summary = _service.capacityForecastSummary;
    final queue = _service.queue;
    final totalVolumeQuintals = queue.fold<double>(
      0.0,
      (acc, item) =>
          acc +
          (double.tryParse(item.actualQuantity
                  .replaceAll(RegExp(r'[^0-9.]'), '')) ??
              0.0),
    );

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insights_rounded,
                    color: AppColors.secondary, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Procurement Analytics & Forecast',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsMetricCard(
                          title: "Today's Intake",
                          value:
                              '${totalVolumeQuintals.toStringAsFixed(1)} Qtl',
                          icon: Icons.scale_rounded,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAnalyticsMetricCard(
                          title: 'Processing Rate',
                          value: _service.processingRate,
                          icon: Icons.speed_rounded,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsMetricCard(
                          title: 'Centre Load',
                          value: '${_service.centreCapacityPercent}%',
                          icon: Icons.pie_chart_rounded,
                          color: _service.centreCapacityPercent > 80
                              ? AppColors.warning
                              : AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAnalyticsMetricCard(
                          title: '2-Hr Risk Forecast',
                          value: summary.peakCongestionLevel.nameEn.toUpperCase(),
                          icon: Icons.trending_up_rounded,
                          color: summary.hasHighOrCriticalRisk
                              ? AppColors.error
                              : AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Intake Hourly Windows & Bottlenecks',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...summary.forecasts.take(4).map((f) {
                    final isHighRisk = f.congestionLevel == CapacityCongestionLevel.highRisk ||
                        f.congestionLevel == CapacityCongestionLevel.critical;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(f.windowLabel,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                          Text(
                              'Load: ${f.predictedLoadPercent}% • Risk: ${f.congestionLevel.nameEn}',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isHighRisk
                                      ? AppColors.error
                                      : AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showOfficerProfileDialog() {
    final centreId = widget.centreId ??
        AuthService.instance.currentCentreId ??
        '11111111-1111-1111-1111-111111111111';

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.badge_rounded,
                    color: AppColors.secondary, size: 22),
              ),
              const SizedBox(width: 10),
              const Text('Officer Credentials',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileRow('Officer ID', widget.officerId),
              _buildProfileRow('Designation',
                  'Procurement Officer (Intake Inspector)'),
              _buildProfileRow('Assigned Centre', _service.centreName),
              _buildProfileRow('Centre UUID', centreId),
              _buildProfileRow(
                  'Security Role', 'RLS Role: officer (Verified)'),
              _buildProfileRow(
                  'Authentication',
                  SupabaseConfig.shouldUseSupabase
                      ? 'Supabase Auth Session'
                      : 'Local Prototype Mode'),
              _buildProfileRow('Operating Status', _service.centreStatus),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color:
                          AppColors.primaryGreen.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded,
                        color: AppColors.primaryGreen, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Authorized to validate gate QR passes, certify produce quality, and approve MSP DBT payouts.',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Dismiss'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSlotManagementModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Dock Slot Management',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Configure procurement capacity windows to manage arrival velocities and avoid gate congestion.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  _buildSlotManagementSection(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticsMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
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
                  tooltip: 'Officer Profile',
                  icon: const Icon(
                    Icons.account_circle_rounded,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                  onPressed: _showOfficerProfileDialog,
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

                            // 2. Action Areas (8 Control Entry Points)
                            _buildActionAreasSection(isCompact: true),
                            const SizedBox(height: 12),

                            // 3. High-Density Horizontal KPI Row
                            _buildKpiSummarySection(isCompact: true),
                            const SizedBox(height: 16),

                            // 4. Two-Column Command Operations Layout
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
                      const SizedBox(height: 14),

                      // 2. Action Areas (8 Control Entry Points)
                      _buildActionAreasSection(),
                      const SizedBox(height: 16),

                      // Phase 14: "Needs Attention" Priority Exception Panel
                      _buildNeedsAttentionSection(),
                      const SizedBox(height: 16),

                      // 3. KPI Summary Cards Grid
                      _buildKpiSummarySection(),
                      const SizedBox(height: 20),

                      // 4. Primary Operational Actions Toolbar
                      _buildOperationalControlsSection(),
                      const SizedBox(height: 22),

                      // 5. Live Queue Table/List
                      _buildLiveQueueSection(),
                      const SizedBox(height: 22),

                      // 6. Centre Status & Capacity Control
                      _buildControlsSection(),
                      const SizedBox(height: 22),

                      // 7. Slot Management Section
                      _buildSlotManagementSection(),
                      const SizedBox(height: 20),

                      // 8. Dynamic Slot Reallocation Section
                      _buildSlotReallocationSection(),
                      const SizedBox(height: 20),

                      // 9. Catchment Alternative Centres Section
                      _buildAlternativeCentresSection(),
                      const SizedBox(height: 20),

                      // 10. Capacity Forecast Section
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
    Color bg = AppColors.primaryContainer.withValues(alpha: 0.5);
    Color border = AppColors.primaryGreen;
    Color statusColor = AppColors.primaryGreen;
    Color statusBg = AppColors.primaryContainer;
    IconData statusIcon = Icons.check_circle_rounded;
    String statusLabel = 'Normal / Open';
    String statusDesc = 'Dock Operations Active • Regular Intake';

    final status = _service.centreStatus;
    if (status.contains('Delayed') || status == 'Open • Busy') {
      bg = AppColors.warningContainer.withValues(alpha: 0.35);
      border = AppColors.warning;
      statusColor = AppColors.warning;
      statusBg = AppColors.warningContainer;
      statusIcon = Icons.hourglass_top_rounded;
      final delay = _service.centreDelayMinutes > 0
          ? _service.centreDelayMinutes
          : 15;
      statusLabel = 'Delayed (+$delay min)';
      statusDesc = 'Heavy Dock Traffic • Queue Velocity Reduced';
    } else if (status.contains('Stopped')) {
      bg = AppColors.errorContainer.withValues(alpha: 0.35);
      border = AppColors.error;
      statusColor = AppColors.error;
      statusBg = AppColors.errorContainer;
      statusIcon = Icons.pause_circle_filled_rounded;
      statusLabel = 'Temporarily Stopped';
      statusDesc = 'Dock Halted • Inspection or Weather Halt';
    }

    final centreId = widget.centreId ??
        AuthService.instance.currentCentreId ??
        '11111111-1111-1111-1111-111111111111';

    return Container(
      key: const Key('officer_centre_status_banner'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.6),
        boxShadow: [
          BoxShadow(
            color: border.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Centre Identity & Operating Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border.withValues(alpha: 0.4)),
                ),
                child: Icon(
                  Icons.warehouse_rounded,
                  color: statusColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _service.centreName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Text(
                            'UUID: ${centreId.length > 8 ? centreId.substring(0, 8) : centreId}...',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Operating Status: ${_service.centreStatus} • Capacity: ${_service.centreCapacityPercent}% (${_service.capacityMode})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusDesc,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: statusColor.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge with explicit Icon + Text (Tap to Administer Centre)
              Tooltip(
                message: 'Manage Centre Status & Operations',
                child: InkWell(
                  key: const Key('banner_centre_admin_btn'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OfficerCentreAdminScreen(
                          officerId: widget.officerId,
                          centreId: widget.centreId,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.tune_rounded, size: 13, color: statusColor),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Operational Indicators: Load %, Processing Rate, Queue Size, Estimated Wait
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildBannerStatPill(
                icon: Icons.pie_chart_rounded,
                label: 'Current Load',
                value: '${_service.centreCapacityPercent}%',
                color: _service.centreCapacityPercent > 80
                    ? AppColors.warning
                    : AppColors.primaryGreen,
              ),
              _buildBannerStatPill(
                icon: Icons.speed_rounded,
                label: 'Processing Rate',
                value: _service.processingRate,
                color: AppColors.secondary,
              ),
              _buildBannerStatPill(
                icon: Icons.people_alt_rounded,
                label: 'Queue Size',
                value: '${_service.waitingCount} in Queue',
                color: AppColors.warning,
              ),
              _buildBannerStatPill(
                icon: Icons.access_time_rounded,
                label: 'Estimated Wait',
                value: _service.averageWait,
                color: AppColors.textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Visual Load Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value:
                        (_service.centreCapacityPercent / 100).clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: Colors.black.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _service.centreCapacityPercent > 85
                          ? AppColors.error
                          : (_service.centreCapacityPercent > 70
                              ? AppColors.warning
                              : AppColors.primaryGreen),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_service.centreCapacityPercent}% (${_service.capacityMode})',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStatPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionAreasSection({bool isCompact = false}) {
    final actions = [
      _ActionItem(
        key: const Key('action_live_queue'),
        icon: Icons.groups_rounded,
        title: 'Live Queue',
        subtitle: '${_service.waitingCount} Waiting',
        color: AppColors.secondary,
        onTap: () {
          final contextToScroll = _liveQueueKey.currentContext;
          if (contextToScroll != null) {
            Scrollable.ensureVisible(
              contextToScroll,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            );
          }
        },
      ),
      _ActionItem(
        key: const Key('action_qr_checkin'),
        icon: Icons.qr_code_scanner_rounded,
        title: 'Gate QR Check-In',
        subtitle: 'Camera Scanner',
        color: AppColors.primaryGreen,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OfficerQrScannerScreen(),
            ),
          );
        },
      ),
      _ActionItem(
        key: const Key('action_procurement'),
        icon: Icons.scale_rounded,
        title: 'Procurement',
        subtitle: 'Produce & Weighment',
        color: AppColors.primaryDark,
        onTap: () {
          final active = _service.queue
              .where((q) => q.status != 'Completed')
              .toList();
          if (active.isNotEmpty) {
            _openFarmerDetail(active.first.tokenNumber);
          } else if (_service.queue.isNotEmpty) {
            _openFarmerDetail(_service.queue.first.tokenNumber);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('No active farmers in queue for procurement.')),
            );
          }
        },
      ),
      _ActionItem(
        key: const Key('action_slots'),
        icon: Icons.calendar_month_rounded,
        title: 'Slot Management',
        subtitle: '${_service.slots.length} Windows Active',
        color: const Color(0xFF5E35B1),
        onTap: _showSlotManagementModal,
      ),
      _ActionItem(
        key: const Key('action_alerts'),
        icon: Icons.notification_important_rounded,
        title: 'Alerts & Exceptions',
        subtitle: '${_service.openExceptionCount} Active Alerts',
        color: _service.criticalExceptionCount > 0
            ? AppColors.error
            : (_service.openExceptionCount > 0
                ? AppColors.warning
                : AppColors.primaryGreen),
        onTap: () {
          final openEx = _service.exceptions
              .where((e) => e.status != ExceptionStatus.resolved)
              .toList();
          if (openEx.isNotEmpty) {
            OfficerExceptionDetailSheet.show(context, exception: openEx.first);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'No active critical exceptions. Centre operating normally.')),
            );
          }
        },
      ),
      _ActionItem(
        key: const Key('action_disputes'),
        icon: Icons.gavel_rounded,
        title: 'Disputes',
        subtitle: '${_service.disputes.where((d) => d.isActive).length} Active',
        color: const Color(0xFFD84315),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OfficerDisputeConsoleScreen(),
            ),
          );
        },
      ),
      _ActionItem(
        key: const Key('action_payments'),
        icon: Icons.payments_rounded,
        title: 'Payments',
        subtitle: '${_service.paymentPendingCount} Pending DBT',
        color: const Color(0xFF00897B),
        onTap: _showOfficerPaymentsDialog,
      ),
      _ActionItem(
        key: const Key('action_centre_admin'),
        icon: Icons.tune_rounded,
        title: 'Centre Admin',
        subtitle: 'Status & Capacity',
        color: AppColors.secondary,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OfficerCentreAdminScreen(
                officerId: widget.officerId,
                centreId: widget.centreId,
              ),
            ),
          );
        },
      ),
      _ActionItem(
        key: const Key('action_analytics'),
        icon: Icons.insights_rounded,
        title: 'Analytics',
        subtitle: 'Intake & Velocity',
        color: const Color(0xFF3949AB),
        onTap: _showOfficerAnalyticsDialog,
      ),
      _ActionItem(
        key: const Key('action_profile'),
        icon: Icons.account_circle_rounded,
        title: 'Officer Profile',
        subtitle: widget.officerId,
        color: AppColors.textPrimary,
        onTap: _showOfficerProfileDialog,
      ),
    ];

    return Container(
      key: const Key('officer_action_areas_section'),
      padding: EdgeInsets.all(isCompact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.dashboard_customize_rounded,
                      size: 18, color: AppColors.secondary),
                  SizedBox(width: 8),
                  Text(
                    'Operations Command Center',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${actions.length} Control Areas',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 10 : 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = isCompact
                  ? 5
                  : (constraints.maxWidth > 850
                      ? 5
                      : (constraints.maxWidth > 500 ? 3 : 2));
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: isCompact
                      ? 2.3
                      : (constraints.maxWidth > 650 ? 2.2 : 2.0),
                ),
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return Material(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      key: action.key,
                      onTap: action.onTap,
                      borderRadius: BorderRadius.circular(12),
                      hoverColor: action.color.withValues(alpha: 0.08),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: action.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(action.icon,
                                  size: 20, color: action.color),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    action.title,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    action.subtitle,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: action.color,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
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
      case ExceptionSeverity.high:
      case ExceptionSeverity.warning:
        cardColor = AppColors.warningContainer.withValues(alpha: 0.25);
        borderColor = AppColors.warning.withValues(alpha: 0.5);
        tagColor = AppColors.warning;
        tagBg = AppColors.warningContainer;
        icon = Icons.warning_amber_rounded;
        break;
      case ExceptionSeverity.medium:
        cardColor = const Color(0xFFFFF8E1).withValues(alpha: 0.5);
        borderColor = const Color(0xFFFFB300).withValues(alpha: 0.5);
        tagColor = const Color(0xFFF57F17);
        tagBg = const Color(0xFFFFF8E1);
        icon = Icons.info_rounded;
        break;
      case ExceptionSeverity.low:
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
                            ex.severityTag,
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
                    InkWell(
                      key: Key('btn_view_ex_${ex.id}'),
                      onTap: () {
                        OfficerExceptionDetailSheet.show(context,
                                exception: ex)
                            .then((_) {
                          if (mounted) setState(() {});
                        });
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
                          'View',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (ex.status == ExceptionStatus.open)
                      InkWell(
                        key: Key('btn_ack_ex_${ex.id}'),
                        onTap: () => _handleAcknowledgeAlert(ex),
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
                    if (ex.status != ExceptionStatus.resolved)
                      InkWell(
                        key: Key('btn_resolve_ex_${ex.id}'),
                        onTap: () => _handleResolveAlert(ex),
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.payments_rounded,
                  label: 'Payment Pending',
                  value: '${_service.paymentPendingCount}',
                  color: AppColors.warning,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.notification_important_rounded,
                  label: 'Active Alerts',
                  value: '${_service.openExceptionCount}',
                  color: _service.openExceptionCount > 0
                      ? AppColors.error
                      : AppColors.primaryGreen,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.calendar_month_rounded,
                  label: 'Active Slots',
                  value: '${_service.slots.length}',
                  color: AppColors.secondary,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.people_alt_rounded,
                  label: 'Queue Size',
                  value: '${_service.queue.length}',
                  color: AppColors.textPrimary,
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
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                icon: Icons.payments_rounded,
                label: 'Payment Pending',
                value: '${_service.paymentPendingCount}',
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.notification_important_rounded,
                label: 'Active Alerts',
                value: '${_service.openExceptionCount}',
                color: _service.openExceptionCount > 0
                    ? AppColors.error
                    : AppColors.primaryGreen,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.calendar_month_rounded,
                label: 'Active Slots',
                value: '${_service.slots.length}',
                color: AppColors.secondary,
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
                      onPressed: _handleScanFarmerQr,
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
                      onPressed: _handleCallNextFarmer,
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
                onPressed: _handleScanFarmerQr,
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
                onPressed: _handleCallNextFarmer,
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
                  onPressed: _handleMarkArrived,
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
                  onPressed: _handleStartProcessing,
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
      key: _liveQueueKey,
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
                onTap: () {
                  _openFarmerDetail(farmer.tokenNumber);
                },
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                                          borderRadius:
                                              BorderRadius.circular(6),
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

                      // Action Button Row for Phase C Procurement
                      if (farmer.status == 'Waiting' ||
                          farmer.status == 'Arrived' ||
                          farmer.status == 'Sampling' ||
                          farmer.status == 'Quality Check' ||
                          farmer.status == 'Weighment') ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onPressed: () {
                              _service.startProcurement(farmer.tokenNumber);
                              _openFarmerDetail(farmer.tokenNumber);
                            },
                            icon: const Icon(
                                Icons.play_circle_filled_rounded,
                                size: 16),
                            label: Text(
                              farmer.status == 'Waiting' ||
                                      farmer.status == 'Arrived'
                                  ? 'START PROCUREMENT'
                                  : 'RESUME PROCUREMENT',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ] else if (farmer.status == 'Booked') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 13, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Awaiting gate QR check-in before procurement can begin',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textTertiary,
                                  fontSize: 10.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else if (farmer.status == 'Accepted' ||
                          farmer.status == 'Completed') ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified_rounded,
                                    size: 14, color: AppColors.primaryGreen),
                                const SizedBox(width: 4),
                                Text(
                                  farmer.status == 'Accepted'
                                      ? 'Procurement Accepted • Payout ${farmer.paymentStatus}'
                                      : 'Procurement Completed',
                                  style: const TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () =>
                                  _openFarmerDetail(farmer.tokenNumber),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'VIEW RECEIPT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Daily Capacity & Hourly Processing Rate Controls
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Capacity',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_service.centreCapacity} / day',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          InkWell(
                            key: const Key('btn_edit_daily_capacity'),
                            onTap: _handleUpdateDailyCapacity,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'EDIT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGreen,
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
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Processing Rate',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_service.configuredProcessingRate} Qtl/hr',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          InkWell(
                            key: const Key('btn_edit_processing_rate'),
                            onTap: _handleUpdateProcessingRate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'EDIT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChoiceChip(String status) {
    final isSelected = _service.centreStatus == status;
    return ChoiceChip(
      key: Key('chip_status_${status.replaceAll(' ', '_').replaceAll('•', '')}'),
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
              : (status == 'Temporarily Stopped'
                  ? const Color(0xFFC62828)
                  : AppColors.primaryGreen)),
      backgroundColor: AppColors.surfaceVariant,
      onSelected: (_) => _handleCentreStatusChange(status),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildCapacityChoiceChip(String mode, int percent) {
    final isSelected = _service.capacityMode == mode;
    return ChoiceChip(
      key: Key('chip_capacity_$mode'),
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
      onSelected: (_) {
        if (!_verifyOfficerAuthorization()) return;
        _service.setCapacityMode(mode);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capacity mode set to $mode ($percent%)'),
            backgroundColor: AppColors.primaryGreen,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {});
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildSlotManagementSection() {
    final slots = _service.slots;

    // Detect overloaded slots and available target slots for recommendation
    ProcurementSlotInfo? overloadedSlot;
    ProcurementSlotInfo? targetAvailableSlot;
    for (final s in slots) {
      if (s.isOverloaded && overloadedSlot == null) {
        overloadedSlot = s;
      } else if (overloadedSlot != null &&
          s.availableCapacity >= 2 &&
          targetAvailableSlot == null) {
        targetAvailableSlot = s;
      }
    }
    final systemRecommendation = (overloadedSlot != null &&
            targetAvailableSlot != null)
        ? 'Move 2 eligible bookings from ${overloadedSlot.time} → ${targetAvailableSlot.time}.'
        : (overloadedSlot != null
            ? 'Move 2 eligible bookings from ${overloadedSlot.time} to upcoming afternoon windows.'
            : null);

    return Container(
      key: const Key('officer_slot_management_section'),
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
              Flexible(
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Smart Slot Management',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${slots.length} Active Windows',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          if (systemRecommendation != null) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 16, color: Color(0xFFE65100)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'System Recommendation: $systemRecommendation',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFBF360C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Column(
            children: slots.map((slot) {
              final isOverloaded = slot.isOverloaded;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isOverloaded
                      ? const Color(0xFFFFEBEE)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isOverloaded
                        ? const Color(0xFFEF9A9A)
                        : AppColors.cardBorder,
                    width: isOverloaded ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOverloaded
                          ? Icons.warning_rounded
                          : Icons.access_time_filled_rounded,
                      size: 18,
                      color: isOverloaded
                          ? AppColors.error
                          : AppColors.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  slot.time,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: isOverloaded
                                        ? AppColors.error
                                        : AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isOverloaded
                                      ? const Color(0xFFFFCDD2)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isOverloaded
                                        ? const Color(0xFFE57373)
                                        : AppColors.cardBorder,
                                  ),
                                ),
                                child: Text(
                                  '${slot.bookingsCount}/${slot.capacity}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isOverloaded
                                        ? AppColors.error
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${slot.availableCapacity} available • Arrivals: ${slot.expectedArrivals} • Status: ${slot.recommendationTag}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isOverloaded
                                  ? const Color(0xFFC62828)
                                  : AppColors.textSecondary,
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
                    'Reason: ${rec.reasonEn}',
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
          const SizedBox(height: 6),

          // Expected Impact Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_down_rounded,
                    size: 14, color: AppColors.primaryGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Expected impact: ${rec.displayExpectedImpact}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Action buttons: [ APPROVE ] and [ REJECT ]
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
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'REJECT',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  key: Key('btn_confirm_realloc_${rec.tokenNumber}'),
                  icon: const Icon(Icons.check_rounded, size: 14),
                  label: const Text(
                    'APPROVE',
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
          // Comparison with Current Centre
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFECEFF1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCFD8DC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 16, color: Color(0xFF37474F)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'CURRENT CENTRE: ${_service.centreName}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF263238),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Load: ${_service.centreCapacityPercent}% • Wait: ${_service.averageWait}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF455A64),
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
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
                'Status: ${rec.operatingStatus}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E7D32),
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
          const SizedBox(height: 6),
          Text(
            'Why recommended: ${rec.reasonEn}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
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
    final availableCap =
        (100 - _service.centreCapacityPercent).clamp(0, 100);
    final arrivalsCount = _service.queue
            .where((q) => q.checkInStatus == 'Checked In')
            .length +
        _service.completedTodayCount;
    final next1h = summary.forecasts.isNotEmpty ? summary.forecasts[0] : null;
    final next2h = summary.forecasts.length > 1 ? summary.forecasts[1] : null;

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
                  summary.peakCongestionLevel.icon,
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
                      'Congestion Intelligence & Capacity Forecast',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      CapacityForecastModel.operationalForecastLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(summary.peakCongestionLevel.icon,
                        size: 14, color: summary.peakCongestionLevel.color),
                    const SizedBox(width: 4),
                    Text(
                      summary.peakCongestionLevel.displayTag,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: summary.peakCongestionLevel.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Current Operational Parameters Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.dashboard_customize_rounded,
                        size: 14, color: AppColors.secondary),
                    SizedBox(width: 6),
                    Text(
                      'CURRENT OPERATIONAL PARAMETERS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 10,
                  children: [
                    _buildParamPill('Queue Size', '${_service.queue.length}'),
                    _buildParamPill(
                        'People Waiting', '${_service.waitingCount}'),
                    _buildParamPill('Current Load',
                        '${_service.centreCapacityPercent}%'),
                    _buildParamPill('Available Capacity', '$availableCap%'),
                    _buildParamPill('Processing Rate',
                        '${_service.processingRatePerHour}/hr'),
                    _buildParamPill('Average Wait', _service.averageWait),
                    _buildParamPill('Delay Minutes',
                        '${_service.centreDelayMinutes}m'),
                    _buildParamPill('Arrivals Today', '$arrivalsCount'),
                  ],
                ),
                const Divider(height: 18, thickness: 0.8),
                // Quick Multi-Horizon Overview
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'FORECAST LOAD: Now ${_service.centreCapacityPercent}%  •  +1h ${next1h?.predictedLoadPercent ?? _service.centreCapacityPercent}% (${next1h?.congestionLevel.displayTag ?? "LOW"})  •  +2h ${next2h?.predictedLoadPercent ?? _service.centreCapacityPercent}% (${next2h?.congestionLevel.displayTag ?? "LOW"})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Risk: ${summary.peakCongestionLevel.nameEn.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: summary.peakCongestionLevel.color,
                      ),
                    ),
                  ],
                ),

              ],
            ),
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
                      'Recommended Action',
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

  Widget _buildParamPill(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastTimelineCard(CapacityForecastModel f) {
    return Container(
      key: Key('card_forecast_${f.window.name}'),
      width: 215,
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
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: f.congestionLevel.color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  f.congestionLevel.displayTag,
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
              const Flexible(
                child: Text(
                  'Forecast Load',
                  style: TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
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
          // Deterministic Operational Reason
          Text(
            'Reason: ${f.displayReason}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            f.confidenceBasis,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade700,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  final Key key;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}
