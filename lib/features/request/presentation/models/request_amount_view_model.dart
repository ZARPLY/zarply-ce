import 'package:flutter/material.dart';

import '../../domain/entities/payment_request.dart';

class RequestAmountViewModel extends ChangeNotifier {
  RequestAmountViewModel({
    this.recipientAddress,
    this.initialAmount,
  }) {
    if (initialAmount != null) {
      paymentAmountController.text = initialAmount!;
      isFormValid = true;
    }
    paymentAmountController.addListener(_updateFormValidity);
  }

  final String? recipientAddress;
  final String? initialAmount;
  final TextEditingController paymentAmountController = TextEditingController();
  bool isFormValid = false;

  @override
  void dispose() {
    paymentAmountController.dispose();
    super.dispose();
  }

  void _updateFormValidity() {
    final double amount = double.tryParse(
          paymentAmountController.text,
        ) ??
        0;
    isFormValid = paymentAmountController.text.isNotEmpty && amount >= 500;
    notifyListeners();
  }

  PaymentRequest createPaymentRequest(String walletAddress) {
    if (!isFormValid) {
      throw Exception('Cannot create payment request: form is invalid');
    }

    return PaymentRequest(
      amount: paymentAmountController.text,
      walletAddress: walletAddress,
    );
  }
}
