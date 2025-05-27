import 'package:flutter/material.dart';
import '../../../../core/services/secure_storage_service.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel() {
    _startSplashTimer();
    _loadRememberPassword();
  }
  final TextEditingController passwordController = TextEditingController();
  final SecureStorageService _secureStorage = SecureStorageService();
  String errorMessage = '';
  bool showSplash = true;
  bool isKeyboardVisible = false;
  bool _rememberPassword = false;

  bool get rememberPassword => _rememberPassword;

  static final RegExp complexity =
      RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>]).+$');

  void _startSplashTimer() {
    Future<void>.delayed(const Duration(seconds: 2), () {
      showSplash = false;
      notifyListeners();
    });
  }

  Future<void> _loadRememberPassword() async {
    _rememberPassword = await _secureStorage.getRememberPassword();
    if (_rememberPassword) {
      try {
        final String storedPin = await _secureStorage.getPin();
        passwordController.text = storedPin;
        // Auto-validate password if remember password is enabled
        await validatePassword();
      } catch (e) {
        // Handle error silently
        _rememberPassword = false;
        await _secureStorage.setRememberPassword(false);
      }
    }
    notifyListeners();
  }

  void setRememberPassword(bool value) {
    _rememberPassword = value;
    _secureStorage.setRememberPassword(value);
    if (!value) {
      // Clear the password field if remember password is disabled
      passwordController.clear();
    }
    notifyListeners();
  }

  void setKeyboardVisibility({required bool visible}) {
    isKeyboardVisible = visible;
    notifyListeners();
  }

  Future<bool> validatePassword() async {
    if (passwordController.text.isEmpty) {
      errorMessage = 'Password required';
      notifyListeners();
      return false;
    }
    if (passwordController.text.length < 8) {
      errorMessage = 'Password must be at least 8 characters';
      notifyListeners();
      return false;
    }
    if (!complexity.hasMatch(passwordController.text)) {
      errorMessage =
          'Password must include a letter, number, and special character';
      notifyListeners();
      return false;
    }

    try {
      final String storedPin = await _secureStorage.getPin();
      if (passwordController.text == storedPin) {
        errorMessage = '';
        notifyListeners();
        return true;
      } else {
        errorMessage = 'Incorrect password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      errorMessage = 'Error validating password';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }
}
