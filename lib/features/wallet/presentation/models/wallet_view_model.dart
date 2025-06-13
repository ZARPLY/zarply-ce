import 'dart:async';

import 'package:flutter/material.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/services/balance_cache_service.dart';
import '../../../../core/services/transaction_parser_service.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/repositories/wallet_repository.dart';

class WalletViewModel extends ChangeNotifier {
  WalletViewModel() {
    _balanceCacheService = BalanceCacheService(
      walletRepository: _walletRepository,
    );
  }
  final WalletRepository _walletRepository = WalletRepositoryImpl();
  late final BalanceCacheService _balanceCacheService;

  ProgramAccount? tokenAccount;
  Wallet? wallet;
  double walletAmount = 0;
  double solBalance = 0;
  bool isLoading = true;
  bool isLoadingTransactions = false;
  bool isExpanded = false;
  bool isRefreshing = false;
  bool isLoadingMore = false;
  int totalSignatures = 0;
  int loadedTransactions = 0;

  Map<String, List<TransactionDetails?>> transactions =
      <String, List<TransactionDetails?>>{};

  bool hasMoreTransactionsToLoad = false;
  String? oldestLoadedSignature;

  GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;

  void toggleExpanded() {
    isExpanded = !isExpanded;
    notifyListeners();
  }

  Future<void> loadWalletData(
    Wallet? providedWallet,
    ProgramAccount? providedTokenAccount,
  ) async {
    isLoading = true;
    notifyListeners();

    try {
      if (providedWallet != null && providedTokenAccount != null) {
        wallet = providedWallet;
        tokenAccount = providedTokenAccount;

        // Use cached balances for faster initial load
        await loadCachedBalances();

        isLoading = false;
        isLoadingTransactions = true;
        notifyListeners();

        try {
          await loadTransactions();
          await updateTransactionCount();
        } catch (e) {
          rethrow;
        }
      }
    } catch (e) {
      throw Exception('Error loading wallet data: $e');
    } finally {
      isLoading = false;
      isLoadingTransactions = false;
      notifyListeners();
    }
  }

  /// Load cached balances for fast initial display
  Future<void> loadCachedBalances() async {
    if (tokenAccount != null && wallet != null) {
      try {
        final ({double solBalance, double zarpBalance}) balances =
            await _balanceCacheService.getBothBalances(
          zarpAddress: tokenAccount!.pubkey,
          solAddress: wallet!.address,
          forceRefresh: false, // Use cache if available
        );

        walletAmount = balances.zarpBalance;
        solBalance = balances.solBalance;
        notifyListeners();

        debugPrint(
          'Loaded cached balances - ZARP: $walletAmount, SOL: $solBalance',
        );
      } catch (e) {
        debugPrint('Error loading cached balances: $e');
        // If cache fails, fall back to network refresh
        await refreshBalances();
      }
    }
  }

  /// Refresh balances from network and update cache
  /// This should be called when user manually refreshes or after payments
  Future<void> refreshBalances() async {
    if (tokenAccount != null && wallet != null) {
      try {
        final ({double solBalance, double zarpBalance}) balances =
            await _balanceCacheService.refreshBalances(
          zarpAddress: tokenAccount!.pubkey,
          solAddress: wallet!.address,
        );

        walletAmount = balances.zarpBalance;
        solBalance = balances.solBalance;
        notifyListeners();

        debugPrint(
          'Refreshed balances - ZARP: $walletAmount, SOL: $solBalance',
        );
      } catch (e) {
        debugPrint('Error refreshing balances: $e');
        rethrow;
      }
    }
  }

  /// Force refresh balances from network (used after payments)
  Future<void> forceRefreshBalances() async {
    if (tokenAccount != null && wallet != null) {
      try {
        final ({double solBalance, double zarpBalance}) balances =
            await _balanceCacheService.getBothBalances(
          zarpAddress: tokenAccount!.pubkey,
          solAddress: wallet!.address,
          forceRefresh: true, // Force network fetch
        );

        walletAmount = balances.zarpBalance;
        solBalance = balances.solBalance;
        notifyListeners();

        debugPrint(
          'Force refreshed balances - ZARP: $walletAmount, SOL: $solBalance',
        );
      } catch (e) {
        debugPrint('Error force refreshing balances: $e');
        rethrow;
      }
    }
  }

  Future<void> loadTransactions() async {
    if (tokenAccount == null) return;

    final Map<String, List<TransactionDetails?>> storedTransactions =
        await _walletRepository.getStoredTransactions();

    if (storedTransactions.isNotEmpty) {
      transactions =
          Map<String, List<TransactionDetails?>>.from(storedTransactions);

      _updateOldestSignature(storedTransactions);

      updateHasMoreTransactions();
      isLoadingTransactions = false;
      notifyListeners();
    }

    (_walletRepository as WalletRepositoryImpl).resetCancellation();

    if (storedTransactions.isEmpty || isRefreshing) {
      final String? lastSignature =
          await _walletRepository.getLastTransactionSignature();

      loadedTransactions = 0;
      notifyListeners();

      try {
        await _walletRepository.getNewerTransactions(
          walletAddress: tokenAccount!.pubkey,
          lastKnownSignature: lastSignature,
          onBatchLoaded: (List<TransactionDetails?> batch) {
            if (_walletRepository.isCancelled) {
              return;
            }

            _processNewTransactionBatch(batch, storedTransactions);
            loadedTransactions +=
                batch.where((TransactionDetails? tx) => tx != null).length;

            transactions =
                Map<String, List<TransactionDetails?>>.from(storedTransactions);

            _updateOldestSignature(storedTransactions);
            isLoadingTransactions = false;
            notifyListeners();
          },
        );
      } catch (e) {
        throw Exception('Error loading transactions: $e');
      }
    }
  }

  Future<void> refreshTransactionsFromButton() async {
    unawaited(refreshIndicatorKey?.currentState?.show());
  }

  /// Refresh transactions and balances
  /// This is called when user pulls to refresh
  Future<void> refreshTransactions() async {
    if (isRefreshing) return;

    isRefreshing = true;
    notifyListeners();

    try {
      // Refresh balances from network when user manually refreshes
      await refreshBalances();
      await loadTransactions();
    } catch (e) {
      throw Exception('Error in refreshTransactions: $e');
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  /// Call this after a successful payment to update balances
  Future<void> onPaymentCompleted() async {
    debugPrint('Payment completed, refreshing balances...');
    await forceRefreshBalances();
  }

  TransactionTransferInfo? parseTransferDetails(
    TransactionDetails? transaction,
  ) {
    if (transaction == null || tokenAccount == null) return null;

    return _walletRepository.parseTransferDetails(
      transaction,
      tokenAccount!.pubkey,
    );
  }

  List<dynamic> getSortedTransactionItems() {
    final List<dynamic> transactionItems = <dynamic>[];

    final List<String> sortedMonths = transactions.keys.toList()
      ..sort((String a, String b) => b.compareTo(a));

    for (final String monthKey in sortedMonths) {
      final int displayedCount =
          transactions[monthKey]!.where((TransactionDetails? tx) {
        final TransactionTransferInfo? transferInfo = parseTransferDetails(tx);
        return transferInfo != null && transferInfo.amount != 0;
      }).length;

      transactionItems.add(<String, dynamic>{
        'type': 'header',
        'month': monthKey,
        'monthKey': monthKey,
        'count': displayedCount,
      });

      final List<TransactionDetails?> sortedTransactions =
          List<TransactionDetails?>.from(transactions[monthKey]!)
            ..sort((TransactionDetails? a, TransactionDetails? b) {
              if (a == null || b == null) return 0;
              return (b.blockTime ?? 0).compareTo(a.blockTime ?? 0);
            });

      transactionItems.addAll(sortedTransactions);
    }

    return transactionItems;
  }

  Future<void> loadMoreTransactions() async {
    if (tokenAccount == null || isLoadingMore || !hasMoreTransactionsToLoad) {
      return;
    }

    (_walletRepository as WalletRepositoryImpl).resetCancellation();

    isLoadingMore = true;
    loadedTransactions = 0;
    notifyListeners();

    final Map<String, List<TransactionDetails?>> storedTransactions =
        Map<String, List<TransactionDetails?>>.from(transactions);

    try {
      await _walletRepository.getOlderTransactions(
        walletAddress: tokenAccount!.pubkey,
        oldestSignature: oldestLoadedSignature!,
        onBatchLoaded: (List<TransactionDetails?> batch) {
          if (_walletRepository.isCancelled) {
            return;
          }

          _processNewTransactionBatch(
            batch,
            storedTransactions,
            isOlderTransactions: true,
          );
          loadedTransactions +=
              batch.where((TransactionDetails? tx) => tx != null).length;

          transactions =
              Map<String, List<TransactionDetails?>>.from(storedTransactions);
          _updateOldestSignature(storedTransactions);
          notifyListeners();
        },
      );

      if (!_walletRepository.isCancelled) {
        updateHasMoreTransactions();
      }
    } catch (e) {
      throw Exception('Error loading more transactions: $e');
    } finally {
      debugPrint('Loading more finished');
      isLoadingMore = false;

      if (!_walletRepository.isCancelled) {
        updateHasMoreTransactions();
      }
      notifyListeners();
    }
  }

  void updateHasMoreTransactions() {
    int loadedCount = 0;
    for (final List<TransactionDetails?> txList in transactions.values) {
      loadedCount +=
          txList.where((TransactionDetails? tx) => tx != null).length;
    }

    loadedTransactions = loadedCount;
    hasMoreTransactionsToLoad = loadedTransactions < totalSignatures;
    notifyListeners();
  }

  Future<void> updateTransactionCount() async {
    if (tokenAccount == null) return;

    try {
      final int networkCount =
          await _walletRepository.getTransactionCount(tokenAccount!.pubkey);
      totalSignatures = networkCount;

      await _walletRepository.storeTransactionCount(networkCount);
      updateHasMoreTransactions();
    } catch (e) {
      final int? storedCount =
          await _walletRepository.getStoredTransactionCount();
      if (storedCount != null) {
        totalSignatures = storedCount;
        updateHasMoreTransactions();
      }
    }
  }

  void _processNewTransactionBatch(
    List<TransactionDetails?> batch,
    Map<String, List<TransactionDetails?>> storedTransactions, {
    bool isOlderTransactions = false,
  }) {
    for (final TransactionDetails? tx in batch) {
      if (tx == null) continue;

      final DateTime txDate = DateTime.fromMillisecondsSinceEpoch(
        tx.blockTime! * 1000,
      );
      final String monthKey =
          '${txDate.year}-${txDate.month.toString().padLeft(2, '0')}';

      if (!storedTransactions.containsKey(monthKey)) {
        storedTransactions[monthKey] = <TransactionDetails?>[];
      }

      if (isOlderTransactions) {
        storedTransactions[monthKey]!.add(tx);
      } else {
        storedTransactions[monthKey]!.insert(0, tx);
      }
    }

    _walletRepository.storeTransactions(storedTransactions);
  }

  void _updateOldestSignature(
    Map<String, List<TransactionDetails?>> storedTransactions,
  ) {
    DateTime? oldestTime;

    for (final List<TransactionDetails?> txList in storedTransactions.values) {
      for (final TransactionDetails? tx in txList) {
        if (tx?.blockTime != null) {
          final DateTime txTime = DateTime.fromMillisecondsSinceEpoch(
            tx!.blockTime! * 1000,
          );
          if (oldestTime == null || txTime.isBefore(oldestTime)) {
            oldestTime = txTime;
            // Use block time as a fallback identifier for oldest transaction
            oldestLoadedSignature = tx.blockTime.toString();
          }
        }
      }
    }
  }

  /// Get cache information for debugging
  Future<String> getCacheInfo() async {
    return await _balanceCacheService.getCacheAgeInfo();
  }

  /// Clear balance cache (useful for logout)
  Future<void> clearBalanceCache() async {
    await _balanceCacheService.clearCache();
  }

  /// Cancel ongoing operations to prevent memory leaks
  void cancelOperations() {
    (_walletRepository as WalletRepositoryImpl).cancelTransactions();
  }

  @override
  void dispose() {
    cancelOperations();
    super.dispose();
  }
}
