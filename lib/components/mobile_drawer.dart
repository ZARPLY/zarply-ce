import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/solana.dart';
import 'package:zarply/services/wallet_solana_service.dart';
import 'package:zarply/services/wallet_storage_service.dart';

class MobileDrawer extends StatelessWidget {
  final Widget? main;
  final List<Widget>? actions;
  final Widget? title;
  // TODO: move such data into env files
  final walletSolanaService = WalletSolanaService(
      rpcUrl: 'https://api.devnet.solana.com',
      websocketUrl: 'wss://api.devnet.solana.com');
  final walletStorageService = WalletStorageService();

  MobileDrawer(
      {required this.main,
      required this.actions,
      required this.title,
      super.key});

  void _makeTransaction() async {
    String recipientAddress =
        dotenv.env['solana_wallet_devnet_public_key'] ?? '';

    // make airdrop here if you need to fund your devnet wallet.
    // await walletSolanaService.requestAirdrop(_wallet!.address, 100000000);

    Wallet? wallet = await walletStorageService.retrieveWallet();

    if (wallet != null && recipientAddress != '') {
      await walletSolanaService.sendTransaction(
          senderWallet: wallet,
          recipientAddress: recipientAddress,
          lamports: 500000);
    } else {
      throw Exception('Wallet or recipient address not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: main,
      backgroundColor: Colors.blue[700],
      appBar: AppBar(
        title: title,
        actions: actions,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _makeTransaction();
        },
        shape: const CircleBorder(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.sync_alt, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
