import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../features/wallet/data/services/wallet_storage_service.dart';

class PrivateKeysViewModel extends ChangeNotifier {
  PrivateKeysViewModel() {
    loadKeys();
  }
  final WalletStorageService _storageService = WalletStorageService();
  String? walletAddress;
  String? tokenAccountAddress;
  bool isLoading = true;
  String? errorMessage;

  Future<void> loadKeys() async {
    try {
      isLoading = true;
      notifyListeners();

      final String? walletKey =
          await _storageService.retrieveWalletPrivateKey();
      final String? tokenKey =
          await _storageService.retrieveAssociatedTokenAccountPublicKey();

      walletAddress = walletKey;
      tokenAccountAddress = tokenKey;
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Error loading keys';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void copyKeysToClipboard(BuildContext context) {
    final String keys = 'Wallet: $walletAddress\nToken: $tokenAccountAddress';
    Clipboard.setData(ClipboardData(text: keys));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Private keys copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
