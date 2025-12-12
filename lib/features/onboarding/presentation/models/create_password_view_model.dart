import 'package:flutter/material.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../data/repositories/create_password_repository_impl.dart';
import '../../domain/repositories/create_password_repository.dart';

class CreatePasswordViewModel extends ChangeNotifier {
  CreatePasswordViewModel({CreatePasswordRepository? repository})
    : _repository = repository ?? CreatePasswordRepositoryImpl() {
    passwordController.addListener(_validateForm);
    confirmPasswordController.addListener(_validateForm);
  }

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final CreatePasswordRepository _repository;
  final SecureStorageService _secureStorage = SecureStorageService();

  bool _isChecked = false;
  bool _isFormValid = false;
  bool _rememberPassword = false;
  bool _isLoading = false;
  String? _passwordErrorText;
  String? _confirmErrorText;

  bool get isChecked => _isChecked;
  bool get isFormValid => _isFormValid;
  bool get rememberPassword => _rememberPassword;
  bool get isLoading => _isLoading;
  String? get passwordErrorText => _passwordErrorText;
  String? get confirmErrorText => _confirmErrorText;

  static final RegExp complexity = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>]).+$');

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

  void setRememberPassword({required bool value}) {
    _rememberPassword = value;
    notifyListeners();
  }

  void _validateForm() {
    _passwordErrorText = null;
    _confirmErrorText = null;
    _isFormValid = false;

    if (passwordController.text.isEmpty) {
      if (confirmPasswordController.text.isNotEmpty) {
        _passwordErrorText = 'Password cannot be blank';
      } else {
        _passwordErrorText = null;
      }
      _confirmErrorText = null;
      _isFormValid = false;
    } else if (passwordController.text.length < 8) {
      _passwordErrorText = 'Password must be at least 8 characters';
      _confirmErrorText = null;
      _isFormValid = false;
    } else if (!complexity.hasMatch(passwordController.text)) {
      _passwordErrorText = 'Password must include a letter, number, and special character';
      _confirmErrorText = null;
      _isFormValid = false;
    } else if (confirmPasswordController.text.isEmpty) {
      _passwordErrorText = null;
      _confirmErrorText = null;
      _isFormValid = false;
    } else if (passwordController.text != confirmPasswordController.text) {
      _passwordErrorText = null;
      _confirmErrorText = 'Passwords do not match';
      _isFormValid = false;
    } else {
      _passwordErrorText = null;
      _confirmErrorText = null;
      _isFormValid = _isChecked;
    }
    notifyListeners();
  }

  Future<bool> createPassword() async {
    if (!_isFormValid) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final bool success = await _repository.savePassword(passwordController.text);
      if (success && _rememberPassword) {
        await _secureStorage.setRememberPassword(value: true);
      }
      return success;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
