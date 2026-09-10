import 'package:flutter/material.dart';
import '../models/officer_queue_item.dart';
import '../services/payment_calculation_service.dart';
import '../services/procurement_state_service.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Phase 7 & 8: Procurement Officer - Farmer Detail & Verification Screen.
///
/// Enables inspecting produce documentation, recording actual weighment,
/// selecting quality grade (FAQ / Grade A / Grade B), advancing through the
/// 7-stage procurement lifecycle, and controlling DBT payment processing.
class OfficerFarmerDetailScreen extends StatefulWidget {
  final String tokenNumber;

  const OfficerFarmerDetailScreen({
    super.key,
    required this.tokenNumber,
  });

  @override
  State<OfficerFarmerDetailScreen> createState() =>
      _OfficerFarmerDetailScreenState();
}

class _OfficerFarmerDetailScreenState extends State<OfficerFarmerDetailScreen> {
  final _service = ProcurementStateService();

  late double _actualWeight;
  late String _selectedGrade;
  bool _initializedState = false;

  static const List<String> _lifecycleStages = [
    'Booked',
    'Arrived',
    'Quality Check',
    'Weighment',
    'Accepted',
    'Payment Pending',
    'Completed',
  ];

  static const List<String> _qualityGrades = [
    'FAQ',
    'Grade A',
    'Grade B',
  ];

  OfficerQueueItem? get _item {
    final list = _service.queue;
    final index = list.indexWhere((q) => q.tokenNumber == widget.tokenNumber);
    if (index != -1) return list[index];
    return null;
  }

  void _initItemState(OfficerQueueItem item) {
    if (!_initializedState) {
      _actualWeight = double.tryParse(
              item.actualQuantity.replaceAll(RegExp(r'[^0-9.]'), '')) ??
          50.2;
      _selectedGrade = item.qualityGrade;
      _initializedState = true;
    }
  }

  void _showVoiceGuidance() {
    final item = _item;
    if (item == null) return;

    final text =
        'Farmer verification for ${item.farmerName}. Token: ${item.tokenNumber}. Status: ${item.status}. Actual weight: ${item.actualQuantity}. Quality: ${item.qualityGrade}.';
    VoiceAssistantSpeechService.instance.speak(text, language: 'en');

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.textPrimary,
        duration: const Duration(seconds: 5),
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _service,
      builder: (context, _) {
        final item = _item;
        if (item == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Farmer Detail')),
            body: const Center(child: Text('Farmer not found in queue.')),
          );
        }

        _initItemState(item);
        final currentStageIndex = _lifecycleStages.indexOf(item.status);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: Text('Farmer Detail • ${item.tokenNumber}'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Back to Dashboard',
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              Semantics(
                label: 'Listen to verification guidance',
                button: true,
                child: TextButton.icon(
                  onPressed: _showVoiceGuidance,
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    color: AppColors.secondary,
                    size: 18,
                  ),
                  label: const Text(
                    'Listen / सुनें',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.secondaryContainer,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Verification Overview Card
                  _buildOverviewCard(item),
                  const SizedBox(height: 20),

                  // 2. Physical Inspection & Weighment Card (Phase 8)
                  _buildInspectionCard(item),
                  const SizedBox(height: 20),

                  // 3. Payment Status & Controls Card (Phase 8)
                  _buildPaymentCard(item),
                  const SizedBox(height: 20),

                  // 4. 7-Stage Procurement Lifecycle Card
                  _buildLifecycleCard(item, currentStageIndex),
                  const SizedBox(height: 20),

                  // 5. Back to Dashboard Button
                  SizedBox(
                    height: 52,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      label: const Text(
                        'Return to Officer Dashboard',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(OfficerQueueItem item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.secondary,
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOKEN NUMBER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.tokenNumber,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(item.status),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 14),

          _buildInfoRow(
            icon: Icons.person_rounded,
            label: 'Farmer',
            value: item.farmerName,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.grass_rounded,
            label: 'Crop',
            value: item.crop,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.scale_rounded,
            label: 'Quantity',
            value: item.quantity,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Booked Slot',
            value: item.bookedSlot,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.pin_drop_rounded,
            label: 'Arrival',
            value: item.arrivalTime,
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionCard(OfficerQueueItem item) {
    final expectedQ = double.tryParse(
            item.quantity.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        50.0;
    final diff = _actualWeight - expectedQ;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.scale_rounded,
                      color: AppColors.secondary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Weighment & Quality Verification',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Weighment Comparison
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Expected Quantity:'),
                    Text(
                      '${expectedQ.toStringAsFixed(1)} Quintals',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Actual Quantity:'),
                    Text(
                      '${_actualWeight.toStringAsFixed(1)} Quintals',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Difference:'),
                    Text(
                      diff >= 0
                          ? '+${diff.toStringAsFixed(1)} Quintals'
                          : '${diff.toStringAsFixed(1)} Quintals',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: diff.abs() > 0.05
                            ? AppColors.warning
                            : AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Actual Weighment Stepper Control
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Actual Weighment:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppColors.secondary),
                    onPressed: () {
                      if (_actualWeight > 5.0) {
                        setState(() {
                          _actualWeight =
                              double.parse((_actualWeight - 0.1).toStringAsFixed(1));
                        });
                      }
                    },
                  ),
                  Text(
                    '${_actualWeight.toStringAsFixed(1)} Quintals',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.secondary),
                    onPressed: () {
                      setState(() {
                        _actualWeight =
                            double.parse((_actualWeight + 0.1).toStringAsFixed(1));
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Quality Grade Selection
          const Text(
            'Quality Grade:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _qualityGrades.map((grade) {
              final isSelected = _selectedGrade == grade;
              return ChoiceChip(
                label: Text(
                  grade,
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
                  setState(() {
                    _selectedGrade = grade;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Operational Actions: Confirm Quality, Confirm Weighment, Accept Produce
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _service.confirmQuality(item.tokenNumber, _selectedGrade),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Confirm Quality',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _service.confirmWeighment(item.tokenNumber, _actualWeight),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(color: AppColors.secondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Confirm Weighment',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _service.acceptProduce(item.tokenNumber),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
              label: const Text(
                'Accept Produce',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
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
        ],
      ),
    );
  }

  Widget _buildPaymentCard(OfficerQueueItem item) {
    final isPending = item.paymentStatus == 'Pending';
    final isProcessing = item.paymentStatus == 'Processing';
    final isCompleted = item.paymentStatus == 'Completed';

    final amtStr = PaymentCalculationService.formatCurrency(item.netPayable);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.payments_rounded,
                      color: AppColors.secondary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Payment Status & Actions',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.primaryContainer
                      : (isProcessing
                          ? Colors.blue.withValues(alpha: 0.15)
                          : AppColors.secondaryContainer),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.paymentStatus,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isCompleted
                        ? AppColors.primaryGreen
                        : (isProcessing ? Colors.blue.shade800 : AppColors.secondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildInfoRow(
            icon: Icons.check_circle_rounded,
            label: 'Procurement',
            value: item.status == 'Completed'
                ? 'Completed'
                : (item.status == 'Accepted' ? 'Accepted' : item.status),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.hourglass_top_rounded,
            label: 'Payment',
            value: item.paymentStatus,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.currency_rupee_rounded,
            label: 'Net Amount',
            value: amtStr,
          ),
          if (item.paymentReference != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              icon: Icons.receipt_long_rounded,
              label: 'Reference',
              value: item.paymentReference!,
            ),
          ],
          const SizedBox(height: 16),

          // Payment Actions: Initiate Payment & Mark Payment Completed
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isPending
                      ? () => _service.initiatePayment(item.tokenNumber)
                      : null,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text(
                    'Initiate Payment',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: !isCompleted
                      ? () => _service.markPaymentCompleted(item.tokenNumber)
                      : null,
                  icon: const Icon(Icons.task_alt_rounded, size: 18),
                  label: const Text(
                    'Mark Payment Completed',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
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

  Widget _buildLifecycleCard(OfficerQueueItem item, int currentStageIndex) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Procurement Lifecycle Stage',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Advance the farmer systematically through physical verification and intake.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 16),

          // Stage list
          Column(
            children: List.generate(_lifecycleStages.length, (i) {
              final stageName = _lifecycleStages[i];
              final isPassed = currentStageIndex > i;
              final isCurrent = currentStageIndex == i;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isPassed
                            ? AppColors.primaryContainer
                            : (isCurrent
                                ? AppColors.secondaryContainer
                                : AppColors.surfaceVariant),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isPassed
                              ? AppColors.primaryGreen
                              : (isCurrent
                                  ? AppColors.secondary
                                  : AppColors.cardBorder),
                          width: isCurrent ? 2.0 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: isPassed
                            ? const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: AppColors.primaryGreen,
                              )
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isCurrent
                                      ? AppColors.secondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        stageName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isCurrent
                              ? AppColors.textPrimary
                              : (isPassed
                                  ? AppColors.textPrimary
                                  : AppColors.textTertiary),
                        ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Quick advance lifecycle button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: item.status != 'Completed'
                  ? () => _service.advanceLifecycle(item.tokenNumber)
                  : null,
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text(
                'Advance Lifecycle Stage',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = AppColors.surfaceVariant;
    Color border = AppColors.cardBorder;
    Color text = AppColors.textPrimary;
    IconData icon = Icons.info_outline_rounded;

    if (status == 'Completed') {
      bg = AppColors.primaryContainer;
      border = AppColors.primaryGreen;
      text = AppColors.primaryGreen;
      icon = Icons.verified_rounded;
    } else if (status == 'Waiting' || status == 'Arrived') {
      bg = AppColors.warning.withValues(alpha: 0.12);
      border = AppColors.warning;
      text = AppColors.warning;
      icon = Icons.hourglass_bottom_rounded;
    } else if (status == 'Sampling' ||
        status == 'Quality Check' ||
        status == 'Weighment' ||
        status == 'Accepted') {
      bg = AppColors.secondaryContainer;
      border = AppColors.secondary;
      text = AppColors.secondary;
      icon = Icons.science_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: text),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
