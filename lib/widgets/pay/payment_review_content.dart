import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:solana/solana.dart';

import '../../provider/wallet_provider.dart';
import '../../services/wallet_solana_service.dart';
import '../../services/wallet_storage_service.dart';
import 'payment_success.dart';

class PaymentReviewContent extends StatefulWidget {
  const PaymentReviewContent({
    required this.amount,
    required this.onCancel,
    super.key,
  });
  final String amount;
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

  Future<void> _makeTransaction() async {
    final String recipientAddress =
        dotenv.env['solana_wallet_devnet_public_key'] ?? '';

    // make airdrop here if you need to fund your devnet wallet. Only do this once.
    // await walletSolanaService.requestAirdrop(_wallet!.address, 100000000);

    final Wallet? wallet =
        Provider.of<WalletProvider>(context, listen: false).wallet;

    if (wallet != null && recipientAddress != '') {
      await walletSolanaService.sendTransaction(
        senderWallet: wallet,
        recipientAddress: recipientAddress,
        lamports: 500000,
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
                  'R${widget.amount}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7F8),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Text(
                    'D1f4HnfUPGPqbatYFq8yTd6VzhMuqesT...',
                    style: TextStyle(color: Colors.grey),
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
          )
        : PaymentSuccess(amount: widget.amount);
  }
}
