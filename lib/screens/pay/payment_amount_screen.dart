import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/pay/payment_review_content.dart';
import '../../widgets/shared/amount_input.dart';

class PaymentAmountScreen extends StatefulWidget {
  const PaymentAmountScreen({
    required this.recipientAddress,
    super.key,
  });

  final String recipientAddress;

  @override
  State<PaymentAmountScreen> createState() => _PaymentAmountScreenState();
}

class _PaymentAmountScreenState extends State<PaymentAmountScreen> {
  final TextEditingController _paymentAmountController =
      TextEditingController();
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _paymentAmountController.addListener(_updateFormValidity);
  }

  @override
  void dispose() {
    _paymentAmountController.dispose();
    super.dispose();
  }

  void _updateFormValidity() {
    setState(() {
      final double amount = double.tryParse(
            _paymentAmountController.text,
          ) ??
          0;
      _isFormValid = _paymentAmountController.text.isNotEmpty && amount >= 500;
    });
  }

  void _showPaymentReviewModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => Container(
        height: MediaQuery.of(context).size.height * 0.90,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: PaymentReviewContent(
          amount: _paymentAmountController.text,
          recipientAddress: widget.recipientAddress,
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
          child: InkWell(
            onTap: () => context.go('/pay-request'),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEBECEF),
                borderRadius: BorderRadius.circular(80),
              ),
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        title: const Text('Pay'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 40),
            AmountInput(controller: _paymentAmountController),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Text('Minimum amount is R5'),
                const SizedBox(height: 24),
                Container(
                  constraints:
                      const BoxConstraints(minWidth: 200, maxWidth: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBECEF),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    widget.recipientAddress,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                const Text('Previously paid'),
                const SizedBox(
                  height: 12,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Text('R43,134.78'),
                    ),
                    const SizedBox(width: 16),
                    const Text('2024-12-22'),
                  ],
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isFormValid ? _showPaymentReviewModal : null,
              style: ElevatedButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Continue'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
