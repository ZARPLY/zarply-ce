import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../features/wallet/data/services/wallet_solana_service.dart';
import '../../features/wallet/data/services/wallet_storage_service.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';

class WalletProvider extends ChangeNotifier {
  final WalletStorageService _walletStorageService = WalletStorageService();
  final WalletSolanaService _walletSolanaService = WalletSolanaService(
    rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
    websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
  );
  final WalletRepository _walletRepository = WalletRepositoryImpl();

  Wallet? _wallet;
  ProgramAccount? _userTokenAccount;
  String? _recoveryPhrase;
  Map<String, List<TransactionDetails?>> _transactions = {};

  Wallet? get wallet => _wallet;

  ProgramAccount? get userTokenAccount => _userTokenAccount;

  bool get hasWallet => _wallet != null;

  String? get recoveryPhrase => _recoveryPhrase;

  bool get hasRecoveryPhrase => _recoveryPhrase != null;

  Map<String, List<TransactionDetails?>> get transactions => _transactions;

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

      // Load transactions
      await refreshTransactions();

      notifyListeners();
      return true;
    } catch (e) {
      _wallet = null;
      _userTokenAccount = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshTransactions() async {
    if (_wallet == null || _userTokenAccount == null) return;

    try {
      // Get stored transactions first
      _transactions = await _walletRepository.getStoredTransactions();

      // Get the last transaction signature
      final String? lastSignature =
          await _walletRepository.getLastTransactionSignature();

      // Fetch new transactions
      await _walletRepository.getAccountTransactions(
        walletAddress: _userTokenAccount!.pubkey,
        afterSignature: lastSignature,
        onBatchLoaded: (List<TransactionDetails?> batch) {
          for (final TransactionDetails? tx in batch) {
            if (tx == null) continue;

            final DateTime txDate = DateTime.fromMillisecondsSinceEpoch(
              tx.blockTime! * 1000,
            );
            final String monthKey =
                '${txDate.year}-${txDate.month.toString().padLeft(2, '0')}';

            if (!_transactions.containsKey(monthKey)) {
              _transactions[monthKey] = <TransactionDetails?>[];
            }
            _transactions[monthKey]!.insert(0, tx);
          }

          // Store updated transactions
          _walletRepository.storeTransactions(_transactions);
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error refreshing transactions: $e');
    }
  }

  Future<void> storeWallet(Wallet wallet) async {
    try {
      await _walletStorageService.saveWalletPrivateKey(wallet);
      await _walletStorageService.saveWalletPublicKey(wallet);
      _wallet = wallet;
      notifyListeners();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> storeAssociatedTokenAccount(ProgramAccount tokenAccount) async {
    await _walletStorageService
        .saveAssociatedTokenAccountPublicKey(tokenAccount);
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

  Future<bool> hasPassword() async {
    return _walletStorageService.hasPassword();
  }
}
