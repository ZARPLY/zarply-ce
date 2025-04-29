import 'package:flutter/material.dart';
import '../../../../core/services/secure_storage_service.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel() {
    _startSplashTimer();
  }
  final TextEditingController passwordController = TextEditingController();
  final SecureStorageService _secureStorage = SecureStorageService();
  String errorMessage = '';
  bool showSplash = true;
  bool isKeyboardVisible = false;

  static final RegExp complexity =
      RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>]).+$');

  void _startSplashTimer() {
    Future<void>.delayed(const Duration(seconds: 2), () {
      showSplash = false;
      notifyListeners();
    });
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
