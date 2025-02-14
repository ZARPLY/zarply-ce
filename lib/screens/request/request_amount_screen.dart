import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/request/request_review_content.dart';
import '../../widgets/shared/amount_input.dart';

class RequestAmountScreen extends StatefulWidget {
  const RequestAmountScreen({
    super.key,
  });

  @override
  State<RequestAmountScreen> createState() => _RequestAmountScreenState();
}

class _RequestAmountScreenState extends State<RequestAmountScreen> {
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
      _isFormValid = _paymentAmountController.text.isNotEmpty && amount >= 5;
    });
  }

  void _showPaymentReviewModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.90,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: RequestReviewContent(
            amount: _paymentAmountController.text,
            onCancel: () => Navigator.pop(context),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
          child: InkWell(
            onTap: () => context.go('/pay_request'),
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
