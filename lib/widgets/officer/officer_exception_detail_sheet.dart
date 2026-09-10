import 'package:flutter/material.dart';
import '../../models/officer_exception_model.dart';
import '../../screens/officer_farmer_detail_screen.dart';
import '../../services/procurement_state_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// Phase 14: High-contrast, explainable Exception Detail Sheet.
///
/// Displays complete operational context, current vs. expected measurements,
/// recommended action directive, and direct mitigation controls
/// (Acknowledge, Resolve, and Navigate to Farmer Detail).
class OfficerExceptionDetailSheet extends StatefulWidget {
  final OfficerExceptionModel exception;

  const OfficerExceptionDetailSheet({
    super.key,
    required this.exception,
  });

  static Future<void> show(
    BuildContext context, {
    required OfficerExceptionModel exception,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OfficerExceptionDetailSheet(exception: exception),
    );
  }

  @override
  State<OfficerExceptionDetailSheet> createState() =>
      _OfficerExceptionDetailSheetState();
}

class _OfficerExceptionDetailSheetState
    extends State<OfficerExceptionDetailSheet> {
  late OfficerExceptionModel _currentException;
  final ProcurementStateService _service = ProcurementStateService();

  @override
  void initState() {
    super.initState();
    _currentException = widget.exception;
  }

  Color _severityColor(ExceptionSeverity severity) {
    switch (severity) {
      case ExceptionSeverity.critical:
        return AppColors.error;
      case ExceptionSeverity.warning:
        return AppColors.warning;
      case ExceptionSeverity.info:
        return const Color(0xFF0277BD);
    }
  }

  Color _severityBgColor(ExceptionSeverity severity) {
    switch (severity) {
      case ExceptionSeverity.critical:
        return AppColors.errorContainer;
      case ExceptionSeverity.warning:
        return AppColors.warningContainer;
      case ExceptionSeverity.info:
        return const Color(0xFFE1F5FE);
    }
  }

  IconData _severityIcon(ExceptionSeverity severity) {
    switch (severity) {
      case ExceptionSeverity.critical:
        return Icons.error_rounded;
      case ExceptionSeverity.warning:
        return Icons.warning_amber_rounded;
      case ExceptionSeverity.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sevColor = _severityColor(_currentException.severity);
    final sevBg = _severityBgColor(_currentException.severity);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with severity badge and status
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: sevBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sevColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_severityIcon(_currentException.severity),
                        size: 14, color: sevColor),
                    const SizedBox(width: 4),
                    Text(
                      _currentException.severityLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: sevColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _currentException.status == ExceptionStatus.resolved
                      ? AppColors.primaryContainer
                      : _currentException.status == ExceptionStatus.acknowledged
                          ? const Color(0xFFEDE7F6)
                          : const Color(0xFFFBE9E7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentException.statusLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _currentException.status == ExceptionStatus.resolved
                        ? AppColors.success
                        : _currentException.status ==
                                ExceptionStatus.acknowledged
                            ? const Color(0xFF5E35B1)
                            : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Exception Title
                  Text(
                    _currentException.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentException.shortDescription,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Farmer / Token quick strip if present
                  if (_currentException.tokenNumber != null ||
                      _currentException.farmerName != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 20, color: AppColors.primaryGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_currentException.farmerName != null)
                                  Text(
                                    _currentException.farmerName!,
                                    style: AppTextStyles.labelLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                if (_currentException.tokenNumber != null)
                                  Text(
                                    'Token: ${_currentException.tokenNumber}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_currentException.tokenNumber != null)
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => OfficerFarmerDetailScreen(
                                      tokenNumber:
                                          _currentException.tokenNumber!,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.open_in_new_rounded,
                                  size: 16),
                              label: const Text('Open Detail'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primaryGreen,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Explainability Section: Root Cause & Measurable Factors
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.analytics_outlined,
                                size: 18, color: sevColor),
                            const SizedBox(width: 8),
                            Text(
                              'Observed Operational Fact',
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentException.explanation,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recommended Action Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sevBg.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: sevColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.bolt_rounded, size: 20, color: sevColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recommended Action',
                                style: AppTextStyles.labelMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: sevColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentException.recommendedAction,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Action Buttons Footer
          Row(
            children: [
              // Acknowledge button (only if open)
              if (_currentException.status == ExceptionStatus.open) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _service.acknowledgeException(_currentException.id);
                      setState(() {
                        _currentException = _currentException.copyWith(
                          status: ExceptionStatus.acknowledged,
                        );
                      });
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        size: 16),
                    label: const Text('Acknowledge'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Resolve button (if not already resolved)
              if (_currentException.status != ExceptionStatus.resolved) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _service.resolveException(_currentException.id);
                      setState(() {
                        _currentException = _currentException.copyWith(
                          status: ExceptionStatus.resolved,
                        );
                      });
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.done_all_rounded, size: 16),
                    label: const Text('Mark Resolved'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
