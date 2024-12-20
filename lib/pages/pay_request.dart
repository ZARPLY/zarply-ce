import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/solana.dart';
import '../services/wallet_solana_service.dart';
import '../services/wallet_storage_service.dart';

class PayRequest extends StatelessWidget {
  PayRequest({super.key});
  final WalletSolanaService walletSolanaService = WalletSolanaService(
    rpcUrl: 'https://api.devnet.solana.com',
    websocketUrl: 'wss://api.devnet.solana.com',
  );
  final WalletStorageService walletStorageService = WalletStorageService();

  Future<void> _makeTransaction() async {
    final String recipientAddress =
        dotenv.env['solana_wallet_devnet_public_key'] ?? '';

    // make airdrop here if you need to fund your devnet wallet.
    // await walletSolanaService.requestAirdrop(_wallet!.address, 100000000);

    final Wallet? wallet = await walletStorageService.retrieveWallet();

    if (wallet != null && recipientAddress != '') {
      await walletSolanaService.sendTransaction(
        senderWallet: wallet,
        recipientAddress: recipientAddress,
        lamports: 500000,
      );
    } else {
      throw Exception('Wallet or recipient address not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.arrow_back),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Column(
              children: <Widget>[
                Text(
                  'Pay Request',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Initiate payments or requests',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          InkWell(
            onTap: _makeTransaction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.send_rounded),
                      SizedBox(width: 8),
                      Text('Pay'),
                    ],
                  ),
                  Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              // Handle request button tap
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[500],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_downward),
                      ),
                      const SizedBox(width: 8),
                      const Text('Request'),
                    ],
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
