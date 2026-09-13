import 'package:flutter/material.dart';
import '../models/farmer_dispute_report.dart';
import '../services/procurement_state_service.dart';
import '../theme/app_colors.dart';

/// Phase E: KisanSetu Procurement Officer & Admin Dispute Audit Console.
///
/// Designed with INFORMATION → DECIDE → CONTROL philosophy:
/// - Full oversight of active grievances and historical resolutions.
/// - Clear calculation of registered quantity, actual weighed quantity, difference, and difference percentage.
/// - Explicit status tracking: Submitted, Under Review, Resolved, Rejected, Escalated.
/// - Dispute Review detail modal with [ RESOLVE ], [ REJECT ], and [ ESCALATE ] actions.
/// - Historical procurement data is strictly read-only and preserved for audit integrity.
class OfficerDisputeConsoleScreen extends StatefulWidget {
  final String? initialToken;

  const OfficerDisputeConsoleScreen({
    super.key,
    this.initialToken,
  });

  @override
  State<OfficerDisputeConsoleScreen> createState() =>
      _OfficerDisputeConsoleScreenState();
}

class _OfficerDisputeConsoleScreenState
    extends State<OfficerDisputeConsoleScreen> {
  final _service = ProcurementStateService();
  String _selectedFilter = 'Active'; // 'All', 'Active', 'Resolved'
  String _searchQuery = '';
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onStateChanged);
    _notesController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  List<FarmerDisputeReport> _getFilteredDisputes() {
    return _service.disputes.where((d) {
      if (_selectedFilter == 'Active' && !d.isActive) return false;
      if (_selectedFilter == 'Resolved' && !d.isResolved && !d.isRejected) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = d.id.toLowerCase().contains(q) ||
            d.farmerName.toLowerCase().contains(q) ||
            d.tokenNumber.toLowerCase().contains(q) ||
            d.crop.toLowerCase().contains(q) ||
            d.reason.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _showResolveConfirmationDialog(
      BuildContext parentCtx, FarmerDisputeReport dispute) async {
    final resolutionNotesController =
        TextEditingController(text: _notesController.text.trim());
    await showDialog<void>(
      context: parentCtx,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Resolve Dispute',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Enter official resolution findings and audit justification:'),
            const SizedBox(height: 12),
            TextField(
              controller: resolutionNotesController,
              decoration: const InputDecoration(
                hintText: 'Enter resolution notes...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final notes = resolutionNotesController.text.trim();
              _service.resolveDispute(
                dispute.id,
                notes: notes.isNotEmpty
                    ? notes
                    : 'Grievance investigated and resolved with farmer consent.',
              );
              Navigator.of(ctx).pop();
              Navigator.of(parentCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Dispute ${dispute.id} marked RESOLVED.'),
                  backgroundColor: AppColors.primaryGreen,
                ),
              );
            },
            child: const Text('Confirm Resolution'),
          ),
        ],
      ),
    );
  }

  void _openDisputeReview(FarmerDisputeReport dispute) {
    _notesController.clear();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final diff = dispute.difference;
            final diffPct = dispute.differencePercentage;
            final audits =
                _service.getWeighmentAuditsForToken(dispute.tokenNumber);

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 600,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.gavel_rounded,
                              color: AppColors.secondary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DISPUTE REVIEW',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Dispute ID: ${dispute.id} • ${dispute.status.toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
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
                      const Divider(height: 28),

                      // Structured Breakdown Card (as required by specification)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('Farmer:', dispute.farmerName,
                                isBold: true),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                                'Token:', dispute.tokenNumber,
                                isBold: true),
                            const SizedBox(height: 8),
                            _buildDetailRow('Crop:', dispute.crop),
                            const SizedBox(height: 8),
                            _buildDetailRow('Assigned Centre:',
                                dispute.centreName),
                            const SizedBox(height: 8),
                            _buildDetailRow('Registered:',
                                '${dispute.registeredQuantity.toStringAsFixed(2)} Qtl'),
                            const SizedBox(height: 8),
                            _buildDetailRow('Actual:',
                                '${dispute.actualQuantity.toStringAsFixed(2)} Qtl',
                                valueColor: AppColors.secondary),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Difference:',
                              '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(2)} Qtl (${diffPct >= 0 ? '+' : ''}${diffPct.toStringAsFixed(1)}%)',
                              valueColor: diff.abs() > 0.05
                                  ? AppColors.error
                                  : AppColors.primaryGreen,
                              isBold: true,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow('Reason:', dispute.reason,
                                isBold: true),
                            const SizedBox(height: 8),
                            _buildDetailRow('Officer:', dispute.officerId),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              'Recorded:',
                              '${dispute.submittedAt.day.toString().padLeft(2, '0')}/${dispute.submittedAt.month.toString().padLeft(2, '0')}/${dispute.submittedAt.year} ${dispute.submittedAt.hour.toString().padLeft(2, '0')}:${dispute.submittedAt.minute.toString().padLeft(2, '0')}',
                            ),
                            if (dispute.explanation != null &&
                                dispute.explanation!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildDetailRow('Farmer Explanation:',
                                  dispute.explanation!),
                            ],
                            if (dispute.officerNotes != null &&
                                dispute.officerNotes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _buildDetailRow('Prior Officer Notes:',
                                  dispute.officerNotes!,
                                  valueColor: AppColors.primaryDark),
                            ],
                          ],
                        ),
                      ),

                      // Associated Weighment Audit Trail
                      if (audits.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.history_rounded,
                                size: 16, color: AppColors.secondary),
                            const SizedBox(width: 6),
                            const Text(
                              'Weighment Audit Trail (Read-Only)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...audits.map((audit) => Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: AppColors.cardBorder),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Original: ${audit.originalWeight.toStringAsFixed(2)} Qtl → Updated: ${audit.updatedWeight.toStringAsFixed(2)} Qtl',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          'By ${audit.changedBy} on ${audit.formattedDateTime} • Reason: ${audit.reason}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${audit.difference >= 0 ? '+' : ''}${audit.difference.toStringAsFixed(2)} Qtl',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: audit.difference.abs() > 0.05
                                            ? AppColors.warning
                                            : AppColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],

                      const SizedBox(height: 16),

                      // Read-only integrity notice
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primaryContainer.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.primaryGreen
                                  .withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                size: 16, color: AppColors.primaryGreen),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Audit Integrity Guard: Historical procurement records cannot be arbitrarily altered from this console.',
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

                      const SizedBox(height: 16),

                      // Officer Notes input field
                      if (dispute.isActive) ...[
                        TextField(
                          controller: _notesController,
                          decoration: InputDecoration(
                            labelText: 'Officer Finding / Decision Notes',
                            hintText:
                                'e.g. Scale recalibrated, moisture re-tested, grievance resolved.',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          maxLines: 2,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 20),

                        // Actions: [ RESOLVE ] [ REJECT ] [ ESCALATE ]
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                key: const Key('action_resolve_dispute'),
                                onPressed: () {
                                  _showResolveConfirmationDialog(ctx, dispute);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'RESOLVE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                key: const Key('action_reject_dispute'),
                                onPressed: () {
                                  final notes = _notesController.text.trim();
                                  _service.rejectDispute(
                                    dispute.id,
                                    notes: notes.isNotEmpty
                                        ? notes
                                        : 'Inspection confirms weighment verified within tolerance limits.',
                                  );
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Dispute ${dispute.id} REJECTED.'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(
                                      color: AppColors.error),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'REJECT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                key: const Key('action_escalate_dispute'),
                                onPressed: () {
                                  final notes = _notesController.text.trim();
                                  _service.escalateDispute(
                                    dispute.id,
                                    notes: notes.isNotEmpty
                                        ? notes
                                        : 'Escalated to District Agricultural Officer for adjudication.',
                                  );
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Dispute ESCALATED to District Committee.'),
                                      backgroundColor: Color(0xFF5E35B1),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF5E35B1),
                                  side: const BorderSide(
                                      color: Color(0xFF5E35B1)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'ESCALATE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Close'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final allDisputes = _service.disputes;
    final activeCount = allDisputes.where((d) => d.isActive).length;
    final resolvedCount = allDisputes.where((d) => d.isResolved).length;
    final discrepancyCount = allDisputes
        .where((d) =>
            d.reason.toLowerCase().contains('quantity') ||
            d.reason.toLowerCase().contains('weight') ||
            d.difference.abs() > 0.05)
        .length;
    final filtered = _getFilteredDisputes();

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
        title: const Row(
          children: [
            Icon(Icons.gavel_rounded, color: AppColors.secondary, size: 22),
            SizedBox(width: 8),
            Text(
              'Dispute Audit Console',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
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
                    title: 'Total Disputes',
                    value: '${allDisputes.length}',
                    color: AppColors.secondary,
                    icon: Icons.assignment_late_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Active Disputes',
                    value: '$activeCount',
                    color: activeCount > 0
                        ? AppColors.warning
                        : AppColors.primaryGreen,
                    icon: Icons.pending_actions_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Quantity Issues',
                    value: '$discrepancyCount',
                    color: AppColors.error,
                    icon: Icons.scale_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Resolved',
                    value: '$resolvedCount',
                    color: AppColors.primaryGreen,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Controls & Filter Bar
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Search box
                      Expanded(
                        child: TextField(
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim();
                            });
                          },
                          decoration: InputDecoration(
                            hintText:
                                'Search by farmer, token, crop, or dispute ID...',
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

                      // Segmented Filters
                      Wrap(
                        spacing: 8,
                        children: ['All', 'Active', 'Resolved'].map((filter) {
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
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dispute list header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dispute Cases (${filtered.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Assigned: ${_service.centreName}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Dispute cards list
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        size: 44, color: AppColors.primaryGreen),
                    const SizedBox(height: 10),
                    const Text(
                      'No disputes found under this filter.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All farmer grievances for ${_service.centreName} are cleared or resolved.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...filtered.map((dispute) {
                return _buildDisputeCard(dispute);
              }),
          ],
        ),
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

  Widget _buildDisputeCard(FarmerDisputeReport dispute) {
    Color statusColor;
    Color statusBg;
    switch (dispute.status.toLowerCase()) {
      case 'resolved':
        statusColor = AppColors.primaryGreen;
        statusBg = AppColors.primaryContainer;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusBg = AppColors.errorContainer;
        break;
      case 'escalated':
        statusColor = const Color(0xFF5E35B1);
        statusBg = const Color(0xFFEDE7F6);
        break;
      default:
        statusColor = AppColors.warning;
        statusBg = AppColors.warningContainer;
    }

    final diff = dispute.difference;
    final diffPct = dispute.differencePercentage;

    return InkWell(
      key: Key('dispute_card_${dispute.id}'),
      onTap: () => _openDisputeReview(dispute),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            // Top Row: Dispute ID + Status + Action Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dispute.id,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dispute.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  key: Key('btn_review_${dispute.id}'),
                  onPressed: () => _openDisputeReview(dispute),
                  icon: const Icon(Icons.rate_review_rounded, size: 14),
                  label: const Text(
                    'REVIEW & AUDIT',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Main Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dispute.farmerName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              dispute.tokenNumber,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Crop:',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            dispute.crop,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text('•',
                              style: TextStyle(
                                  color: AppColors.textSecondary)),
                          Text(
                            'Centre: ${dispute.centreName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reason: ${dispute.reason}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Registered:',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          Text(
                            '${dispute.registeredQuantity.toStringAsFixed(2)} Qtl',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Actual Weighed:',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          Text(
                            '${dispute.actualQuantity.toStringAsFixed(2)} Qtl',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Difference:',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          Text(
                            '${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(2)} Qtl (${diffPct >= 0 ? '+' : ''}${diffPct.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: diff.abs() > 0.05
                                  ? AppColors.error
                                  : AppColors.primaryGreen,
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
          if (dispute.explanation != null &&
              dispute.explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Farmer Note: "${dispute.explanation}"',
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (dispute.officerNotes != null &&
              dispute.officerNotes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Officer Finding: "${dispute.officerNotes}"',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
}
