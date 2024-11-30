import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solana/solana.dart';

class WalletStorageException implements Exception {
  final String message;
  WalletStorageException(this.message);

  @override
  String toString() => 'WalletStorageException: $message';
}

class WalletStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _walletKey = 'wallet_key';

  Future<void> saveWallet(Wallet wallet) async {
    try {
      if (wallet.address.isEmpty) {
        throw WalletStorageException('Wallet address cannot be empty.');
      }
      final Ed25519HDKeyPairData keyPairData = await wallet.extract();
      final String privateKeyBase64 = base64Encode(keyPairData.bytes);
      await _secureStorage.write(key: _walletKey, value: privateKeyBase64);
    } catch (e) {
      throw WalletStorageException('Failed to save wallet key: $e');
    }
  }

  Future<Wallet> retrieveWallet() async {
    try {
      final walletKey = await _secureStorage.read(key: _walletKey);
      if (walletKey == null) {
        throw WalletStorageException('Could not get wallet key');
      }

      final restoredWallet =
          await Wallet.fromPrivateKeyBytes(privateKey: base64Decode(walletKey));
      return restoredWallet;
    } catch (e) {
      throw WalletStorageException('Failed to retrieve wallet key: $e');
    }
  }

  Future<void> deletePrivateKey() async {
    try {
      final exists = await _secureStorage.containsKey(key: _walletKey);
      // TODO: destroy wallet
      if (!exists) {
        throw WalletStorageException('No wallet key to delete.');
      }
      await _secureStorage.delete(key: _walletKey);
    } catch (e) {
      throw WalletStorageException('Failed to delete wallet key: $e');
    }
  }
}
