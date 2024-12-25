import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:solana/solana.dart';
import '../../services/wallet_solana_service.dart';
import '../../services/wallet_storage_service.dart';

class PayRequest extends StatelessWidget {
  PayRequest({super.key});
  final WalletSolanaService walletSolanaService = WalletSolanaService(
    rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
    websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
  );
  final WalletStorageService walletStorageService = WalletStorageService();

  Future<void> _makeTransaction() async {
    final String recipientAddress =
        dotenv.env['solana_wallet_devnet_public_key'] ?? '';

    // make airdrop here if you need to fund your devnet wallet. Only do this once.
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
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
          child: InkWell(
            onTap: () => context.pop(),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  Text(
                    'Pay Request',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Initiate payments or requests',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            InkWell(
              onTap: () => context.go('/payment-details'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F9),
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
                            color: const Color(0xFF9BA1AC),
                            borderRadius: BorderRadius.circular(80),
                          ),
                          child: const Icon(
                            Icons.call_made,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Pay'),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                // Handle request button tap
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F9),
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
                            color: const Color(0xFF9BA1AC),
                            borderRadius: BorderRadius.circular(80),
                          ),
                          child: const Icon(
                            Icons.call_received,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Request'),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
