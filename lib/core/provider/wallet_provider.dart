import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/data/services/wallet_solana_service.dart';
import '../../features/wallet/data/services/wallet_storage_service.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../services/balance_cache_service.dart';

class WalletProvider extends ChangeNotifier {
  WalletProvider() {
    _balanceCacheService = BalanceCacheService(
      walletRepository: _walletRepository,
    );
  }
  final WalletStorageService _walletStorageService = WalletStorageService();
  final WalletSolanaService _walletSolanaService = WalletSolanaService(
    rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
    websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
  );
  final WalletRepository _walletRepository = WalletRepositoryImpl();
  late final BalanceCacheService _balanceCacheService;

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

  Future<void> fetchLimitedTransactions() async {
    if (_wallet == null || _userTokenAccount == null) return;

    try {
      final String? lastSignature =
          await _walletRepository.getLastTransactionSignature();

      (_walletRepository as WalletRepositoryImpl).resetCancellation();
      await _walletSolanaService.getAccountTransactions(
        walletAddress: _userTokenAccount!.pubkey,
        until: lastSignature,
        limit: 10,
        onBatchLoaded: (List<TransactionDetails?> batch) {
          if (batch.isEmpty) return;

          _processAndStoreTransactions(batch);
        },
        isCancelled: () => _walletRepository.isCancelled,
      );
    } catch (e) {
      debugPrint('Error fetching limited transactions: $e');
    }
  }

  Future<void> refreshTransactions() async {
    if (_wallet == null || _userTokenAccount == null) return;

    (_walletRepository as WalletRepositoryImpl).resetCancellation();

    try {
      final String? lastSignature =
          await _walletRepository.getLastTransactionSignature();
      debugPrint('Last signature: $lastSignature');

      await _walletRepository.getNewerTransactions(
        walletAddress: _userTokenAccount!.pubkey,
        lastKnownSignature: lastSignature,
        onBatchLoaded: (List<TransactionDetails?> batch) {
          debugPrint('Processing and storing transactions: ${batch.length}');
          if (batch.isEmpty) return;

          _processAndStoreTransactions(batch);
        },
      );
    } catch (e) {
      debugPrint('Error refreshing transactions: $e');
    }
  }

  // Helper method to process and store transactions in secure storage
  Future<void> _processAndStoreTransactions(
    List<TransactionDetails?> batch,
  ) async {
    try {
      // Get current stored transactions
      final Map<String, List<TransactionDetails?>> transactions =
          await _walletRepository.getStoredTransactions();

      // Process new transactions
      for (final TransactionDetails? tx in batch) {
        if (tx == null) continue;

        final DateTime txDate = DateTime.fromMillisecondsSinceEpoch(
          tx.blockTime! * 1000,
        );
        final String monthKey =
            '${txDate.year}-${txDate.month.toString().padLeft(2, '0')}';

        if (!transactions.containsKey(monthKey)) {
          transactions[monthKey] = <TransactionDetails?>[];
        }
        transactions[monthKey]!.insert(0, tx);
      }

      // Store updated transactions
      await _walletRepository.storeTransactions(transactions);

      // Store the latest transaction signature for future fetches
      if (batch.isNotEmpty && batch.first != null) {
        final String signature =
            batch.first!.transaction.toJson()['signatures'][0];
        await _walletRepository.storeLastTransactionSignature(signature);
      }
    } catch (e) {
      debugPrint('Error processing transactions: $e');
    }
  }

  Future<void> fetchAndCacheBalances() async {
    if (_wallet == null || _userTokenAccount == null) return;

    try {
      await _balanceCacheService.getBothBalances(
        zarpAddress: _userTokenAccount!.pubkey,
        solAddress: _wallet!.address,
        forceRefresh: true,
      );
    } catch (e) {
      debugPrint('Error fetching balances: $e');
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

  /// Refresh balances after a payment is completed
  Future<void> onPaymentCompleted() async {
    if (_wallet != null && _userTokenAccount != null) {
      try {
        debugPrint('Payment completed, refreshing balances...');
        await _balanceCacheService.getBothBalances(
          zarpAddress: _userTokenAccount!.pubkey,
          solAddress: _wallet!.address,
          forceRefresh: true, // Force network fetch after payment
        );
        debugPrint('Balances refreshed after payment');
      } catch (e) {
        debugPrint('Error refreshing balances after payment: $e');
      }
    }
  }
}
