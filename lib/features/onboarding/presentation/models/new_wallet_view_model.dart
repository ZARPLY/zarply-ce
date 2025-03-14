import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../wallet/data/services/wallet_storage_service.dart';

class NewWalletViewModel extends ChangeNotifier {
  NewWalletViewModel() {
    getWalletAddresses();
  }
  final WalletStorageService _storageService = WalletStorageService();
  String? walletAddress;
  String? tokenAccountAddress;
  bool isLoading = true;

  Future<void> getWalletAddresses() async {
    isLoading = true;
    notifyListeners();

    walletAddress = await _storageService.retrieveWalletPublicKey();
    tokenAccountAddress =
        await _storageService.retrieveAssociatedTokenAccountPublicKey();

    isLoading = false;
    notifyListeners();
  }

  Future<void> copyToClipboard(String text, BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address copied to clipboard')),
      );
    }
  }
}
