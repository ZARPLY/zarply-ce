import 'package:flutter/material.dart';
import '../../data/repositories/create_password_repository_impl.dart';
import '../../domain/repositories/create_password_repository.dart';

class CreatePasswordViewModel extends ChangeNotifier {
  CreatePasswordViewModel({CreatePasswordRepository? repository})
      : _repository = repository ?? CreatePasswordRepositoryImpl() {
    passwordController.addListener(_validateForm);
    confirmPasswordController.addListener(_validateForm);
  }

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final CreatePasswordRepository _repository;

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
    return await _repository.savePassword(passwordController.text);
  }
}
