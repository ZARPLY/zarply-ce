import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/widgets/shared/amount_input.dart';
import '../../domain/entities/payment_request.dart';
import '../models/request_amount_view_model.dart';
import '../widgets/request_review_content.dart';

class RequestAmountScreen extends StatelessWidget {
  const RequestAmountScreen({
    super.key,
  });

  void _showRequestReviewModal(BuildContext context, String amount) {
    final WalletProvider walletProvider =
        Provider.of<WalletProvider>(context, listen: false);
    final String walletAddress = walletProvider.wallet?.address ?? '';

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
        child: RequestReviewContent(
          paymentRequest: PaymentRequest(
            amount: amount,
            walletAddress: walletAddress,
          ),
          onCancel: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RequestAmountViewModel>(
      create: (_) => RequestAmountViewModel(),
      child: Consumer<RequestAmountViewModel>(
        builder: (BuildContext context, RequestAmountViewModel viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              leading: Padding(
                padding:
                    const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
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
              title: const Text('Request'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 40),
                  Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(minWidth: 250, maxWidth: 350),
                      child: AmountInput(
                        controller: viewModel.paymentAmountController,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text('Minimum amount is R5'),
                      SizedBox(
                        height: 40,
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: viewModel.isFormValid
                        ? () => _showRequestReviewModal(
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
