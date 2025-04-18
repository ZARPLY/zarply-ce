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
  String? _passwordErrorText;
  String? _confirmErrorText;

  bool get isChecked => _isChecked;
  bool get isFormValid => _isFormValid;
  String? get passwordErrorText => _passwordErrorText;
  String? get confirmErrorText => _confirmErrorText;

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
    final RegExp complexity = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>]).+$');
    if (passwordController.text.isEmpty) {
      if (confirmPasswordController.text.isNotEmpty) {
        _passwordErrorText = 'Password cannot be blank';
      } else {
        _passwordErrorText = null;
      }
        _confirmErrorText = null;
        _isFormValid = false;
    } else if(!complexity.hasMatch(passwordController.text)){
      _passwordErrorText = 'Password must include a letter, number, and special character';
      _confirmErrorText = null;
    } else if (confirmPasswordController.text.isEmpty) {
      _passwordErrorText = null;
      _confirmErrorText = null;
      _isFormValid = false;
    } else if(passwordController.text != confirmPasswordController.text){
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
    return await _repository.savePassword(passwordController.text);
  }
}
