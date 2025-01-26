import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../provider/wallet_provider.dart';
import '../../services/wallet_solana_service.dart';
import '../../services/wallet_storage_service.dart';
import '../../widgets/onboarding/progress_steps.dart';

class RestoreWalletScreen extends StatefulWidget {
  const RestoreWalletScreen({super.key});

  @override
  State<RestoreWalletScreen> createState() => _RestoreWalletScreenState();
}

class _RestoreWalletScreenState extends State<RestoreWalletScreen> {
  final TextEditingController _phraseController = TextEditingController();
  final WalletStorageService _storageService = WalletStorageService();
  final WalletSolanaService _walletService = WalletSolanaService(
    rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
    websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
  );
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _phraseController.addListener(_updateFormValidity);
  }

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  void _updateFormValidity() {
    setState(() {
      _isFormValid = _phraseController.text.trim().isNotEmpty &&
          _walletService.isValidMnemonic(_phraseController.text.trim());
    });
  }

  Future<Wallet?> _restoreWallet(WalletProvider walletProvider) async {
    try {
      final Wallet wallet = await _walletService.restoreWalletFromMnemonic(
        _phraseController.text.trim(),
      );

      await walletProvider.storeWallet(wallet);
      await _storageService.saveWallet(wallet);

      return wallet;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to restore wallet: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _restoreAssociatedTokenAccount(
    Wallet wallet,
    WalletProvider walletProvider,
  ) async {
    try {
      final ProgramAccount? tokenAccount =
          await _walletService.getAssociatedTokenAccount(wallet);
      if (tokenAccount == null) return;
      await walletProvider.storeAssociatedTokenAccount(tokenAccount);
    } catch (e) {
      throw WalletStorageException(
        'Failed to restore associated token account: $e',
      );
    }
  }

  Future<void> _handleRestoreWallet() async {
    final WalletProvider walletProvider =
        Provider.of<WalletProvider>(context, listen: false);
    final Wallet? wallet = await _restoreWallet(walletProvider);
    if (wallet == null) return;
    await _restoreAssociatedTokenAccount(wallet, walletProvider);

    if (mounted) {
      context.go('/wallet');
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
        title: const Padding(
          padding: EdgeInsets.only(right: 24),
          child: ProgressSteps(
            currentStep: 0,
            totalSteps: 3,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Restore Wallet',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your recovery phrase to restore your wallet',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _phraseController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Recovery Phrase',
                hintText: 'Enter your 12 or 24 word recovery phrase',
                errorText: _phraseController.text.isNotEmpty
                    ? _isFormValid
                        ? null
                        : 'Please enter exactly 12 or 24 words'
                    : null,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isFormValid ? _handleRestoreWallet : null,
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Restore Wallet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
