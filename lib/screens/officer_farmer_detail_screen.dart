import 'package:flutter/material.dart';
import '../models/officer_queue_item.dart';
import '../services/payment_calculation_service.dart';
import '../services/procurement_state_service.dart';
import '../services/voice_assistant_speech/voice_assistant_speech_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Phase C: Procurement Officer - Farmer Detail & Processing Screen.
///
/// Implements the complete Officer-side procurement processing workflow:
/// QR Check-In → Checked In → Waiting → Call Farmer → Farmer/Booking Verification
/// → Quality Inspection → Weighment → Grade/Quality Result → Procurement Acceptance
/// → Bill/Payment Readiness → Completed.
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
  late TextEditingController _weightController;
  late TextEditingController _qualityNotesController;
  late TextEditingController _overrideReasonController;
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

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController();
    _qualityNotesController = TextEditingController();
    _overrideReasonController = TextEditingController();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _qualityNotesController.dispose();
    _overrideReasonController.dispose();
    super.dispose();
  }

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
      _weightController.text = _actualWeight.toStringAsFixed(1);
      _qualityNotesController.text = 'Moisture 11.2%, Foreign matter < 0.5%';
      _overrideReasonController.text = item.discrepancyNote ?? '';
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  // Top Procurement Workflow Stepper Header
                  _buildWorkflowStepper(item),
                  const SizedBox(height: 20),

                  // Stage 1: Farmer Verification Card
                  _buildFarmerVerificationCard(item),
                  const SizedBox(height: 20),

                  // Stage 2: Quality Inspection Card
                  _buildQualityInspectionCard(item),
                  const SizedBox(height: 20),

                  // Stage 3: Weighment Card
                  _buildWeighmentCard(item),
                  const SizedBox(height: 20),

                  // Phase E: Weighment Audit Trail (Immutable)
                  _buildWeighmentAuditTrailCard(item),
                  const SizedBox(height: 20),

                  // Stage 4: Procurement Summary Card
                  _buildProcurementSummaryCard(item),
                  const SizedBox(height: 20),

                  // Stage 5: Bill / Payment Readiness Card
                  _buildBillPaymentCard(item),
                  const SizedBox(height: 20),

                  // Stage 6: Full 7-Stage Lifecycle Tracking Card
                  _buildLifecycleCard(item, currentStageIndex),
                  const SizedBox(height: 20),

                  // Return to Officer Dashboard Button
                  SizedBox(
                    height: 52,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      label: const Text(
                        'Return to Officer Dashboard',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
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

  /// Visual workflow pipeline indicator:
  /// Verification → Quality → Weighment → Summary → Bill/Payment
  Widget _buildWorkflowStepper(OfficerQueueItem item) {
    int activeStep = 0;
    if (item.status == 'Quality Check' || item.status == 'Sampling') {
      activeStep = 1;
    } else if (item.status == 'Weighment') {
      activeStep = 2;
    } else if (item.status == 'Accepted') {
      activeStep = 3;
    } else if (item.status == 'Payment Pending' || item.status == 'Completed') {
      activeStep = 4;
    }

    final steps = [
      '1. Verify',
      '2. Quality',
      '3. Weigh',
      '4. Summary',
      '5. Payment',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                'PROCUREMENT PIPELINE WORKFLOW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              _buildStatusBadge(item.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(steps.length, (i) {
              final isPassed = activeStep > i;
              final isCurrent = activeStep == i;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isPassed
                              ? AppColors.primaryContainer
                              : (isCurrent
                                  ? AppColors.secondaryContainer
                                  : AppColors.surfaceVariant),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPassed
                                ? AppColors.primaryGreen
                                : (isCurrent
                                    ? AppColors.secondary
                                    : AppColors.cardBorder),
                            width: isCurrent ? 1.5 : 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            steps[i],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isCurrent || isPassed
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isPassed
                                  ? AppColors.primaryGreen
                                  : (isCurrent
                                      ? AppColors.secondary
                                      : AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (i < steps.length - 1)
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Stage 1: Farmer & Booking Verification
  Widget _buildFarmerVerificationCard(OfficerQueueItem item) {
    final isCheckedIn = item.checkInStatus == 'Checked In';
    final isInvalidBooking =
        item.status == 'Cancelled' || item.status == 'Expired';

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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FARMER VERIFICATION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Verify farmer identity and produce booking details.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCheckedIn
                      ? AppColors.primaryContainer
                      : AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCheckedIn
                          ? Icons.check_circle_rounded
                          : Icons.pending_rounded,
                      size: 14,
                      color: isCheckedIn
                          ? AppColors.primaryGreen
                          : AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCheckedIn ? 'Gate Check-In Verified' : 'Awaiting Gate QR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isCheckedIn
                            ? AppColors.primaryGreen
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
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
            icon: Icons.confirmation_number_rounded,
            label: 'Token',
            value: item.tokenNumber,
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
            label: 'Registered Quantity',
            value: '${item.quantity} Qtl',
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Scheduled Slot',
            value: item.bookedSlot,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            icon: Icons.store_rounded,
            label: 'Centre',
            value: 'Assigned procurement centre',
          ),
          const SizedBox(height: 16),

          if (isInvalidBooking) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Booking is invalid or cancelled. Procurement processing disabled.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Actions: [ VERIFY & CONTINUE ] and [ HOLD / RETURN TO QUEUE ]
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: isInvalidBooking
                      ? null
                      : () {
                          final started =
                              _service.startProcurement(item.tokenNumber);
                          if (!started && item.checkInStatus != 'Checked In') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Warning: Farmer must be checked in at the gate scanner first.',
                                ),
                                backgroundColor: AppColors.warning,
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.verified_user_rounded, size: 18),
                  label: const Text(
                    'VERIFY & CONTINUE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _service.holdOrReturnToQueue(
                      item.tokenNumber,
                      reason: 'Returned to queue by officer',
                    );
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.pause_circle_outline_rounded, size: 18),
                  label: const Text(
                    'HOLD / RETURN TO QUEUE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

  /// Stage 2: Quality Inspection Card
  Widget _buildQualityInspectionCard(OfficerQueueItem item) {
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
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.biotech_rounded,
                        color: AppColors.secondary, size: 22),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QUALITY INSPECTION',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Weighment & Quality Verification',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Grade: $_selectedGrade',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildInfoRow(
            icon: Icons.grass_rounded,
            label: 'Crop',
            value: item.crop,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.scale_rounded,
            label: 'Quantity',
            value: item.quantity,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.assignment_turned_in_rounded,
            label: 'Inspection Status',
            value: item.status == 'Quality Check' || item.status == 'Sampling'
                ? 'Under Inspection'
                : 'Inspected ($_selectedGrade)',
          ),
          const SizedBox(height: 14),

          // Quality Grade Selection Chips
          const Text(
            'Assay Result / Quality Grade:',
            style: TextStyle(
              fontSize: 12,
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
          const SizedBox(height: 12),

          // Quality Inspection Notes
          TextField(
            controller: _qualityNotesController,
            decoration: InputDecoration(
              labelText: 'Inspection / Moisture Notes',
              hintText: 'e.g. Moisture 11.2%, Foreign matter < 0.5%',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 14),

          // Quality Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _service.confirmQuality(
                      item.tokenNumber,
                      _selectedGrade,
                      notes: _qualityNotesController.text,
                    );
                  },
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
                child: ElevatedButton.icon(
                  onPressed: () {
                    _service.confirmQuality(
                      item.tokenNumber,
                      _selectedGrade,
                      notes: _qualityNotesController.text,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text(
                    'CONTINUE TO WEIGHMENT',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
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
            ],
          ),
        ],
      ),
    );
  }

  /// Stage 3: Weighment Card
  Widget _buildWeighmentCard(OfficerQueueItem item) {
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
                    'WEIGHMENT',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Units: Qtl / Quintal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Comparison Panel
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
                    const Text('Registered Quantity:'),
                    Text(
                      '${expectedQ.toStringAsFixed(2)} Qtl',
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
                      '${_actualWeight.toStringAsFixed(2)} Qtl',
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
                          ? '+${diff.toStringAsFixed(2)} Qtl'
                          : '${diff.toStringAsFixed(2)} Qtl',
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

          // Input controls: direct typing + stepper buttons
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Actual Weight (Qtl)',
                    hintText: '50.2',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) {
                    final d = double.tryParse(val);
                    if (d != null && d > 0) {
                      setState(() {
                        _actualWeight = d;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: AppColors.secondary),
                onPressed: () {
                  if (_actualWeight > 5.0) {
                    setState(() {
                      _actualWeight = double.parse(
                          (_actualWeight - 0.1).toStringAsFixed(1));
                      _weightController.text = _actualWeight.toStringAsFixed(1);
                    });
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: AppColors.secondary),
                onPressed: () {
                  setState(() {
                    _actualWeight = double.parse(
                        (_actualWeight + 0.1).toStringAsFixed(1));
                    _weightController.text = _actualWeight.toStringAsFixed(1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Discrepancy / Override Reason Audit Field
          if (diff.abs() > 0.05) ...[
            TextField(
              controller: _overrideReasonController,
              decoration: InputDecoration(
                labelText: 'Weight Discrepancy Reason (Audit Trail)',
                hintText: 'e.g. Moisture reduction or scale calibration',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              'Audit Note: Weight adjustment recorded with officer timestamp. Registered quantity (${expectedQ.toStringAsFixed(2)} Qtl) is preserved in audit records.',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _service.confirmWeighment(
                      item.tokenNumber,
                      _actualWeight,
                      overrideReason: _overrideReasonController.text,
                    );
                  },
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
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _service.confirmWeighment(
                      item.tokenNumber,
                      _actualWeight,
                      overrideReason: _overrideReasonController.text,
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text(
                    'CONTINUE TO SUMMARY',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
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
            ],
          ),
        ],
      ),
    );
  }

  /// Phase E: Read-only Weighment Audit Trail Card.
  /// Displays historical scale adjustments, officer attribution, timestamps, and reason.
  /// Immutable record: cannot be modified or overwritten from the UI.
  Widget _buildWeighmentAuditTrailCard(OfficerQueueItem item) {
    final audits = _service.getWeighmentAuditsForToken(item.tokenNumber);
    final expectedQ = double.tryParse(
            item.quantity.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        50.0;

    return Container(
      key: const Key('weighment_audit_trail_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: audits.isNotEmpty
              ? AppColors.secondary.withValues(alpha: 0.4)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.history_edu_rounded,
                      color: AppColors.secondary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'WEIGHMENT AUDIT TRAIL',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Read-Only (${audits.length} Entries)',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Immutable verification history of scale corrections and weight overrides.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          if (audits.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.textTertiary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No scale adjustments recorded yet. Registered weight: ${expectedQ.toStringAsFixed(2)} Qtl.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: audits.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final audit = audits[index];
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            audit.formattedDateTime,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: audit.difference >= 0
                                  ? AppColors.primaryContainer
                                  : AppColors.warningContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${audit.difference >= 0 ? "+" : ""}${audit.difference.toStringAsFixed(2)} Qtl (${audit.differencePercentage.toStringAsFixed(1)}%)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: audit.difference >= 0
                                    ? AppColors.primaryGreen
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Original Weight',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${audit.originalWeight.toStringAsFixed(2)} Qtl',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 16, color: AppColors.textTertiary),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Updated Weight',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${audit.updatedWeight.toStringAsFixed(2)} Qtl',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            'Changed By: ${audit.changedBy}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (audit.reason.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.comment_rounded,
                                size: 14, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Reason: ${audit.reason}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// Stage 4: Procurement Summary Card & Acceptance
  Widget _buildProcurementSummaryCard(OfficerQueueItem item) {
    final expectedQ = double.tryParse(
            item.quantity.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        50.0;
    final mspRate = PaymentCalculationService.getMspRate(item.crop);
    final calc = PaymentCalculationService.calculate(
      acceptedQuantity: _actualWeight,
      crop: item.crop,
      qualityGrade: _selectedGrade,
    );

    final isAlreadyAccepted = item.status == 'Accepted' ||
        item.status == 'Payment Pending' ||
        item.status == 'Completed';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryGreen,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROCUREMENT SUMMARY',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryGreen,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'Review all parameters before final acceptance.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAlreadyAccepted
                      ? AppColors.primaryContainer
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isAlreadyAccepted ? 'Accepted ✓' : 'Pending Acceptance',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isAlreadyAccepted
                        ? AppColors.primaryGreen
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),

          _buildInfoRow(
            icon: Icons.person_rounded,
            label: 'Farmer',
            value: '${item.farmerName} (Verified)',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.confirmation_number_rounded,
            label: 'Token',
            value: item.tokenNumber,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.grass_rounded,
            label: 'Crop',
            value: item.crop,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.scale_rounded,
            label: 'Registered Quantity',
            value: '${expectedQ.toStringAsFixed(2)} Qtl',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.check_circle_rounded,
            label: 'Actual Quantity',
            value: '${_actualWeight.toStringAsFixed(2)} Qtl',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.grade_rounded,
            label: 'Quality Grade',
            value: _selectedGrade,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            icon: Icons.store_rounded,
            label: 'Centre',
            value: 'Assigned procurement centre',
          ),
          const SizedBox(height: 10),

          // Benchmark Note (Transparent CCEA 2024-25 Pricing Benchmark)
          Container(
            padding: const EdgeInsets.all(12),
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
                    const Text(
                      'Reference Benchmark MSP:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '₹${mspRate.toStringAsFixed(0)} / Qtl',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'CCEA 2024-25 Benchmark Reference (Transparent statutory MSP rate, not live ticker)',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Divider(height: 14, color: AppColors.cardBorder),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Calculated Gross:'),
                    Text(
                      PaymentCalculationService.formatCurrency(calc.grossAmount),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Deductions:'),
                    Text(
                      PaymentCalculationService.formatCurrency(calc.deductions),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Net Payable Amount:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                    Text(
                      PaymentCalculationService.formatCurrency(calc.netPayable),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Acceptance Action Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: isAlreadyAccepted
                      ? null
                      : () {
                          _service.acceptProduce(item.tokenNumber);
                        },
                  icon: const Icon(Icons.verified_rounded, size: 20),
                  label: const Text(
                    'ACCEPT PROCUREMENT',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: isAlreadyAccepted
                      ? null
                      : () {
                          _service.acceptProduce(item.tokenNumber);
                        },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text(
                    'Accept Produce',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  /// Stage 5: Bill & Payment Readiness Card
  Widget _buildBillPaymentCard(OfficerQueueItem item) {
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        : (isProcessing
                            ? Colors.blue.shade800
                            : AppColors.secondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Acceptance Banner
          if (item.status == 'Accepted' || item.status == 'Completed') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryGreen),
              ),
              child: const Row(
                children: [
                  Icon(Icons.task_alt_rounded,
                      color: AppColors.primaryGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'PROCUREMENT ACCEPTED ✓',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

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
          const SizedBox(height: 10),
          const Text(
            'Payment lifecycle tracking only. Real PFMS/NPCI settlement occurs via Government treasury gateway.',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Payment Actions
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

  /// 7-Stage Procurement Lifecycle Card
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
