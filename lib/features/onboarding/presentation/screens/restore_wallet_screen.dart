import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../../../wallet/data/services/wallet_solana_service.dart';
import '../../../wallet/data/services/wallet_storage_service.dart';
import '../widgets/importing_wallet_modal.dart';

class RestoreWalletScreen extends StatefulWidget {
  const RestoreWalletScreen({super.key});

  @override
  State<RestoreWalletScreen> createState() => _RestoreWalletScreenState();
}

class _RestoreWalletScreenState extends State<RestoreWalletScreen> {
  final TextEditingController _phraseController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();
  final WalletStorageService _storageService = WalletStorageService();
  final WalletSolanaService _walletService = WalletSolanaService(
    rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
    websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
  );
  bool _isFormValid = false;
  String _selectedRestoreMethod = 'Seed Phrase';

  @override
  void initState() {
    super.initState();
    _phraseController.addListener(_updateFormValidity);
    _privateKeyController.addListener(_updateFormValidity);
  }

  @override
  void dispose() {
    _phraseController.dispose();
    _privateKeyController.dispose();
    super.dispose();
  }

  void _updateFormValidity() {
    setState(() {
      if (_selectedRestoreMethod == 'Seed Phrase') {
        _isFormValid = _phraseController.text.trim().isNotEmpty &&
            _walletService.isValidMnemonic(_phraseController.text.trim());
      } else {
        _isFormValid = _privateKeyController.text.trim().isNotEmpty &&
            _walletService.isValidPrivateKey(_privateKeyController.text.trim());
      }
    });
  }

  Future<Wallet?> _restoreWallet(WalletProvider walletProvider) async {
    try {
      Wallet wallet;
      if (_selectedRestoreMethod == 'Seed Phrase') {
        wallet = await _walletService.restoreWalletFromMnemonic(
          _phraseController.text.trim(),
        );
      } else {
        wallet = await _walletService.restoreWalletFromPrivateKey(
          _privateKeyController.text.trim(),
        );
      }

      await walletProvider.storeWallet(wallet);
      await _storageService.saveWalletPrivateKey(wallet);
      await _storageService.saveWalletPublicKey(wallet);

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

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.90,
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return FutureBuilder<void>(
              future: () async {
                final Wallet? wallet = await _restoreWallet(walletProvider);
                final bool hasPassword = await walletProvider.hasPassword();

                if (wallet == null) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  return;
                }
                await _restoreAssociatedTokenAccount(wallet, walletProvider);
                if (!context.mounted) return;
                setState(() {}); // Trigger rebuild with success state
                await Future<void>.delayed(const Duration(seconds: 2));
                if (!context.mounted) return;
                if (!hasPassword) {
                  context.replace('/create_password');
                } else {
                  context.replace('/login');
                }
              }(),
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                final bool isImported =
                    snapshot.connectionState == ConnectionState.done;
                return ImportingWalletModal(isImported: isImported);
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
          child: InkWell(
            onTap: () => context.go('/welcome'),
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
        title: Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(40), // More rounded corners
            ),
            child: DropdownButton<String>(
              value: _selectedRestoreMethod,
              isExpanded: true,
              isDense: true,
              iconSize: 20,
              alignment: AlignmentDirectional.centerEnd,
              underline: Container(),
              items: const <DropdownMenuItem<String>>[
                DropdownMenuItem<String>(
                  value: 'Seed Phrase',
                  child: Text('Seed Phrase'),
                ),
                DropdownMenuItem<String>(
                  value: 'Private Key',
                  child: Text('Private Key'),
                ),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedRestoreMethod = newValue;
                  });
                }
              },
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
              'Restore Wallet',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedRestoreMethod == 'Seed Phrase'
                  ? 'Your Secret Recovery Phrase is essential for accessing your wallet if you lose your device or need to switch to a different wallet application.'
                  : 'Enter your private key to restore your wallet. Make sure to keep your private key secure and never share it with anyone.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            if (_selectedRestoreMethod == 'Seed Phrase')
              TextField(
                controller: _phraseController,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: 'Recovery Phrase',
                  hintText: 'Enter your 12 or 24 word recovery phrase',
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.red,
                    ),
                  ),
                  errorText: _phraseController.text.isNotEmpty
                      ? _isFormValid
                          ? null
                          : 'Please enter exactly 12 or 24 words'
                      : null,
                ),
              )
            else
              TextField(
                controller: _privateKeyController,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: 'Private Key',
                  hintText: 'Enter your private key',
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.red,
                    ),
                  ),
                  errorText:
                      _privateKeyController.text.isNotEmpty && !_isFormValid
                          ? 'Please enter a valid private key'
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
                child: const Text('Import Wallet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
