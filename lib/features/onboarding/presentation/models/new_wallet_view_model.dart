import 'package:flutter/material.dart';

import '../../data/repositories/new_wallet_repository_impl.dart';
import '../../domain/repositories/new_wallet_repository.dart';

class NewWalletViewModel extends ChangeNotifier {
  NewWalletViewModel() {
    getWalletAddresses();
  }

  final NewWalletRepository _repository = NewWalletRepositoryImpl();
  String? walletAddress;
  String? tokenAccountAddress;
  bool isLoading = true;

  Future<void> getWalletAddresses() async {
    isLoading = true;
    notifyListeners();

    walletAddress = await _repository.getWalletPublicKey();
    tokenAccountAddress =
        await _repository.getAssociatedTokenAccountPublicKey();

    isLoading = false;
    notifyListeners();
  }

  Future<void> copyToClipboard(String text, BuildContext context) async {
    await _repository.copyToClipboard(text, context);
  }
}
