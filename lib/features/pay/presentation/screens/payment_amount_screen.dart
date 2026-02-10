import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/provider/payment_provider.dart';
import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/widgets/initializer/app_initializer.dart';
import '../../../../core/widgets/previously_paid_info.dart';
import '../../../../core/widgets/shared/amount_input.dart';
import '../../../wallet/data/repositories/wallet_repository_impl.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import '../models/payment_amount_view_model.dart';
import '../widgets/payment_review_content.dart';

class PaymentAmountScreen extends StatefulWidget {
  const PaymentAmountScreen({
    required this.recipientAddress,
    required this.source,
    this.initialAmount,
    super.key,
  });

  final String recipientAddress;
  final String? initialAmount;
  final String source;

  @override
  State<PaymentAmountScreen> createState() => _PaymentAmountScreenState();
}

class _PaymentAmountScreenState extends State<PaymentAmountScreen> {
  final FocusNode _amountFocus = FocusNode();

  @override
  void dispose() {
    _amountFocus.dispose();
    super.dispose();
  }

  Future<void> _showPaymentReviewModal(String amount) async {
    // Refresh balance before showing modal to ensure accuracy
    final WalletProvider walletProvider = Provider.of<WalletProvider>(context, listen: false);
    double walletBalance = AppInitializer.of(context).walletBalance;

    // Try to get fresh balance if token account exists
    if (walletProvider.userTokenAccount != null) {
      try {
        final WalletRepository walletRepository = WalletRepositoryImpl();
        final double freshBalance = await walletRepository.getZarpBalance(
          walletProvider.userTokenAccount!.pubkey,
        );
        walletBalance = freshBalance;
      } catch (e) {
        // Continue with cached balance
      }
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.90,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: PaymentReviewContent(
            amount: amount,
            recipientAddress: widget.recipientAddress,
            walletBalance: walletBalance,
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Ensure PaymentProvider has the recipient address set when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final PaymentProvider paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      if (paymentProvider.recipientAddress != widget.recipientAddress) {
        paymentProvider.setRecipientAddress(widget.recipientAddress);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final WalletProvider walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final String currentWalletAddress = walletProvider.userTokenAccount?.pubkey ?? walletProvider.wallet?.address ?? '';

    return ChangeNotifierProvider<PaymentAmountViewModel>(
      create: (_) => PaymentAmountViewModel(
        recipientAddress: widget.recipientAddress,
        initialAmount: widget.initialAmount,
        currentWalletAddress: currentWalletAddress,
        context: context,
      ),
      child: Consumer<PaymentAmountViewModel>(
        builder: (BuildContext context, PaymentAmountViewModel viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              leading: Padding(
                padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
                child: InkWell(
                  onTap: () => context.go(widget.source),
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
                  AmountInput(
                    controller: viewModel.paymentAmountController,
                    readOnly: false,
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const Text('Minimum amount is R5'),
                      const SizedBox(height: 24),
                      Container(
                        constraints: const BoxConstraints(minWidth: 250, maxWidth: 350),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEBECEF),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Text(
                          widget.recipientAddress,
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
                      PreviouslyPaidInfo(
                        viewModel: viewModel,
                        recipientAddress: widget.recipientAddress,
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: viewModel.isFormValid
                        ? () async {
                            await _showPaymentReviewModal(
                              viewModel.paymentAmountController.text,
                            );
                          }
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
