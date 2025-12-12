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
  bool _isLoading = false;
  bool isPasswordCorrect = false;

  bool get rememberPassword => _rememberPassword;
  bool get isLoading => _isLoading;

  static final RegExp complexity = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>]).+$');

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
        final bool valid = await validatePassword();
        setIsPasswordCorrect(value: valid);
      } catch (e) {
        // Handle error silently
        _rememberPassword = false;
        await _secureStorage.setRememberPassword(value: false);
      }
    }
    notifyListeners();
  }

  void setRememberPassword({required bool value}) {
    _rememberPassword = value;
    _secureStorage.setRememberPassword(value: value);
    if (!value) {
      // Clear the password field if remember password is disabled
      passwordController.clear();
      setIsPasswordCorrect(value: false);
    }
    notifyListeners();
  }

  void setKeyboardVisibility({required bool visible}) {
    isKeyboardVisible = visible;
    notifyListeners();
  }

  void setIsLoading({required bool value}) {
    _isLoading = value;
    notifyListeners();
  }

  void setIsPasswordCorrect({required bool value}) {
    isPasswordCorrect = value;
    notifyListeners();
  }

  Future<bool> validatePassword() async {
    try {
      if (passwordController.text.isEmpty) {
        errorMessage = 'Password required';
        return false;
      }
      if (passwordController.text.length < 8) {
        errorMessage = 'Password must be at least 8 characters';
        return false;
      }
      if (!complexity.hasMatch(passwordController.text)) {
        errorMessage = 'Password must include a letter, number, and special character';
        return false;
      }

      final String storedPin = await _secureStorage.getPin();
      if (passwordController.text == storedPin) {
        errorMessage = '';
        return true;
      } else {
        errorMessage = 'Incorrect password';
        return false;
      }
    } catch (e) {
      errorMessage = 'Error validating password';
      return false;
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }
}
