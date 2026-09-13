import 'camera_device_helper_stub.dart'
    if (dart.library.js_interop) 'camera_device_helper_web.dart';

/// Representation of a physical or virtual camera device.
class CameraDeviceInfo {
  final String deviceId;
  final String label;
  final bool isFrontOrBuiltIn;

  const CameraDeviceInfo({
    required this.deviceId,
    required this.label,
    this.isFrontOrBuiltIn = false,
  });
}

/// Status of browser/device camera permission request.
enum CameraPermissionStatus {
  granted,
  denied,
  noCamera,
  inUse,
  error,
}

/// Result of requesting camera access with detailed diagnostic message.
class CameraPermissionResult {
  final CameraPermissionStatus status;
  final String? message;

  const CameraPermissionResult(this.status, [this.message]);

  static const granted =
      CameraPermissionResult(CameraPermissionStatus.granted);
  factory CameraPermissionResult.denied([String? msg]) =>
      CameraPermissionResult(CameraPermissionStatus.denied, msg);
  factory CameraPermissionResult.noCamera([String? msg]) =>
      CameraPermissionResult(CameraPermissionStatus.noCamera, msg);
  factory CameraPermissionResult.inUse([String? msg]) =>
      CameraPermissionResult(CameraPermissionStatus.inUse, msg);
  factory CameraPermissionResult.error(String msg) =>
      CameraPermissionResult(CameraPermissionStatus.error, msg);
}

/// Cross-platform helper interface to enumerate and set cameras.
abstract class CameraDeviceHelper {
  static CameraDeviceHelper get instance => getCameraDeviceHelper();

  Future<CameraPermissionResult> requestPermission();
  Future<List<CameraDeviceInfo>> getAvailableCameras();
  Future<void> setPreferredCamera(String deviceId);
  String? getPreferredCamera();
}
