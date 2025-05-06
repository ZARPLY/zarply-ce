import 'package:flutter/material.dart';
import 'package:solana/solana.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/initializer/app_initializer.dart';
import '../models/payment_review_content_view_model.dart';
import 'payment_success.dart';

class PaymentReviewContent extends StatefulWidget {
  const PaymentReviewContent({
    required this.amount,
    required this.recipientAddress,
    required this.onCancel,
    required this.walletBalance,
    super.key,
  });
  final String amount;
  final String recipientAddress;
  final VoidCallback onCancel;
  final double walletBalance;

  @override
  State<PaymentReviewContent> createState() => _PaymentReviewContentState();
}

class _PaymentReviewContentState extends State<PaymentReviewContent> {
  late final PaymentReviewContentViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PaymentReviewContentViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _makeTransaction() async {
    final Wallet wallet = AppInitializer.of(context).wallet;
    await _viewModel.makeTransaction(
      wallet: wallet, 
      recipientAddress: widget.recipientAddress, 
      amount: widget.amount,
      );
  }

  @override
  Widget build(BuildContext context) {
    final double tokenAmount = (double.tryParse(widget.amount) ?? 0) / 100;
    final bool insufficientTokens = tokenAmount > widget.walletBalance;

    final double solBalance = AppInitializer.of(context).solBalance;
    const double minSolForFree = 0.001;
    final bool insufficientSol = solBalance < minSolForFree;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (BuildContext context, _) {
        if (_viewModel.hasPaymentBeenMade) {
          return PaymentSuccess(amount: widget.amount);
        }
        return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Payment Review',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: widget.onCancel,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF9BA1AC),
                      ),
                      child: const Icon(
                        Icons.call_made,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      Formatters.formatAmount(tokenAmount),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F7F8),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Text(
                        Formatters.shortenAddress(widget.recipientAddress),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Review the details before making a payment. Once complete, this payment cannot be reversed. Confirm to proceed.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    if (insufficientTokens) ...[
                      Text(
                        'Insufficient funds (Balance: ${Formatters.formatAmount(widget.walletBalance)})',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    if (insufficientSol)...[
                      Text(
                        'Insufficient SOL for fees. You need at least '
                        '${minSolForFree.toStringAsFixed(3)} SOL but have '
                        '${solBalance.toStringAsPrecision(3)} SOL.',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            (_viewModel.isLoading || 
                            insufficientTokens || 
                            insufficientSol)
                            ? null : _makeTransaction,
                        style: ElevatedButton.styleFrom(
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: _viewModel.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Confirm Payment'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
      },
    );
  }
}
