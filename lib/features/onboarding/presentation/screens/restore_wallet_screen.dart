import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../models/restore_wallet_view_model.dart';
import '../widgets/importing_wallet_modal.dart';
import '../widgets/restore_wallet_dropdown.dart';

class RestoreWalletScreen extends StatefulWidget {
  const RestoreWalletScreen({super.key});

  @override
  State<RestoreWalletScreen> createState() => _RestoreWalletScreenState();
}

class _RestoreWalletScreenState extends State<RestoreWalletScreen> {
  late final RestoreWalletViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = RestoreWalletViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
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
                final bool success =
                    await _viewModel.restoreWallet(walletProvider);
                if (!success) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  return;
                }

                final bool hasPassword = await walletProvider.hasPassword();
                if (!context.mounted) return;

                if (!hasPassword) {
                  context.replace('/create_password');
                } else {
                  context.replace('/login');
                }
              }(),
              builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                return ImportingWalletModal(
                  isImported: _viewModel.importComplete,
                );
              },
            );
          },
        ),
      ),
    );

    if (_viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          child: RestoreMethodDropdown(
            selectedMethod: _viewModel.selectedRestoreMethod,
            onChanged: (String? newValue) {
              if (newValue != null) {
                _viewModel.setRestoreMethod(newValue);
                setState(() {}); 
              }
            },
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (BuildContext context, _) {
          return Padding(
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
                  _viewModel.selectedRestoreMethod == 'Seed Phrase'
                      ? 'Your Secret Recovery Phrase is essential for accessing your wallet if you lose your device or need to switch to a different wallet application.'
                      : 'Enter your private key to restore your wallet. Make sure to keep your private key secure and never share it with anyone.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                if (_viewModel.selectedRestoreMethod == 'Seed Phrase')
                  TextField(
                    controller: _viewModel.phraseController,
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
                      errorText: _viewModel.phraseController.text.isNotEmpty
                          ? _viewModel.isFormValid
                              ? null
                              : 'Please enter exactly 12 or 24 words'
                          : null,
                    ),
                  )
                else
                  TextField(
                    controller: _viewModel.privateKeyController,
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
                          _viewModel.privateKeyController.text.isNotEmpty &&
                                  !_viewModel.isFormValid
                              ? 'Please enter a valid private key'
                              : null,
                    ),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _viewModel.isFormValid ? _handleRestoreWallet : null,
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
          );
        },
      ),
    );
  }
}
