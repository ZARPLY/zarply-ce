import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../../data/repositories/welcome_repository_impl.dart';
import '../../domain/repositories/welcome_repository.dart';

class WelcomeViewModel extends ChangeNotifier {
  WelcomeViewModel({WelcomeRepository? repository}) : _repository = repository ?? WelcomeRepositoryImpl();

  final WelcomeRepository _repository;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> createAndStoreWallet(WalletProvider walletProvider) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final ({String? recoveryPhrase, ProgramAccount? tokenAccount, Wallet? wallet, String? errorMessage}) result =
          await _repository.createWallet();

      if (result.errorMessage != null) {
        _errorMessage = result.errorMessage;
        debugPrint('[WelcomeVM] createWallet returned error: $_errorMessage');
        return false;
      }

      walletProvider.setRecoveryPhrase(result.recoveryPhrase!);
      await _repository.storeWalletKeys(
        wallet: result.wallet!,
        tokenAccount: result.tokenAccount,
      );
      return true;
    } catch (e, stackTrace) {
      _errorMessage = 'Unexpected error. Please try again later. $e';
      debugPrint('[WelcomeVM] createAndStoreWallet threw: $e');
      debugPrint('[WelcomeVM] StackTrace: $stackTrace');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
