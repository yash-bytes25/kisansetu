import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'camera_device_helper.dart';

/// Web implementation using standard JS interop for device enumeration,
/// permission requests via getUserMedia, and localStorage preferred camera selection.
class _WebCameraDeviceHelper implements CameraDeviceHelper {
  static const String _kStorageKey = 'mobile_scanner_preferred_device_id';

  @override
  Future<CameraPermissionResult> requestPermission() async {
    try {
      final nav = globalContext['navigator'] as JSObject?;
      if (nav == null) {
        debugPrint('[KisanSetu Camera] Error: navigator is undefined on this browser');
        return CameraPermissionResult.error('Browser does not support navigator');
      }

      final mediaDevices = nav['mediaDevices'] as JSObject?;
      if (mediaDevices == null) {
        debugPrint('[KisanSetu Camera] Error: navigator.mediaDevices is undefined (insecure context or unsupported)');
        return CameraPermissionResult.error('navigator.mediaDevices is unavailable. Ensure HTTPS or localhost.');
      }
      debugPrint('[KisanSetu Camera] 1. navigator.mediaDevices exists and verified');

      // Create video constraint { video: true }
      final constraints = JSObject();
      constraints['video'] = true.toJS;

      debugPrint('[KisanSetu Camera] 2. getUserMedia({video: true}) is being called');
      final promise = mediaDevices.callMethod('getUserMedia'.toJS, constraints) as JSPromise?;
      if (promise == null) {
        debugPrint('[KisanSetu Camera] Error: getUserMedia returned null promise');
        return CameraPermissionResult.error('getUserMedia returned null promise');
      }

      debugPrint('[KisanSetu Camera] 3. Browser permission request triggered');
      final stream = await promise.toDart as JSObject?;
      debugPrint('[KisanSetu Camera] 3. Browser permission granted! MediaStream acquired.');

      // Stop warmup tracks immediately so camera hardware is released cleanly for MobileScanner
      if (stream != null) {
        try {
          final getTracksRes = stream.callMethod('getVideoTracks'.toJS) as JSArray?;
          if (getTracksRes != null) {
            final tracks = getTracksRes.toDart;
            for (final track in tracks) {
              if (track != null) {
                (track as JSObject).callMethod('stop'.toJS);
              }
            }
          }
          debugPrint('[KisanSetu Camera] 10. Warmup stream tracks cleanly stopped and released.');
        } catch (e) {
          debugPrint('[KisanSetu Camera] Note: stopping warmup tracks: $e');
        }
      }

      // 4. Enumerate available video input devices (labels are now populated because permission was granted)
      final cameras = await getAvailableCameras();
      debugPrint('[KisanSetu Camera] 4. Available video input devices found: ${cameras.length}');
      for (final cam in cameras) {
        debugPrint('[KisanSetu Camera] 4. Detected device: "${cam.label}" [ID: ${cam.deviceId}] (Front/BuiltIn: ${cam.isFrontOrBuiltIn})');
      }

      // For desktop Web, prioritize ASUS FHD webcam or front/built-in webcam
      if (cameras.isNotEmpty) {
        CameraDeviceInfo? selected;
        for (final cam in cameras) {
          final l = cam.label.toLowerCase();
          if (l.contains('asus') || l.contains('fhd') || l.contains('user-facing')) {
            selected = cam;
            break;
          }
        }
        selected ??= cameras.firstWhere(
          (c) => c.isFrontOrBuiltIn,
          orElse: () => cameras.first,
        );

        await setPreferredCamera(selected.deviceId);
        debugPrint('[KisanSetu Camera] 4. Selected device for MobileScanner: "${selected.label}" [ID: ${selected.deviceId}]');
      }

      return CameraPermissionResult.granted;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      debugPrint('[KisanSetu Camera] 8. JavaScript/DOMException from getUserMedia captured: $e');

      if (errStr.contains('notallowederror') ||
          errStr.contains('permissiondeniederror') ||
          errStr.contains('permission') ||
          errStr.contains('denied')) {
        return CameraPermissionResult.denied('Camera permission was denied by user or browser.');
      } else if (errStr.contains('notfounderror') ||
          errStr.contains('devicesnotfounderror') ||
          errStr.contains('no camera') ||
          errStr.contains('notfound')) {
        return CameraPermissionResult.noCamera('No camera hardware found on this machine.');
      } else if (errStr.contains('notreadableerror') ||
          errStr.contains('trackstarterror') ||
          errStr.contains('in use')) {
        return CameraPermissionResult.inUse('Camera is in use by another application.');
      } else {
        return CameraPermissionResult.error('Camera access failed: $e');
      }
    }
  }

  @override
  Future<List<CameraDeviceInfo>> getAvailableCameras() async {
    try {
      final nav = globalContext['navigator'] as JSObject?;
      if (nav == null) return [];
      final mediaDevices = nav['mediaDevices'] as JSObject?;
      if (mediaDevices == null) return [];

      final promise =
          mediaDevices.callMethod('enumerateDevices'.toJS) as JSPromise?;
      if (promise == null) return [];
      final jsDevices = await promise.toDart;
      if (jsDevices == null) return [];

      final devicesList = (jsDevices as JSArray).toDart;
      final List<CameraDeviceInfo> cameraList = [];
      var index = 1;

      for (final item in devicesList) {
        if (item != null) {
          final d = item as JSObject;
          final kind = (d['kind'] as JSString?)?.toDart;
          if (kind == 'videoinput') {
            final id = (d['deviceId'] as JSString?)?.toDart ?? '';
            final jsLabel = d['label'] as JSString?;
            var label = jsLabel != null ? jsLabel.toDart.trim() : '';
            if (label.isEmpty) {
              label = index == 1 ? 'Built-in Laptop Webcam' : 'Camera $index';
            }
            final l = label.toLowerCase();
            final isFront = l.contains('front') ||
                l.contains('integrated') ||
                l.contains('built-in') ||
                l.contains('internal') ||
                l.contains('asus') ||
                l.contains('user-facing') ||
                l.contains('facetime') ||
                index == 1;

            cameraList.add(
              CameraDeviceInfo(
                deviceId: id,
                label: label,
                isFrontOrBuiltIn: isFront,
              ),
            );
            index++;
          }
        }
      }
      return cameraList;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> setPreferredCamera(String deviceId) async {
    try {
      final storage = globalContext['localStorage'] as JSObject?;
      storage?.callMethod('setItem'.toJS, _kStorageKey.toJS, deviceId.toJS);
    } catch (_) {}
  }

  @override
  String? getPreferredCamera() {
    try {
      final storage = globalContext['localStorage'] as JSObject?;
      final result =
          storage?.callMethod('getItem'.toJS, _kStorageKey.toJS) as JSString?;
      return result?.toDart;
    } catch (_) {
      return null;
    }
  }
}

CameraDeviceHelper getCameraDeviceHelper() => _WebCameraDeviceHelper();
