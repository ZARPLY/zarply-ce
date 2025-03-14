import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../../../wallet/data/services/wallet_solana_service.dart';
import '../../../wallet/data/services/wallet_storage_service.dart';

class RestoreWalletViewModel extends ChangeNotifier {
  RestoreWalletViewModel() {
    phraseController.addListener(_updateFormValidity);
    privateKeyController.addListener(_updateFormValidity);
  }
  final TextEditingController phraseController = TextEditingController();
  final TextEditingController privateKeyController = TextEditingController();
  final WalletStorageService storageService = WalletStorageService();
  final WalletSolanaService walletService = WalletSolanaService(
    rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
    websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
  );

  bool isFormValid = false;
  String selectedRestoreMethod = 'Seed Phrase';
  bool isImporting = false;
  bool importComplete = false;
  String? errorMessage;

  @override
  void dispose() {
    phraseController.dispose();
    privateKeyController.dispose();
    super.dispose();
  }

  void setRestoreMethod(String method) {
    selectedRestoreMethod = method;
    _updateFormValidity();
    notifyListeners();
  }

  void _updateFormValidity() {
    if (selectedRestoreMethod == 'Seed Phrase') {
      isFormValid = phraseController.text.trim().isNotEmpty &&
          walletService.isValidMnemonic(phraseController.text.trim());
    } else {
      isFormValid = privateKeyController.text.trim().isNotEmpty &&
          walletService.isValidPrivateKey(privateKeyController.text.trim());
    }
    notifyListeners();
  }

  Future<Wallet?> _restoreWallet(WalletProvider walletProvider) async {
    try {
      Wallet wallet;
      if (selectedRestoreMethod == 'Seed Phrase') {
        wallet = await walletService.restoreWalletFromMnemonic(
          phraseController.text.trim(),
        );
      } else {
        wallet = await walletService.restoreWalletFromPrivateKey(
          privateKeyController.text.trim(),
        );
      }

      await walletProvider.storeWallet(wallet);
      await storageService.saveWalletPrivateKey(wallet);
      await storageService.saveWalletPublicKey(wallet);

      return wallet;
    } catch (e) {
      errorMessage = 'Failed to restore wallet: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  Future<void> _restoreAssociatedTokenAccount(
    Wallet wallet,
    WalletProvider walletProvider,
  ) async {
    try {
      final ProgramAccount? tokenAccount =
          await walletService.getAssociatedTokenAccount(wallet);
      if (tokenAccount == null) return;
      await walletProvider.storeAssociatedTokenAccount(tokenAccount);
    } catch (e) {
      throw WalletStorageException(
        'Failed to restore associated token account: $e',
      );
    }
  }

  Future<bool> restoreWallet(WalletProvider walletProvider) async {
    isImporting = true;
    errorMessage = null;
    notifyListeners();

    try {
      final Wallet? wallet = await _restoreWallet(walletProvider);

      if (wallet == null) {
        isImporting = false;
        notifyListeners();
        return false;
      }

      await _restoreAssociatedTokenAccount(wallet, walletProvider);

      importComplete = true;
      notifyListeners();

      // Delay to show success state
      await Future<void>.delayed(const Duration(seconds: 2));

      return true;
    } catch (e) {
      errorMessage = e.toString();
      isImporting = false;
      notifyListeners();
      return false;
    }
  }
}

class WalletStorageException implements Exception {
  WalletStorageException(this.message);
  final String message;

  @override
  String toString() => message;
}
