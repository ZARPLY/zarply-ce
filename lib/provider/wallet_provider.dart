import 'package:flutter/material.dart';
import 'package:solana/solana.dart';
import '../services/wallet_storage_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletStorageService _walletStorageService = WalletStorageService();
  Wallet? _wallet;

  Wallet? get wallet => _wallet;

  bool get hasWallet => _wallet != null;

  Future<bool> initializeWallet() async {
    try {
      _wallet = await _walletStorageService.retrieveWallet();
      notifyListeners();
      return true;
    } catch (e) {
      _wallet = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> storeWallet(Wallet wallet) async {
    try {
      await _walletStorageService.saveWallet(wallet);
      _wallet = wallet;
      notifyListeners();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> deleteWallet() async {
    try {
      await _walletStorageService.deletePrivateKey();
      _wallet = null;
      notifyListeners();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }
}
