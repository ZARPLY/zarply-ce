import 'package:flutter/material.dart';

class DexViewModel extends ChangeNotifier {
  DexViewModel() {
    _checkOvexConnection();
  }
  bool _isOvexConnected = false;

  bool get isOvexConnected => _isOvexConnected;

  Future<void> _checkOvexConnection() async {
    try {
      // TODO: Check Ovex connection status
      _isOvexConnected = false;
      notifyListeners();
    } catch (e) {
      print('DexViewModel: Error checking connection status: $e');
      _isOvexConnected = false;
      notifyListeners();
    }
  }

  /// Refresh the connection status
  Future<void> refreshConnectionStatus() async {
    await _checkOvexConnection();
  }

  /// Disconnect Ovex account
  Future<void> disconnectOvex() async {
    try {
      // TODO: Disconnect Ovex account
      _isOvexConnected = false;
      print('DexViewModel: Ovex account disconnected');
      notifyListeners();
    } catch (e) {
      print('DexViewModel: Error disconnecting Ovex: $e');
    }
  }
}
