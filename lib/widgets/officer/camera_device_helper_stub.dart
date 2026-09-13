import 'camera_device_helper.dart';

/// Non-web fallback stub.
class _StubCameraDeviceHelper implements CameraDeviceHelper {
  @override
  Future<CameraPermissionResult> requestPermission() async {
    return CameraPermissionResult.granted;
  }

  @override
  Future<List<CameraDeviceInfo>> getAvailableCameras() async {
    return const [];
  }

  @override
  Future<void> setPreferredCamera(String deviceId) async {}

  @override
  String? getPreferredCamera() => null;
}

CameraDeviceHelper getCameraDeviceHelper() => _StubCameraDeviceHelper();
