import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/solana.dart';
import '../services/wallet_solana_service.dart';
import '../services/wallet_storage_service.dart';

class MobileDrawer extends StatelessWidget {
  MobileDrawer({
    required this.main,
    required this.actions,
    required this.title,
    super.key,
  });
  final Widget? main;
  final List<Widget>? actions;
  final Widget? title;
  final WalletSolanaService walletSolanaService = WalletSolanaService(
    rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
    websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
  );
  final WalletStorageService walletStorageService = WalletStorageService();

  Future<void> _makeTransaction() async {
    final String recipientAddress =
        dotenv.env['solana_wallet_devnet_public_key'] ?? '';

    final Wallet? wallet = await walletStorageService.retrieveWallet();

    if (wallet != null && recipientAddress != '') {
      // make airdrop here if you need to fund your devnet wallet.
      // await walletSolanaService.requestAirdrop(wallet.address, 100000000);
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
      body: main,
      backgroundColor: Colors.blue[700],
      appBar: AppBar(
        title: title,
        actions: actions,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _makeTransaction,
        shape: const CircleBorder(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.sync_alt, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
