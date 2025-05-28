import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _checkSessionOnStartup();
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _sessionKey = 'auth_session_expiry';

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  Timer? _expiryTimer;

  Future<void> login() async {
    final DateTime expiryTime = DateTime.now().add(const Duration(hours: 1));
    await _storage.write(
      key: _sessionKey,
      value: expiryTime.toIso8601String(),
    );

    _isAuthenticated = true;
    notifyListeners();

    _scheduleExpiryCheck(expiryTime);
  }

  Future<void> logout() async {
    await _storage.delete(key: _sessionKey);
    _isAuthenticated = false;
    _expiryTimer?.cancel();
    notifyListeners();
  }

  Future<void> _checkSessionOnStartup() async {
    final String? expiryString = await _storage.read(key: _sessionKey);
    if (expiryString == null) {
      await logout();
      return;
    }

    final DateTime expiryTime = DateTime.parse(expiryString);

    if (DateTime.now().isAfter(expiryTime)) {
      await logout();
    } else {
      _isAuthenticated = true;
      notifyListeners();

      _scheduleExpiryCheck(expiryTime);
    }
  }

  void _scheduleExpiryCheck(DateTime expiryTime) {
    _expiryTimer?.cancel();
    final Duration remaining = expiryTime.difference(DateTime.now());

    _expiryTimer = Timer(remaining, _handleSessionExpiry);
  }

  void _handleSessionExpiry() {
    logout();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }
}
