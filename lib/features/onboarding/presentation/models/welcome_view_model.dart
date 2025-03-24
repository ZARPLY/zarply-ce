import 'package:flutter/material.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../../data/repositories/welcome_repository_impl.dart';
import '../../domain/repositories/welcome_repository.dart';

class WelcomeViewModel extends ChangeNotifier {
  WelcomeViewModel({WelcomeRepository? repository})
      : _repository = repository ?? WelcomeRepositoryImpl();

  final WelcomeRepository _repository;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> createAndStoreWallet(WalletProvider walletProvider) async {
    _isLoading = true;
    notifyListeners();

    try {
      final ({
        String recoveryPhrase,
        ProgramAccount tokenAccount,
        Wallet wallet
      }) result = await _repository.createWallet();
      walletProvider.setRecoveryPhrase(result.recoveryPhrase);
      await _repository.storeWalletKeys(
        wallet: result.wallet,
        tokenAccount: result.tokenAccount,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
