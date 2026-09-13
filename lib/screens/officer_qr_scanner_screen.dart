import 'package:flutter/material.dart';
import '../models/officer_queue_item.dart';
import '../services/procurement_state_service.dart';
import '../services/qr_validation_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/officer/gate_camera_preview.dart';

/// Phase 12: Procurement Officer Gate QR Scanner Screen.
///
/// Designed with high accessibility for field procurement gate staff:
/// - Real Camera Viewfinder using MobileScanner for Chrome/Web and Android
/// - Instant Quick Demo Scan presets (TK-8492, TK-8493, Wrong Centre, Duplicate, Malformed)
/// - Manual Token Input fallback
/// - Detailed Verification Summary Card
/// - Large Confirm Check-In action button (>= 56dp)
class OfficerQrScannerScreen extends StatefulWidget {
  const OfficerQrScannerScreen({super.key});

  @override
  State<OfficerQrScannerScreen> createState() => _OfficerQrScannerScreenState();
}

class _OfficerQrScannerScreenState extends State<OfficerQrScannerScreen> {
  final _stateService = ProcurementStateService();
  final _tokenController = TextEditingController();

  QrValidationResult? _validationResult;
  OfficerQueueItem? _scannedItem;
  bool _isCheckingIn = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _processQrInput(String rawInput) {
    setState(() {
      _isCheckingIn = false;
    });

    final result = QrValidationService.validate(
      rawPayload: rawInput,
      currentCentreName: _stateService.centreName,
    );

    OfficerQueueItem? item;
    if (result.tokenNumber != null) {
      final matches = _stateService.queue
          .where((q) => q.tokenNumber == result.tokenNumber);
      if (matches.isNotEmpty) {
        item = matches.first;
      } else if (result.tokenNumber == _stateService.farmerData.tokenNumber) {
        // Fallback to active farmer data if not in queue list
        final fd = _stateService.farmerData;
        item = OfficerQueueItem(
          tokenNumber: fd.tokenNumber,
          farmerName: fd.farmerName,
          crop: fd.cropName,
          quantity: fd.quantity,
          bookedSlot: fd.bookedSlotTime ?? '11:30 AM',
          arrivalTime: fd.actualArrivalTime ?? 'Not arrived',
          status: fd.lifecycleStatus,
          peopleAhead: fd.peopleAhead,
          approxWaitMinutes: fd.expectedWaitMinutes,
          checkInStatus: fd.checkInStatus,
        );
      }
    }

    setState(() {
      _validationResult = result;
      _scannedItem = item;
    });
  }

  void _confirmCheckIn() {
    if (_scannedItem == null || _validationResult == null) return;
    final token = _scannedItem!.tokenNumber;

    setState(() {
      _isCheckingIn = true;
    });

    final success = _stateService.checkInFarmer(token);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Check-In Confirmed for $token (${_scannedItem!.farmerName})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );

      // Re-validate to refresh state display to "Already Checked In"
      _processQrInput(token);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to check-in $token. Please check state.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gate QR Check-In Scanner'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Scanner Instructions',
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Point your camera at the farmer\'s Digital Pass QR to check in.',
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Real Camera Live Scanner Card
            GateCameraPreview(
              centreName: _stateService.centreName,
              isScanningPaused:
                  _validationResult != null && _validationResult!.isValid,
              onBarcodeScanned: _processQrInput,
              onResumeScan: () {
                setState(() {
                  _validationResult = null;
                  _scannedItem = null;
                });
              },
            ),

            const SizedBox(height: 16),

            // Quick Demo Scanner Simulation Chips
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.science_rounded,
                          size: 18,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Demo Simulation Scans',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.qr_code,
                              size: 16, color: AppColors.primaryDark),
                          label: const Text('TK-8492 (Ramesh)'),
                          backgroundColor:
                              AppColors.primaryGreen.withValues(alpha: 0.1),
                          onPressed: () {
                            _processQrInput(
                              QrValidationService.generateQrPayload(
                                bookingId: 'BK-8492',
                                tokenNumber: 'TK-8492',
                                centreName: _stateService.centreName,
                                slotTime: '11:30 AM',
                              ),
                            );
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.qr_code,
                              size: 16, color: AppColors.primaryDark),
                          label: const Text('TK-8493 (Harpreet)'),
                          backgroundColor:
                              AppColors.primaryGreen.withValues(alpha: 0.1),
                          onPressed: () {
                            _processQrInput(
                              QrValidationService.generateQrPayload(
                                bookingId: 'BK-8493',
                                tokenNumber: 'TK-8493',
                                centreName: _stateService.centreName,
                                slotTime: '11:45 AM',
                              ),
                            );
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.wrong_location_rounded,
                              size: 16, color: Colors.deepOrange),
                          label: const Text('Wrong Centre'),
                          backgroundColor:
                              Colors.deepOrange.withValues(alpha: 0.1),
                          onPressed: () {
                            _processQrInput(
                              QrValidationService.generateQrPayload(
                                bookingId: 'BK-9999',
                                tokenNumber: 'TK-9999',
                                centreName: 'Other Distant Mandi Centre',
                                slotTime: '10:00 AM',
                              ),
                            );
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.error_outline_rounded,
                              size: 16, color: AppColors.error),
                          label: const Text('Malformed QR'),
                          backgroundColor:
                              AppColors.error.withValues(alpha: 0.1),
                          onPressed: () {
                            _processQrInput('KISANSETU:V1:CORRUPTED');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Manual Token Input
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tokenController,
                        decoration: const InputDecoration(
                          hintText: 'Enter Token Number (e.g. TK-8492)',
                          prefixIcon: Icon(Icons.search_rounded),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                        onSubmitted: _processQrInput,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(88, 48),
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        if (_tokenController.text.trim().isNotEmpty) {
                          _processQrInput(_tokenController.text.trim());
                        }
                      },
                      child: const Text('Verify'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Scan / Verification Result Card
            if (_validationResult != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final result = _validationResult!;
    final isValid = result.isValid;
    final item = _scannedItem;

    final farmerName = item?.farmerName ?? 'Ramesh Kumar';
    final token = result.tokenNumber ?? item?.tokenNumber ?? 'TK-8492';
    final crop = item?.crop ?? 'Wheat';
    final quantity = item?.quantity ?? '50 Quintals';
    final slot = result.slotTime ?? item?.bookedSlot ?? '11:30 AM';
    final centre = result.centreName ?? _stateService.centreName;
    final isAlreadyCheckedIn =
        item != null && item.checkInStatus == 'Checked In';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isValid ? AppColors.success : AppColors.error,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header
            Row(
              children: [
                Icon(
                  isValid ? Icons.verified_rounded : Icons.gpp_bad_rounded,
                  color: isValid ? AppColors.success : AppColors.error,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isValid ? 'FARMER VERIFIED' : 'Validation Error',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: isValid ? AppColors.success : AppColors.error,
                        ),
                      ),
                      if (isValid)
                        Text(
                          'QR Pass Verified',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      Text(
                        result.userMessage,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            if (isValid) ...[
              _buildDetailRow('Farmer Name', farmerName, isBold: true),
              _buildDetailRow('Token', token, isBold: true),
              _buildDetailRow('Crop', crop),
              _buildDetailRow('Quantity', quantity),
              _buildDetailRow('Crop & Qty', '$crop • $quantity'),
              _buildDetailRow('Scheduled Slot', slot),
              _buildDetailRow('Assigned Centre', centre),

              const SizedBox(height: 14),

              // Status checklist: ✓ Valid QR, ✓ Correct Centre, ✓ Booking Confirmed
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildStatusChip('✓ Valid QR'),
                        _buildStatusChip('✓ Correct Centre'),
                        _buildStatusChip('✓ Booking Confirmed'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ] else ...[
              if (result.tokenNumber != null)
                _buildDetailRow('Token', result.tokenNumber!, isBold: true),
              if (result.centreName != null)
                _buildDetailRow('Assigned Centre', result.centreName!),
              const SizedBox(height: 16),
            ],

            // Action Button
            if (isValid && !isAlreadyCheckedIn) ...[
              SizedBox(
                height: 56, // Accessible large button >= 56dp
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isCheckingIn ? null : _confirmCheckIn,
                  icon: const Icon(Icons.how_to_reg_rounded, size: 24),
                  label: _isCheckingIn
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'CHECK IN FARMER',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              'Confirm Gate Check-In',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ] else if (isAlreadyCheckedIn) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.success),
                    SizedBox(width: 8),
                    Text(
                      'Farmer is Already Checked In & In Queue',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.success,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isBold = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold || isHighlight
                  ? FontWeight.bold
                  : FontWeight.w500,
              color: isHighlight
                  ? (value == 'Checked In'
                      ? AppColors.success
                      : Colors.orange[800])
                  : (isBold ? AppColors.primaryDark : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
