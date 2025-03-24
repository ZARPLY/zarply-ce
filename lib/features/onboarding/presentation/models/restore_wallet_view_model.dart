import 'package:flutter/material.dart';
import 'package:solana/solana.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../../data/repositories/restore_wallet_repository_impl.dart';
import '../../domain/repositories/restore_wallet_repository.dart';

class RestoreWalletViewModel extends ChangeNotifier {
  RestoreWalletViewModel({RestoreWalletRepository? repository})
      : _repository = repository ?? RestoreWalletRepositoryImpl() {
    phraseController.addListener(_updateFormValidity);
    privateKeyController.addListener(_updateFormValidity);
  }
  final TextEditingController phraseController = TextEditingController();
  final TextEditingController privateKeyController = TextEditingController();
  final RestoreWalletRepository _repository;

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
          _repository.isValidMnemonic(phraseController.text.trim());
    } else {
      isFormValid = privateKeyController.text.trim().isNotEmpty &&
          _repository.isValidPrivateKey(privateKeyController.text.trim());
    }
    notifyListeners();
  }

  Future<Wallet?> _restoreWallet(WalletProvider walletProvider) async {
    try {
      Wallet wallet;
      if (selectedRestoreMethod == 'Seed Phrase') {
        wallet = await _repository.restoreWalletFromMnemonic(
          phraseController.text.trim(),
        );
      } else {
        wallet = await _repository.restoreWalletFromPrivateKey(
          privateKeyController.text.trim(),
        );
      }

      await _repository.storeWallet(wallet, walletProvider);

      return wallet;
    } catch (e) {
      errorMessage = 'Failed to restore wallet: ${e.toString()}';
      notifyListeners();
      return null;
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

      await _repository.restoreAssociatedTokenAccount(wallet, walletProvider);

      importComplete = true;
      notifyListeners();

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
