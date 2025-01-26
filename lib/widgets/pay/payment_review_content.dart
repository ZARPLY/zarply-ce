import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:solana/solana.dart';

import '../../provider/wallet_provider.dart';
import '../../services/wallet_solana_service.dart';
import '../../services/wallet_storage_service.dart';
import '../../utils/formatters.dart';
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
  final WalletSolanaService walletSolanaService = WalletSolanaService(
    rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
    websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
  );
  final WalletStorageService walletStorageService = WalletStorageService();
  bool hasPaymentBeenMade = false;
  bool isLoading = false;

  Future<void> _makeTransaction() async {
    setState(() {
      isLoading = true;
    });

    try {
      final Wallet? wallet =
          Provider.of<WalletProvider>(context, listen: false).wallet;

      if (wallet == null) {
        throw Exception('Wallet not found');
      }

      if (widget.recipientAddress != '') {
        await walletSolanaService.sendTransaction(
          senderWallet: wallet,
          recipientAddress: widget.recipientAddress,
          zarpAmount: double.parse(
                widget.amount,
              ) /
              100,
        );
        setState(() {
          hasPaymentBeenMade = true;
        });
      } else {
        setState(() {
          hasPaymentBeenMade = false;
        });
        throw Exception('Wallet or recipient address not found');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return !hasPaymentBeenMade
        ? Padding(
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
                    double.parse(
                          widget.amount,
                        ) /
                        100,
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
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _makeTransaction,
                    style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Confirm Payment'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          )
        : PaymentSuccess(amount: widget.amount);
  }
}
