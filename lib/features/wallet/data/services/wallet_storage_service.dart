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

  Future<void> saveWalletPrivateKey(Wallet wallet) async {
    print('DEBUG: WalletStorageService.saveWalletPrivateKey() called for address: ${wallet.address}');
    try {
      if (wallet.address.isEmpty) {
        throw WalletStorageException('Wallet address cannot be empty.');
      }
      final Ed25519HDKeyPairData keyPairData = await wallet.extract();
      final String privateKeyBase64 = base64Encode(keyPairData.bytes);
      print('DEBUG: Saving wallet private key to secure storage');
      await _secureStorage.write(
        key: _walletPrivateKey,
        value: privateKeyBase64,
      );
      print('DEBUG: Wallet private key saved successfully');
    } catch (e) {
      print('DEBUG: Error saving wallet private key: $e');
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
    print('DEBUG: WalletStorageService.retrieveWallet() called');
    try {
      final String? walletKey =
          await _secureStorage.read(key: _walletPrivateKey);
      print('DEBUG: Retrieved wallet key from storage: ${walletKey != null ? 'exists' : 'null'}');
      
      if (walletKey == null) {
        print('DEBUG: No wallet key found in storage');
        return null;
      }

      final Ed25519HDKeyPair restoredWallet =
          await Wallet.fromPrivateKeyBytes(privateKey: base64Decode(walletKey));
      print('DEBUG: Successfully restored wallet with address: ${restoredWallet.address}');
      return restoredWallet;
    } catch (e) {
      print('DEBUG: Error retrieving wallet: $e');
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
    final String? tokenAccount =
        await _secureStorage.read(key: _associatedTokenAccountKey);
    return tokenAccount;
  }

  Future<void> deletePrivateKey() async {
    try {
      final bool exists =
          await _secureStorage.containsKey(key: _walletPrivateKey);
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
}
