import 'package:flutter/material.dart';

import '../../../../core/services/secure_storage_service.dart';

class CreatePasswordViewModel extends ChangeNotifier {
  CreatePasswordViewModel() {
    passwordController.addListener(_validateForm);
    confirmPasswordController.addListener(_validateForm);
  }
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final SecureStorageService _secureStorage = SecureStorageService();

  bool _isChecked = false;
  bool _isFormValid = false;
  String? _errorText;

  bool get isChecked => _isChecked;
  bool get isFormValid => _isFormValid;
  String? get errorText => _errorText;

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void setChecked({required bool value}) {
    _isChecked = value;
    _validateForm();
    notifyListeners();
  }

  void _validateForm() {
    if (passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _errorText = null;
      _isFormValid = false;
    } else if (passwordController.text != confirmPasswordController.text) {
      _errorText = 'Passwords do not match';
      _isFormValid = false;
    } else {
      _errorText = null;
      _isFormValid = _isChecked;
    }
    notifyListeners();
  }

  Future<bool> createPassword() async {
    if (!_isFormValid) return false;

    try {
      await _secureStorage.savePin(passwordController.text);
      return true;
    } catch (e) {
      return false;
    }
  }
}
