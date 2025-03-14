import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../../../wallet/data/services/wallet_solana_service.dart';
import '../../../wallet/data/services/wallet_storage_service.dart';

class WelcomeViewModel extends ChangeNotifier {
  final WalletSolanaService _walletService = WalletSolanaService(
    rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
    websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
  );
  final WalletStorageService _storageService = WalletStorageService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> createAndStoreWallet(WalletProvider walletProvider) async {
    _isLoading = true;
    notifyListeners();

    try {
      final String recoveryPhrase = bip39.generateMnemonic();

      walletProvider.setRecoveryPhrase(recoveryPhrase);

      final Wallet wallet =
          await _walletService.createWalletFromMnemonic(recoveryPhrase);
      await Future<void>.delayed(const Duration(seconds: 2));
      final ProgramAccount tokenAccount =
          await _walletService.createAssociatedTokenAccount(wallet);

      await _storageService.saveWalletPrivateKey(wallet);
      await _storageService.saveWalletPublicKey(wallet);
      await _storageService.saveAssociatedTokenAccountPublicKey(tokenAccount);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
