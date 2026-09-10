import 'dart:async';
import 'package:flutter/foundation.dart';

/// Abstract contract for network connectivity monitoring and simulation.
///
/// Decouples business logic from specific network/connectivity plugins
/// so that actual connectivity listeners or simulated toggles can be swapped
/// without changing application logic.
abstract class ConnectivityService {
  bool get isOnline;
  ValueListenable<bool> get isOnlineListenable;
  Stream<bool> get onConnectivityChanged;
  void setOnline(bool online);
  void toggle();
}

/// Central application connectivity service implementation.
class AppConnectivityService extends ChangeNotifier
    implements ConnectivityService {
  static final AppConnectivityService instance =
      AppConnectivityService._internal();
  AppConnectivityService._internal();

  bool _isOnline = true;
  final ValueNotifier<bool> _isOnlineNotifier = ValueNotifier<bool>(true);
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  @override
  bool get isOnline => _isOnline;

  @override
  ValueListenable<bool> get isOnlineListenable => _isOnlineNotifier;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  void setOnline(bool online) {
    if (_isOnline == online) return;
    _isOnline = online;
    _isOnlineNotifier.value = online;
    _controller.add(online);
    notifyListeners();
  }

  @override
  void toggle() {
    setOnline(!_isOnline);
  }

  /// Reset to online state (e.g. for test cleanup).
  void reset() {
    _isOnline = true;
    _isOnlineNotifier.value = true;
    _controller.add(true);
    notifyListeners();
  }
}
