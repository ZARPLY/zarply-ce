import 'package:flutter/material.dart';

import '../../data/repositories/private_keys_repository_impl.dart';
import '../../domain/repositories/private_keys_repository.dart';

class PrivateKeysViewModel extends ChangeNotifier {
  PrivateKeysViewModel({PrivateKeysRepository? repository})
      : _repository = repository ?? PrivateKeysRepositoryImpl() {
    loadKeys();
  }

  final PrivateKeysRepository _repository;
  String? walletAddress;
  String? tokenAccountAddress;
  bool isLoading = true;
  String? errorMessage;

  Future<void> loadKeys() async {
    try {
      isLoading = true;
      notifyListeners();

      walletAddress = await _repository.getWalletPrivateKey();
      tokenAccountAddress = await _repository.getTokenAccountPublicKey();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Error loading keys';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void copyKeysToClipboard(BuildContext context) {
    _repository.copyKeysToClipboard(
      walletAddress ?? '',
      tokenAccountAddress ?? '',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Private keys copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
