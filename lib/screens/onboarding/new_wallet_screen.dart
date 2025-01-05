import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:solana/solana.dart';

import '../../provider/wallet_provider.dart';
import '../../services/wallet_solana_service.dart';
import '../../services/wallet_storage_service.dart';

class NewWalletScreen extends StatefulWidget {
  const NewWalletScreen({super.key});

  @override
  State<NewWalletScreen> createState() => _NewWalletScreenState();
}

class _NewWalletScreenState extends State<NewWalletScreen> {
  final WalletSolanaService _walletService = WalletSolanaService(
    rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
    websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
  );
  final WalletStorageService _storageService = WalletStorageService();
  String? _walletAddress;

  @override
  void initState() {
    super.initState();
    _createAndStoreWallet();
  }

  Future<void> _createAndStoreWallet() async {
    final WalletProvider walletProvider =
        Provider.of<WalletProvider>(context, listen: false);
    final String? recoveryPhrase = walletProvider.recoveryPhrase;

    if (recoveryPhrase == null) {
      throw Exception('Recovery phrase is null');
    }

    final Wallet wallet =
        await _walletService.createWalletFromMnemonic(recoveryPhrase);
    await _storageService.saveWallet(wallet);

    walletProvider.clearRecoveryPhrase();

    setState(() {
      _walletAddress = wallet.address;
    });
  }

  Future<void> _copyToClipboard() async {
    if (_walletAddress != null) {
      await Clipboard.setData(ClipboardData(text: _walletAddress!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address copied to clipboard')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
          child: InkWell(
            onTap: () => context.go('/getting_started'),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Your New Wallet',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Here is your new wallet address. Keep it safe!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            if (_walletAddress != null)
              Center(
                child: GestureDetector(
                  onTap: _copyToClipboard,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD3D9DF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            _walletAddress!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy, size: 20),
                      ],
                    ),
                  ),
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _walletAddress != null ? () => context.go('/wallet') : null,
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Go to Wallet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
