import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/shared/amount_input.dart';
import '../models/payment_amount_view_model.dart';
import '../widgets/payment_review_content.dart';

class PaymentAmountScreen extends StatelessWidget {
  const PaymentAmountScreen({
    required this.recipientAddress,
    required this.source,
    this.initialAmount,
    super.key,
  });

  final String recipientAddress;
  final String? initialAmount;
  final String source;

  void _showPaymentReviewModal(BuildContext context, String amount) {
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
          amount: amount,
          recipientAddress: recipientAddress,
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaymentAmountViewModel>(
      create: (_) => PaymentAmountViewModel(
        recipientAddress: recipientAddress,
        initialAmount: initialAmount,
      ),
      child: Consumer<PaymentAmountViewModel>(
        builder: (BuildContext context, PaymentAmountViewModel viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              leading: Padding(
                padding:
                    const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
                child: InkWell(
                  onTap: () => context.go(source),
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
                  AmountInput(controller: viewModel.paymentAmountController),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const Text('Minimum amount is R5'),
                      const SizedBox(height: 24),
                      Container(
                        constraints:
                            const BoxConstraints(minWidth: 250, maxWidth: 350),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBECEF),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Text(
                          viewModel.recipientAddress,
                          textAlign: TextAlign.center,
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
                    onPressed: viewModel.isFormValid
                        ? () => _showPaymentReviewModal(
                              context,
                              viewModel.paymentAmountController.text,
                            )
                        : null,
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
        },
      ),
    );
  }
}
