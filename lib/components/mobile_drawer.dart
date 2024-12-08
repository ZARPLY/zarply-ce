import 'package:flutter/material.dart';
import 'package:solana/solana.dart';
import 'package:zarply/services/wallet_solana_service.dart';
import 'package:zarply/services/wallet_storage_service.dart';

class MobileDrawer extends StatelessWidget {
  final Widget? main;
  final List<Widget>? actions;
  final Widget? title;
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
    // await walletSolanaService.requestAirdrop(_wallet!.address, 100000000);
    Wallet? wallet = await walletStorageService.retrieveWallet();
    await walletSolanaService.sendTransaction(
        senderWallet: wallet!,
        recipientAddress: "5cwnBsrohuK84gbTig8sZgN4ALF4M3MBaRZasB5r3Moy",
        lamports: 500000);
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
