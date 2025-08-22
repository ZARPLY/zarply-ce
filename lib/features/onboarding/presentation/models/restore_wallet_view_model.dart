import 'package:flutter/material.dart';
import 'package:solana/solana.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../../data/repositories/restore_wallet_repository_impl.dart';
import '../../domain/repositories/restore_wallet_repository.dart';

class RestoreWalletViewModel extends ChangeNotifier {
  RestoreWalletViewModel({RestoreWalletRepository? repository})
      : _repository = repository ?? RestoreWalletRepositoryImpl() {
    phraseController.addListener(() {
      print('RestoreWalletViewModel: Phrase controller listener triggered');
      updateFormValidity();
    });
    privateKeyController.addListener(() {
      print('RestoreWalletViewModel: Private key controller listener triggered');
      updateFormValidity();
    });
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
    updateFormValidity();
    notifyListeners();
  }

  void updateFormValidity() {
    if (selectedRestoreMethod == 'Seed Phrase') {
      final String phrase = phraseController.text.trim();
      final List<String> words = phrase.split(' ').where((String word) => word.isNotEmpty).toList();
      final bool isValidMnemonic = _repository.isValidMnemonic(phrase);
      final bool hasValidWordCount = words.length == 12 || words.length == 24;
      isFormValid = phrase.isNotEmpty && isValidMnemonic && hasValidWordCount;
      
      // Debug logging
      print('RestoreWalletViewModel: Phrase length: ${phrase.length}');
      print('RestoreWalletViewModel: Phrase: "$phrase"');
      print('RestoreWalletViewModel: Word count: ${words.length}');
      print('RestoreWalletViewModel: Words: $words');
      print('RestoreWalletViewModel: isValidMnemonic: $isValidMnemonic');
      print('RestoreWalletViewModel: hasValidWordCount: $hasValidWordCount');
      print('RestoreWalletViewModel: isFormValid: $isFormValid');
      
      // Additional debugging for common issues
      if (phrase.isNotEmpty && !isValidMnemonic) {
        print('RestoreWalletViewModel: Validation failed. Possible issues:');
        print('RestoreWalletViewModel: - Extra spaces or formatting');
        print('RestoreWalletViewModel: - Invalid words');
        print('RestoreWalletViewModel: - Mixed case issues');
      }
    } else {
      final String privateKey = privateKeyController.text.trim();
      final bool isValidPrivateKey = _repository.isValidPrivateKey(privateKey);
      isFormValid = privateKey.isNotEmpty && isValidPrivateKey;
      
      // Debug logging
      print('RestoreWalletViewModel: Private key length: ${privateKey.length}');
      print('RestoreWalletViewModel: isValidPrivateKey: $isValidPrivateKey');
      print('RestoreWalletViewModel: isFormValid: $isFormValid');
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

      // await Future<void>.delayed(const Duration(seconds: 2));

      return true;
    } catch (e) {
      errorMessage = e.toString();
      isImporting = false;
      notifyListeners();
      return false;
    }
  }
}
