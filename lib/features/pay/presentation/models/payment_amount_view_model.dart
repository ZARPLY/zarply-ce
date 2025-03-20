import 'package:flutter/material.dart';

class PaymentAmountViewModel extends ChangeNotifier {
  PaymentAmountViewModel({
    required this.recipientAddress,
    this.initialAmount,
  }) {
    if (initialAmount != null) {
      paymentAmountController.text = initialAmount!;
      isFormValid = true;
    }
    paymentAmountController.addListener(_updateFormValidity);
  }
  final TextEditingController paymentAmountController = TextEditingController();
  bool isFormValid = false;
  final String recipientAddress;
  final String? initialAmount;

  void _updateFormValidity() {
    final double amount = double.tryParse(paymentAmountController.text) ?? 0;
    isFormValid = paymentAmountController.text.isNotEmpty && amount >= 500;
    notifyListeners();
  }

  @override
  void dispose() {
    paymentAmountController.dispose();
    super.dispose();
  }
}
