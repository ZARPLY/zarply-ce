import 'package:flutter/material.dart';

class PaymentDetailsViewModel extends ChangeNotifier {
  PaymentDetailsViewModel() {
    publicKeyController.addListener(_updateFormValidity);
    descriptionController.addListener(_updateFormValidity);
  }
  final TextEditingController publicKeyController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool isFormValid = false;
  String? publicKeyError;

  @override
  void dispose() {
    publicKeyController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _updateFormValidity() {
    final String publicKey = publicKeyController.text;

    if (publicKey.isEmpty) {
      publicKeyError = 'Public key is required';
    } else if (publicKey.length < 32) {
      publicKeyError = 'Invalid public key format';
    } else {
      publicKeyError = null;
    }

    isFormValid = publicKeyError == null && publicKeyController.text.isNotEmpty;
    notifyListeners();
  }
}
