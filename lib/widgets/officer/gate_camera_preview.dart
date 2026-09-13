import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'camera_device_helper.dart';

/// Phase B: Real Camera-Based Viewfinder and QR Scanner for Gate Check-In.
///
/// Features:
/// - Real camera feed using [MobileScanner] on Web (Chrome) & Android
/// - Defaults to laptop webcam on Web (`CameraFacing.front`), rear camera on mobile
/// - External USB webcam / multiple camera detection and switching
/// - Clear live states: Initializing, Requesting Permission, Ready, Denied, No Camera, Paused
/// - In-viewfinder animated scan line and reticle frame
/// - Automatic pause upon QR detection with debounce to prevent duplicates
/// - Headless test fallbacks and state simulation for widget tests
class GateCameraPreview extends StatefulWidget {
  final void Function(String rawPayload) onBarcodeScanned;
  final bool isScanningPaused;
  final VoidCallback? onResumeScan;
  final String centreName;

  // Test state simulation overrides
  final bool? testPermissionDenied;
  final bool? testNoCamera;
  final String? testErrorMessage;
  final bool? testInitializing;

  const GateCameraPreview({
    super.key,
    required this.onBarcodeScanned,
    required this.isScanningPaused,
    required this.centreName,
    this.onResumeScan,
    this.testPermissionDenied,
    this.testNoCamera,
    this.testErrorMessage,
    this.testInitializing,
  });

  @override
  State<GateCameraPreview> createState() => _GateCameraPreviewState();
}

class _GateCameraPreviewState extends State<GateCameraPreview>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanLineController;
  MobileScannerController? _controller;
  Timer? _timeoutTimer;

  bool _isTorchOn = false;
  bool _isPermissionDenied = false;
  bool _isNoCameraDetected = false;
  bool _isInitializing = true;
  String? _errorMessage;
  DateTime? _lastScannedTimestamp;

  List<CameraDeviceInfo> _availableCameras = [];
  String? _selectedCameraId;

  bool get _isTestEnvironment =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (!_isTestEnvironment) {
      _scanLineController.repeat(reverse: true);
      _startCameraSequence();
    } else {
      _isInitializing = false;
    }
  }

  Future<void> _loadAvailableCameras() async {
    try {
      final cameras = await CameraDeviceHelper.instance.getAvailableCameras();
      if (mounted) {
        setState(() {
          _availableCameras = cameras;
          _selectedCameraId =
              CameraDeviceHelper.instance.getPreferredCamera() ??
                  (cameras.isNotEmpty ? cameras.first.deviceId : null);
        });
      }
    } catch (_) {}
  }

  Future<void> _startCameraSequence() async {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    if (!mounted) return;
    setState(() {
      _isInitializing = true;
      _isPermissionDenied = false;
      _isNoCameraDetected = false;
      _errorMessage = null;
    });

    debugPrint('[KisanSetu Camera] Starting camera initialization sequence...');

    // 1-3. For web, explicitly verify mediaDevices and trigger getUserMedia
    if (kIsWeb) {
      final permResult = await CameraDeviceHelper.instance.requestPermission();
      if (!mounted) return;

      if (permResult.status == CameraPermissionStatus.denied) {
        debugPrint('[KisanSetu Camera] Permission denied by user or browser.');
        setState(() {
          _isPermissionDenied = true;
          _isInitializing = false;
        });
        return;
      } else if (permResult.status == CameraPermissionStatus.noCamera) {
        debugPrint('[KisanSetu Camera] No camera device found.');
        setState(() {
          _isNoCameraDetected = true;
          _isInitializing = false;
        });
        return;
      } else if (permResult.status == CameraPermissionStatus.error ||
          permResult.status == CameraPermissionStatus.inUse) {
        debugPrint('[KisanSetu Camera] Camera error: ${permResult.message}');
        setState(() {
          _errorMessage = permResult.message ?? 'Failed to access camera';
          _isInitializing = false;
        });
        return;
      }
    }

    // 4. Load available cameras
    await _loadAvailableCameras();
    if (!mounted) return;

    // 5. Initialize MobileScannerController
    debugPrint('[KisanSetu Camera] 5. Initializing MobileScannerController...');
    _disposeController();

    final controller = MobileScannerController(
      autoStart: true,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: kIsWeb ? CameraFacing.front : CameraFacing.back,
      torchEnabled: false,
    );

    controller.addListener(() {
      if (!mounted) return;
      if (controller.value.isInitialized && _isInitializing) {
        debugPrint(
            '[KisanSetu Camera] 6. Camera stream actually started! Frame size: ${controller.value.size}');
        debugPrint(
            '[KisanSetu Camera] 7. Live video stream is being rendered in GateCameraPreview');
        _timeoutTimer?.cancel();
        _timeoutTimer = null;
        setState(() {
          _isInitializing = false;
        });
        _loadAvailableCameras();
      }
    });

    // 9. Timeout guard: cannot remain indefinitely stuck on "Initializing Camera"
    _timeoutTimer = Timer(const Duration(seconds: 12), () {
      if (mounted && _isInitializing) {
        debugPrint('[KisanSetu Camera] 9. Camera initialization timed out after 12 seconds.');
        setState(() {
          _isInitializing = false;
          _errorMessage =
              'Camera initialization timed out. Please check permissions or if another app is using the webcam and tap Retry.';
        });
      }
    });

    setState(() {
      _controller = controller;
    });
  }

  void _disposeController() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    try {
      _controller?.dispose();
    } catch (e) {
      debugPrint('[KisanSetu Camera] 10. Note on disposing controller: $e');
    }
    _controller = null;
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _scanLineController.dispose();
    _disposeController();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (widget.isScanningPaused) return;

    final now = DateTime.now();
    if (_lastScannedTimestamp != null &&
        now.difference(_lastScannedTimestamp!) < const Duration(seconds: 2)) {
      // Debounce duplicate scans within 2 seconds
      return;
    }

    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.trim().isNotEmpty) {
        _lastScannedTimestamp = now;
        widget.onBarcodeScanned(raw.trim());
        break;
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_controller == null || _isTestEnvironment) return;
    try {
      await _controller!.switchCamera();
      setState(() {});
    } catch (e) {
      debugPrint('Failed to switch camera: $e');
    }
  }

  Future<void> _selectCamera(CameraDeviceInfo camera) async {
    debugPrint('[KisanSetu Camera] Selecting camera: ${camera.label} [${camera.deviceId}]');
    await CameraDeviceHelper.instance.setPreferredCamera(camera.deviceId);
    if (mounted) {
      setState(() {
        _selectedCameraId = camera.deviceId;
      });
      _retryCamera();
    }
  }

  Future<void> _toggleTorch() async {
    if (_controller == null || _isTestEnvironment) {
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
      return;
    }

    try {
      await _controller!.toggleTorch();
      setState(() {
        _isTorchOn = !_isTorchOn;
      });
    } catch (e) {
      debugPrint('Failed to toggle torch: $e');
    }
  }

  Future<void> _retryCamera() async {
    debugPrint('[KisanSetu Camera] 10. Disposing existing camera resources before retry...');
    _disposeController();
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _startCameraSequence();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInitializing = widget.testInitializing ?? _isInitializing;
    final isPermissionDenied =
        widget.testPermissionDenied ?? _isPermissionDenied;
    final isNoCamera = widget.testNoCamera ?? _isNoCameraDetected;
    final errorMessage = widget.testErrorMessage ?? _errorMessage;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      color: Colors.black,
      child: SizedBox(
        height: 360,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Live Camera Stream / Fallback / Error
            if (widget.testInitializing == true)
              _buildLoadingView()
            else if (_isTestEnvironment &&
                !isPermissionDenied &&
                !isNoCamera &&
                errorMessage == null)
              _buildTestPlaceholder()
            else if (isPermissionDenied)
              _buildPermissionDeniedView()
            else if (isNoCamera)
              _buildNoCameraView()
            else if (errorMessage != null)
              _buildErrorView(errorMessage)
            else
              _buildLiveScanner(),

            // 2. Viewfinder Reticle & Animated Scan Line Overlay
            if (!isPermissionDenied &&
                !isNoCamera &&
                errorMessage == null &&
                !isInitializing)
              _buildScannerReticle(),

            // 3. Top Controls Bar (Camera Switch, Torch, Live Badge)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _buildTopControlsBar(),
            ),

            // 4. Bottom Information Advisory Banner
            Positioned(
              bottom: 12,
              left: 16,
              right: 16,
              child: _buildBottomAdvisory(),
            ),

            // 5. Scan Paused / Processing Overlay
            if (widget.isScanningPaused)
              Positioned.fill(child: _buildPausedOverlay()),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveScanner() {
    if (_controller == null) return _buildLoadingView();

    return MobileScanner(
      controller: _controller!,
      fit: BoxFit.cover,
      onDetect: _handleBarcode,
      placeholderBuilder: (context) => _buildLoadingView(),
      errorBuilder: (context, error) {
        debugPrint(
            '[KisanSetu Camera] 8. MobileScanner error captured: ${error.errorCode} - ${error.errorDetails?.message ?? error.toString()}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final errStr =
              (error.errorDetails?.message ?? error.toString()).toLowerCase();
          if (error.errorCode == MobileScannerErrorCode.permissionDenied ||
              errStr.contains('notallowederror') ||
              errStr.contains('permission')) {
            setState(() {
              _isPermissionDenied = true;
              _isInitializing = false;
            });
          } else if (error.errorCode == MobileScannerErrorCode.unsupported ||
              errStr.contains('notfounderror') ||
              errStr.contains('devicesnotfounderror') ||
              errStr.contains('no camera') ||
              errStr.contains('no media')) {
            setState(() {
              _isNoCameraDetected = true;
              _isInitializing = false;
            });
          } else {
            setState(() {
              _errorMessage = error.errorDetails?.message ?? error.toString();
              _isInitializing = false;
            });
          }
        });
        return _buildErrorView(
            error.errorDetails?.message ?? 'Camera initialization failed.');
      },
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentAmber),
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Initializing Camera...',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            const Text(
              'Requesting browser/device camera permission',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestPlaceholder() {
    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_scanner, size: 48, color: Colors.white38),
          const SizedBox(height: 8),
          Text(
            'Live Viewfinder Active',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedView() {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.videocam_off_rounded,
                size: 36,
                color: AppColors.accentAmber,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Camera Access Blocked',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Camera access is blocked. Allow Camera permission for KisanSetu in Chrome site settings or device Settings and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _retryCamera,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry Camera'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCameraView() {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.no_photography_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Camera Detected',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No video input device found on this laptop/device.\nPlease connect a USB webcam and retry.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _retryCamera,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry Camera'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Camera Unavailable',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _retryCamera,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry Camera'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerReticle() {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 210,
          height: 210,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.accentAmber,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Corner Accent Lines
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white, width: 4),
                      left: BorderSide(color: Colors.white, width: 4),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white, width: 4),
                      right: BorderSide(color: Colors.white, width: 4),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white, width: 4),
                      left: BorderSide(color: Colors.white, width: 4),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white, width: 4),
                      right: BorderSide(color: Colors.white, width: 4),
                    ),
                  ),
                ),
              ),

              // Animated Scan Line
              if (!widget.isScanningPaused)
                AnimatedBuilder(
                  animation: _scanLineController,
                  builder: (context, child) {
                    return Positioned(
                      top: _scanLineController.value * 190,
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: AppColors.accentAmber,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.accentAmber.withValues(alpha: 0.8),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopControlsBar() {
    final hasMultipleCameras = _availableCameras.length > 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Live Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isScanningPaused
                  ? Colors.orangeAccent
                  : AppColors.success,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isScanningPaused
                      ? Colors.orangeAccent
                      : AppColors.success,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.isScanningPaused ? 'PAUSED' : 'LIVE CAMERA',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),

        // Controls: Switch Camera & Torch
        Row(
          children: [
            if (hasMultipleCameras)
              PopupMenuButton<String>(
                tooltip:
                    'Select Camera (${_availableCameras.length} available)',
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cameraswitch_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onSelected: (deviceId) async {
                  final cam = _availableCameras
                      .firstWhere((c) => c.deviceId == deviceId);
                  await _selectCamera(cam);
                },
                itemBuilder: (context) => _availableCameras.map((cam) {
                  final isSelected = cam.deviceId == _selectedCameraId;
                  return PopupMenuItem<String>(
                    value: cam.deviceId,
                    child: Row(
                      children: [
                        Icon(
                          cam.isFrontOrBuiltIn
                              ? Icons.camera_front_rounded
                              : Icons.usb_rounded,
                          size: 18,
                          color: isSelected
                              ? AppColors.primaryGreen
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cam.label,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color:
                                  isSelected ? AppColors.primaryGreen : null,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check,
                              size: 16, color: AppColors.primaryGreen),
                      ],
                    ),
                  );
                }).toList(),
              )
            else
              IconButton(
                tooltip: 'Switch Camera',
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cameraswitch_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: _switchCamera,
              ),
            IconButton(
              tooltip: _isTorchOn ? 'Turn Flash Off' : 'Turn Flash On',
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: _isTorchOn ? AppColors.accentAmber : Colors.white,
                  size: 20,
                ),
              ),
              onPressed: _toggleTorch,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomAdvisory() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Scan Farmer QR',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Point the camera at the farmer\'s Digital Pass QR (${widget.centreName})',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPausedOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 32,
              ),
              const SizedBox(height: 8),
              const Text(
                'QR Scanned',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Review details below or resume scanner',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (widget.onResumeScan != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                  ),
                  onPressed: widget.onResumeScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                  label: const Text('Scan Another QR'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
