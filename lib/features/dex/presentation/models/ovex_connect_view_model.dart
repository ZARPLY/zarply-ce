import 'package:flutter/material.dart';

class OvexConnectViewModel extends ChangeNotifier {
  OvexConnectViewModel() {
    // Listen to text changes to validate form
    emailController.addListener(_validateForm);
    apiKeyController.addListener(_validateForm);
  }

  /// Validate form and update validity state
  void _validateForm() {
    final String email = emailController.text.trim();
    final String apiKey = apiKeyController.text.trim();

    final bool emailValid = email.isNotEmpty && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    final bool apiKeyValid = apiKey.isNotEmpty;

    _isFormValid = emailValid && apiKeyValid;
    notifyListeners();
  }

  final TextEditingController emailController = TextEditingController();
  final TextEditingController apiKeyController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isFormValid = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isFormValid => _isFormValid;

  void setIsLoading({required bool value}) {
    _isLoading = value;
    notifyListeners();
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Validate email format
  bool validateEmail() {
    final String email = emailController.text.trim();
    if (email.isEmpty) {
      setErrorMessage('Email is required');
      return false;
    }

    final bool isValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    if (!isValid) {
      setErrorMessage('Please enter a valid email address');
      return false;
    }

    setErrorMessage(null);
    return true;
  }

  /// Validate API key
  bool validateApiKey() {
    final String apiKey = apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setErrorMessage('API key is required');
      return false;
    }

    setErrorMessage(null);
    return true;
  }

  /// Connect to Ovex with provided credentials
  Future<bool> connectToOvex() async {
    if (!validateEmail() || !validateApiKey()) {
      return false;
    }

    setIsLoading(value: true);
    setErrorMessage(null);

    try {
      // TODO: Implement Ovex connection logic
      await Future.delayed(const Duration(seconds: 1));

      // TODO: Store credentials securely
      // Credentials storage removed - implement when needed

      setIsLoading(value: false);
      return true;
    } catch (e) {
      setErrorMessage('Failed to connect: ${e.toString()}');
      setIsLoading(value: false);
      return false;
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    apiKeyController.dispose();
    super.dispose();
  }
}
