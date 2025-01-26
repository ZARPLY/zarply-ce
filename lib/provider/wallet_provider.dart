import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../services/wallet_solana_service.dart';
import '../services/wallet_storage_service.dart';

class WalletProvider extends ChangeNotifier {
  final WalletStorageService _walletStorageService = WalletStorageService();
  final WalletSolanaService _walletSolanaService = WalletSolanaService(
    rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
    websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
  );

  Wallet? _wallet;
  ProgramAccount? _userTokenAccount;
  String? _recoveryPhrase;

  Wallet? get wallet => _wallet;

  ProgramAccount? get userTokenAccount => _userTokenAccount;

  bool get hasWallet => _wallet != null;

  String? get recoveryPhrase => _recoveryPhrase;

  bool get hasRecoveryPhrase => _recoveryPhrase != null;

  void setRecoveryPhrase(String phrase) {
    _recoveryPhrase = phrase;
    notifyListeners();
  }

  void clearRecoveryPhrase() {
    _recoveryPhrase = null;
    notifyListeners();
  }

  Future<bool> initialize() async {
    try {
      _wallet = await _walletStorageService.retrieveWallet();

      if (_wallet == null) {
        return false;
      }

      _userTokenAccount =
          await _walletSolanaService.getAssociatedTokenAccount(_wallet!);
      notifyListeners();

      return true;
    } catch (e) {
      _wallet = null;
      _userTokenAccount = null;
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

  Future<void> storeAssociatedTokenAccount(ProgramAccount tokenAccount) async {
    await _walletStorageService.saveAssociatedTokenAccount(tokenAccount);
    _userTokenAccount = tokenAccount;
    notifyListeners();
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
