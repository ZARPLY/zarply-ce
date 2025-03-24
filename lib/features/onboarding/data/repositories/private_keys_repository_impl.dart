import 'package:flutter/services.dart';

import '../../../../features/wallet/data/services/wallet_storage_service.dart';
import '../../domain/repositories/private_keys_repository.dart';

class PrivateKeysRepositoryImpl implements PrivateKeysRepository {
  final WalletStorageService _storageService = WalletStorageService();

  @override
  Future<String?> getWalletPrivateKey() async {
    return await _storageService.retrieveWalletPrivateKey();
  }

  @override
  Future<String?> getTokenAccountPublicKey() async {
    return await _storageService.retrieveAssociatedTokenAccountPublicKey();
  }

  @override
  Future<void> copyKeysToClipboard(String walletKey, String tokenKey) async {
    final String keys = 'Wallet: $walletKey\nToken: $tokenKey';
    await Clipboard.setData(ClipboardData(text: keys));
  }
}
