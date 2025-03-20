import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../features/wallet/data/services/wallet_storage_service.dart';
import '../../domain/repositories/new_wallet_repository.dart';

class NewWalletRepositoryImpl implements NewWalletRepository {
  final WalletStorageService _storageService = WalletStorageService();

  @override
  Future<String?> getWalletPublicKey() async {
    return await _storageService.retrieveWalletPublicKey();
  }

  @override
  Future<String?> getAssociatedTokenAccountPublicKey() async {
    return await _storageService.retrieveAssociatedTokenAccountPublicKey();
  }

  @override
  Future<void> copyToClipboard(String text, BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address copied to clipboard')),
      );
    }
  }
}
