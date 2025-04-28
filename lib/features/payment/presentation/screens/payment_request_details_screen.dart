import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/utils/formatters.dart';

class PaymentRequestDetailsScreen extends StatefulWidget {
  const PaymentRequestDetailsScreen({
    required this.amount,
    required this.recipientAddress,
    super.key,
  });

  final String amount;
  final String recipientAddress;

  @override
  State<PaymentRequestDetailsScreen> createState() =>
      _PaymentRequestDetailsScreenState();
}

class _PaymentRequestDetailsScreenState
    extends State<PaymentRequestDetailsScreen> {
  bool _isProcessing = false;

  Future<void> _handlePaymentConfirmation() async {
    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Show success bottom sheet
      await _showSuccessBottomSheet();

      // Navigate back to wallet screen
      if (mounted) {
        context.go('/wallet');
      }
    }
  }

  Future<void> _showSuccessBottomSheet() {
    return showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Successful',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your payment has been processed successfully',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double amountInRands = double.parse(widget.amount) / 100;
    final walletProvider = Provider.of<WalletProvider>(context);
    final wallet = walletProvider.wallet;
    final tokenAccount = walletProvider.userTokenAccount;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/wallet'),
        ),
        title: const Text('Payment Review'),
        actions: [
          TextButton(
            onPressed: () => context.go('/wallet'),
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.blue,
              child: Column(
                children: [
                  const Text(
                    "You're about to pay",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatters.formatAmount(amountInRands),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem('To account', widget.recipientAddress),
                  const SizedBox(height: 24),
                  _buildDetailItem(
                      'Account Number', tokenAccount?.pubkey ?? ''),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isProcessing ? null : _handlePaymentConfirmation,
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Confirm Payment'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
