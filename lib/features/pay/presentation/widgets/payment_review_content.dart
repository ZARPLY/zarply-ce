import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:solana/solana.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loading_button.dart';
import '../models/payment_review_content_view_model.dart';
import 'payment_success.dart';

class PaymentReviewContent extends StatefulWidget {
  const PaymentReviewContent({
    required this.amount,
    required this.recipientAddress,
    required this.onCancel,
    super.key,
  });
  final String amount;
  final String recipientAddress;
  final VoidCallback onCancel;

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
    final Wallet? wallet =
        Provider.of<WalletProvider>(context, listen: false).wallet;

    if (wallet == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Wallet not found. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await _viewModel.makeTransaction(
        wallet: wallet,
        recipientAddress: widget.recipientAddress,
        amount: widget.amount,
        context: context,
      );

      if (mounted) {
        Navigator.pop(context); // Close the modal
        context.go('/wallet'); // Navigate to wallet screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Formatters.formatAmount(
                  double.parse(widget.amount) / 100,
                ),
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
              SizedBox(
                width: double.infinity,
                child: LoadingButton(
                  isLoading: _viewModel.isLoading,
                  onPressed: _makeTransaction,
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Confirm Payment'),
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
