import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

class WalletStorageException implements Exception {
  WalletStorageException(this.message);
  final String message;

  @override
  String toString() => 'WalletStorageException: $message';
}

class WalletStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _walletPrivateKey = 'wallet_private_key';
  final String _walletPublicKey = 'wallet_public_key';
  final String _associatedTokenAccountKey = 'associated_token_account_key';
  final String _isFirstTimeUserKey = 'is_first_time_user';

  Future<void> saveWalletPrivateKey(Wallet wallet) async {
    try {
      if (wallet.address.isEmpty) {
        throw WalletStorageException('Wallet address cannot be empty.');
      }
      final Ed25519HDKeyPairData keyPairData = await wallet.extract();
      final String privateKeyBase64 = base64Encode(keyPairData.bytes);
      await _secureStorage.write(
        key: _walletPrivateKey,
        value: privateKeyBase64,
      );
    } catch (e) {
      throw WalletStorageException('Failed to save wallet key: $e');
    }
  }

  Future<void> saveWalletPublicKey(Wallet wallet) async {
    await _secureStorage.write(
      key: _walletPublicKey,
      value: wallet.address,
    );
  }

  Future<void> saveAssociatedTokenAccountPublicKey(
    ProgramAccount? tokenAccount,
  ) async {
    await _secureStorage.write(
      key: _associatedTokenAccountKey,
      value: tokenAccount?.pubkey,
    );
  }

  Future<Wallet?> retrieveWallet() async {
    try {
      final String? walletKey = await _secureStorage.read(key: _walletPrivateKey);
      if (walletKey == null) {
        return null;
      }

      final Ed25519HDKeyPair restoredWallet = await Wallet.fromPrivateKeyBytes(privateKey: base64Decode(walletKey));
      return restoredWallet;
    } catch (e) {
      throw WalletStorageException('Failed to retrieve wallet key: $e');
    }
  }

  Future<String?> retrieveWalletPublicKey() async {
    final String? walletKey = await _secureStorage.read(key: _walletPublicKey);
    return walletKey;
  }

  Future<String?> retrieveWalletPrivateKey() async {
    final String? walletKey = await _secureStorage.read(key: _walletPrivateKey);
    return walletKey;
  }

  Future<String?> retrieveAssociatedTokenAccountPublicKey() async {
    final String? tokenAccount = await _secureStorage.read(key: _associatedTokenAccountKey);
    return tokenAccount;
  }

  Future<void> deletePrivateKey() async {
    try {
      final bool exists = await _secureStorage.containsKey(key: _walletPrivateKey);
      // TODO: destroy wallet
      if (!exists) {
        throw WalletStorageException('No wallet key to delete.');
      }
      await _secureStorage.delete(key: _walletPrivateKey);
    } catch (e) {
      throw WalletStorageException('Failed to delete wallet key: $e');
    }
  }

  Future<bool> hasPassword() async {
    try {
      return await _secureStorage.containsKey(key: 'user_pin');
    } catch (e) {
      throw WalletStorageException('Failed to check password existence: $e');
    }
  }

  Future<void> setFirstTimeUser({required bool isFirstTime}) async {
    try {
      await _secureStorage.write(
        key: _isFirstTimeUserKey,
        value: isFirstTime.toString(),
      );
    } catch (e) {
      throw WalletStorageException('Failed to save first-time user flag: $e');
    }
  }

  Future<bool> isFirstTimeUser() async {
    try {
      final String? value = await _secureStorage.read(key: _isFirstTimeUserKey);
      if (value == null) {
        return false;
      }
      return value.toLowerCase() == 'true';
    } catch (e) {
      throw WalletStorageException('Failed to retrieve first-time user flag: $e');
    }
  }

  Future<void> clearFirstTimeUserFlag() async {
    try {
      await _secureStorage.delete(key: _isFirstTimeUserKey);
    } catch (e) {
      throw WalletStorageException('Failed to clear first-time user flag: $e');
    }
  }
}
