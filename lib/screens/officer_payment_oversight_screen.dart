import 'package:flutter/material.dart';
import '../config/supabase_config.dart';
import '../models/officer_queue_item.dart';
import '../services/procurement_state_service.dart';
import '../theme/app_colors.dart';

/// Phase E: KisanSetu Procurement Officer & Admin Payment Oversight Screen.
///
/// Designed with INFORMATION → DECIDE → CONTROL philosophy:
/// - Transparent oversight of DBT disbursements across 7 lifecycle stages:
///   NOT_ELIGIBLE → PENDING → INITIATED → PROCESSING → SUCCESS/COMPLETED → FAILED → REVERSED.
/// - Payment Exceptions engine identifying stalled, pending, or failed settlements.
/// - Strict adherence to normalized schema (payments → bookings → farmer_produce).
/// - Authorized prototype lifecycle operations explicitly marked as prototype actions.
class OfficerPaymentOversightScreen extends StatefulWidget {
  const OfficerPaymentOversightScreen({super.key});

  @override
  State<OfficerPaymentOversightScreen> createState() =>
      _OfficerPaymentOversightScreenState();
}

class _OfficerPaymentOversightScreenState
    extends State<OfficerPaymentOversightScreen> {
  final _service = ProcurementStateService();
  String _selectedFilter = 'All'; // 'All', 'Exceptions', 'Completed'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _service.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  bool _isException(OfficerQueueItem item) {
    final s = item.paymentStatus.toUpperCase();
    return s == PaymentLifecycleStatus.failed ||
        s == PaymentLifecycleStatus.reversed ||
        s == PaymentLifecycleStatus.processing ||
        (s == PaymentLifecycleStatus.pending && item.netPayable > 0);
  }

  String _getExceptionAction(OfficerQueueItem item) {
    final s = item.paymentStatus.toUpperCase();
    if (s == PaymentLifecycleStatus.failed) {
      return 'Verify farmer bank IFSC / account and retry payment';
    } else if (s == PaymentLifecycleStatus.reversed) {
      return 'Investigate bank reversal note and re-issue voucher';
    } else if (s == PaymentLifecycleStatus.processing) {
      return 'Review payment status';
    } else if (s == PaymentLifecycleStatus.pending) {
      return 'Authorize DBT disbursement batch';
    }
    return 'Review transaction audit';
  }

  String _getExceptionSeverity(OfficerQueueItem item) {
    final s = item.paymentStatus.toUpperCase();
    if (s == PaymentLifecycleStatus.failed ||
        s == PaymentLifecycleStatus.reversed) {
      return 'HIGH';
    } else if (s == PaymentLifecycleStatus.processing) {
      return 'MEDIUM';
    }
    return 'INFO';
  }

  List<OfficerQueueItem> _getFilteredItems() {
    return _service.queue.where((item) {
      if (_selectedFilter == 'Exceptions' && !_isException(item)) return false;
      if (_selectedFilter == 'Completed' &&
          item.paymentStatus.toUpperCase() != PaymentLifecycleStatus.success &&
          item.paymentStatus != 'Completed') {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = item.farmerName.toLowerCase().contains(q) ||
            item.tokenNumber.toLowerCase().contains(q) ||
            item.crop.toLowerCase().contains(q) ||
            (item.paymentReference ?? '').toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  void _showPaymentDetailModal(OfficerQueueItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 580,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: AppColors.primaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MSP PAYMENT OVERSIGHT',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${item.farmerName} • Token ${item.tokenNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // 7-Stage Payment Lifecycle Flowchart
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Lifecycle Progress',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildLifecycleTimeline(item),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Amount & Deductions Breakdown
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildRow('Farmer Name:', item.farmerName,
                            isBold: true),
                        const SizedBox(height: 8),
                        _buildRow('Token Reference:', item.tokenNumber,
                            isBold: true),
                        const SizedBox(height: 8),
                        _buildRow('Crop (Produce):', item.crop),
                        const SizedBox(height: 8),
                        _buildRow('Registered Quantity:', item.quantity),
                        const SizedBox(height: 8),
                        _buildRow('Actual Weighed:', item.actualQuantity,
                            isBold: true),
                        const SizedBox(height: 8),
                        _buildRow('Quality Grade:', item.qualityGrade),
                        const SizedBox(height: 8),
                        _buildRow('Gross Procurement:',
                            '₹${item.grossAmount.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        _buildRow('Statutory Deductions:',
                            '₹${item.deductions.toStringAsFixed(2)}'),
                        const Divider(height: 16),
                        _buildRow(
                          'Net Payable (DBT):',
                          '₹${item.netPayable.toStringAsFixed(2)}',
                          isBold: true,
                          valueColor: AppColors.primaryGreen,
                        ),
                        const SizedBox(height: 8),
                        _buildRow(
                            'Payment Reference:',
                            item.paymentReference ??
                                'PAY-2026-${item.tokenNumber.replaceAll('TK-', '')}'),
                        const SizedBox(height: 8),
                        _buildRow(
                            'Payment Date:', item.paymentDate ?? 'Pending'),
                        const SizedBox(height: 8),
                        _buildRow('Status:', item.paymentStatus.toUpperCase(),
                            isBold: true,
                            valueColor: _getStatusColor(item.paymentStatus)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Prototype Notice
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warningContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16, color: AppColors.warning),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Prototype Boundary Notice: State transitions simulate operational workflow. Live banking requires verified PFMS/NPCI gateway adapter.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Actions
                  Row(
                    children: [
                      if (item.paymentStatus != 'Completed' &&
                          item.paymentStatus.toUpperCase() !=
                              PaymentLifecycleStatus.success) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            key: const Key('btn_modal_complete_payment'),
                            onPressed: () {
                              _service.markPaymentCompleted(item.tokenNumber);
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'DBT payment completed for ${item.farmerName} (₹${item.netPayable.toStringAsFixed(2)}).'),
                                  backgroundColor: AppColors.primaryGreen,
                                ),
                              );
                            },
                            icon: const Icon(Icons.check_circle_rounded,
                                size: 16),
                            label: const Text(
                              'MARK COMPLETED (DEMO)',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (item.paymentStatus.toUpperCase() ==
                          PaymentLifecycleStatus.failed) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('btn_modal_retry_payment'),
                            onPressed: () {
                              _service.retryPayment(item.tokenNumber);
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Settlement retry submitted for verification.'),
                                  backgroundColor: AppColors.secondary,
                                ),
                              );
                            },
                            icon: const Icon(Icons.replay_rounded, size: 16),
                            label: const Text(
                              'RETRY SETTLEMENT',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.secondary,
                              side:
                                  const BorderSide(color: AppColors.secondary),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLifecycleTimeline(OfficerQueueItem item) {
    final stages = [
      'Accepted',
      'Pending',
      'Initiated',
      'Processing',
      'Completed'
    ];
    final curStatus = item.paymentStatus.toLowerCase();
    int currentStepIndex = 1;
    if (curStatus == 'completed' || curStatus == 'success') {
      currentStepIndex = 4;
    } else if (curStatus == 'processing') {
      currentStepIndex = 3;
    } else if (curStatus == 'initiated') {
      currentStepIndex = 2;
    } else if (curStatus == 'pending') {
      currentStepIndex = 1;
    }

    return Row(
      children: List.generate(stages.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIdx = index ~/ 2;
          final isPast = stepIdx < currentStepIndex;
          return Expanded(
            child: Container(
              height: 3,
              color: isPast ? AppColors.primaryGreen : AppColors.cardBorder,
            ),
          );
        }
        final stepIdx = index ~/ 2;
        final isCompleted = stepIdx <= currentStepIndex;
        final isCurrent = stepIdx == currentStepIndex;

        return Column(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: isCompleted
                  ? AppColors.primaryGreen
                  : AppColors.surfaceVariant,
              child: isCurrent
                  ? const Icon(Icons.radio_button_checked_rounded,
                      size: 14, color: Colors.white)
                  : (isCompleted
                      ? const Icon(Icons.check_rounded,
                          size: 12, color: Colors.white)
                      : Text(
                          '${stepIdx + 1}',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary),
                        )),
            ),
            const SizedBox(height: 4),
            Text(
              stages[stepIdx],
              style: TextStyle(
                fontSize: 9,
                fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                color: isCurrent
                    ? AppColors.primaryGreen
                    : AppColors.textSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        return AppColors.primaryGreen;
      case 'failed':
      case 'reversed':
        return AppColors.error;
      case 'processing':
      case 'initiated':
        return AppColors.secondary;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = _service.queue;
    final totalDisbursed = queue
        .where((q) =>
            q.paymentStatus == 'Completed' ||
            q.paymentStatus.toUpperCase() == PaymentLifecycleStatus.success)
        .fold<double>(0.0, (acc, item) => acc + item.netPayable);
    final totalPending = queue
        .where((q) => q.paymentStatus == 'Pending')
        .fold<double>(0.0, (acc, item) => acc + item.netPayable);
    final exceptionsList = queue.where((q) => _isException(q)).toList()
      ..sort((a, b) {
        final aHigh =
            a.paymentStatus.toUpperCase() == PaymentLifecycleStatus.failed ||
                a.paymentStatus.toUpperCase() == PaymentLifecycleStatus.reversed;
        final bHigh =
            b.paymentStatus.toUpperCase() == PaymentLifecycleStatus.failed ||
                b.paymentStatus.toUpperCase() == PaymentLifecycleStatus.reversed;
        if (aHigh && !bHigh) return -1;
        if (!aHigh && bHigh) return 1;
        return 0;
      });
    final filtered = _getFilteredItems();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Dashboard',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Oversight & Exceptions',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'MSP DBT Payouts & Exception Handling',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.cardBorder, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // KPI Summary Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Disbursed (Settled)',
                    value: '₹${totalDisbursed.toStringAsFixed(0)}',
                    color: AppColors.primaryGreen,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Pending Authorization',
                    value: '₹${totalPending.toStringAsFixed(0)}',
                    color: AppColors.warning,
                    icon: Icons.hourglass_top_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Active Exceptions',
                    value: '${exceptionsList.length}',
                    color: exceptionsList.isNotEmpty
                        ? AppColors.error
                        : AppColors.primaryGreen,
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Transactions',
                    value: '${queue.length}',
                    color: AppColors.secondary,
                    icon: Icons.receipt_long_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // DBT Lifecycle Pipeline Card (Requirement 7)
            Container(
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
                    children: [
                      const Icon(Icons.alt_route_rounded,
                          color: AppColors.primaryGreen, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'DBT Lifecycle Pipeline',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Normalized: payments → bookings → farmer_produce',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildPipelineBadge('Produce Accepted', Icons.inventory_2_outlined),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textSecondary),
                      _buildPipelineBadge('Payment Eligible', Icons.verified_user_outlined),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textSecondary),
                      _buildPipelineBadge('Payment Pending', Icons.hourglass_top_rounded),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textSecondary),
                      _buildPipelineBadge('Payment Initiated', Icons.send_rounded),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textSecondary),
                      _buildPipelineBadge('Processing', Icons.sync_rounded),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.textSecondary),
                      _buildPipelineBadge('Completed', Icons.check_circle_rounded),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Highlighted Payment Exceptions Box (Required by specification 6)
            if (exceptionsList.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_rounded,
                            color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Payment Exceptions Requiring Attention',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warningContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${exceptionsList.length} Items',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...exceptionsList.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.errorContainer,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'PAYMENT EXCEPTION',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        item.farmerName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        item.tokenNumber,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Amount: ₹${item.netPayable.toStringAsFixed(2)} • Status: ${item.paymentStatus} • Severity: ${_getExceptionSeverity(item)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Action: ${_getExceptionAction(item)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (item.paymentStatus.toLowerCase() == 'failed') ...[
                              ElevatedButton(
                                onPressed: () {
                                  _service.retryPayment(item.tokenNumber);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Payment re-initiated for token ${item.tokenNumber}.'),
                                      backgroundColor: AppColors.primaryGreen,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Retry Settlement',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            ElevatedButton(
                              key: Key(
                                  'btn_resolve_exception_${item.tokenNumber}'),
                              onPressed: () => _showPaymentDetailModal(item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'REVIEW',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Controls & Filters Bar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by farmer, token, or payment ref...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 20, color: AppColors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Exceptions', 'Completed'].map((filter) {
                      final isSel = _selectedFilter == filter;
                      return ChoiceChip(
                        label: Text(filter),
                        selected: isSel,
                        selectedColor: AppColors.primaryContainer,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSel ? FontWeight.w800 : FontWeight.w600,
                          color: isSel
                              ? AppColors.primaryGreen
                              : AppColors.textSecondary,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Transactions Header & Batch Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Disbursement Roster (${filtered.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (queue.any((q) => q.paymentStatus == 'Pending'))
                  ElevatedButton.icon(
                    key: const Key('btn_authorize_dbt_batch'),
                    onPressed: () {
                      final pending =
                          queue.where((q) => q.paymentStatus == 'Pending');
                      for (final p in pending) {
                        _service.markPaymentCompleted(p.tokenNumber);
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Authorized ${pending.length} pending DBT payment vouchers.'),
                          backgroundColor: AppColors.primaryGreen,
                        ),
                      );
                    },
                    icon: const Icon(Icons.send_rounded, size: 14),
                    label: const Text(
                      'AUTHORIZE PENDING BATCH',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Roster Cards
            ...filtered.map((item) {
              return _buildPaymentCard(item);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineBadge(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.secondary),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(OfficerQueueItem item) {
    final statusColor = _getStatusColor(item.paymentStatus);
    Color statusBg;
    if (statusColor == AppColors.primaryGreen) {
      statusBg = AppColors.primaryContainer;
    } else if (statusColor == AppColors.error) {
      statusBg = AppColors.errorContainer;
    } else if (statusColor == AppColors.secondary) {
      statusBg = AppColors.secondaryContainer;
    } else {
      statusBg = AppColors.warningContainer;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          // Header Row: Farmer + Status + Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    item.farmerName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.tokenNumber,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.paymentStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                key: Key('btn_inspect_payment_${item.tokenNumber}'),
                onPressed: () => _showPaymentDetailModal(item),
                icon: const Icon(Icons.visibility_rounded, size: 14),
                label: const Text(
                  'AUDIT OVERSIGHT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Details Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crop: ${item.crop} • Weighed: ${item.actualQuantity} (${item.qualityGrade})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Ref: ${item.paymentReference ?? 'PAY-2026-${item.tokenNumber.replaceAll('TK-', '')}'} • Date: ${item.paymentDate ?? 'Pending'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Net Payable DBT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '₹${item.netPayable.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
