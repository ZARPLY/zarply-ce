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

  Timer? _legacyMonitorTimer;
  bool _isMonitoringLegacy = false;
  bool _disposed = false;

  ProgramAccount? tokenAccount;
  Wallet? wallet;
  double walletAmount = 0;
  double solBalance = 0;
  bool isLoadingTransactions = false;
  bool isExpanded = false;
  bool isRefreshing = false;
  bool isLoadingMore = false;
  int totalSignatures = 0;
  int loadedTransactions = 0;

  Map<String, List<TransactionDetails?>> transactions = <String, List<TransactionDetails?>>{};

  bool hasMoreTransactionsToLoad = false;
  String? oldestLoadedSignature;

  GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;

  void toggleExpanded() {
    isExpanded = !isExpanded;
    notifyListeners();
  }

  Future<void> loadCachedBalances() async {
    if (tokenAccount != null && wallet != null) {
      try {
        final ({double solBalance, double zarpBalance}) balances = await _balanceCacheService.getBothBalances(
          zarpAddress: tokenAccount!.pubkey,
          solAddress: wallet!.address,
          forceRefresh: false,
        );

        walletAmount = balances.zarpBalance;
        solBalance = balances.solBalance;
        notifyListeners();
      } catch (e) {
        await refreshBalances();
      }
    }
  }

  Future<void> refreshBalances() async {
    if (tokenAccount != null && wallet != null) {
      try {
        final ({double solBalance, double zarpBalance}) balances = await _balanceCacheService.refreshBalances(
          zarpAddress: tokenAccount!.pubkey,
          solAddress: wallet!.address,
        );

        walletAmount = balances.zarpBalance;
        solBalance = balances.solBalance;
        notifyListeners();
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<void> forceRefreshBalances() async {
    if (tokenAccount != null && wallet != null) {
      try {
        final ({double solBalance, double zarpBalance}) balances = await _balanceCacheService.getBothBalances(
          zarpAddress: tokenAccount!.pubkey,
          solAddress: wallet!.address,
          forceRefresh: true, // Force network fetch
        );

        walletAmount = balances.zarpBalance;
        solBalance = balances.solBalance;
        notifyListeners();
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<void> loadTransactions() async {
    if (tokenAccount == null) {
      throw Exception('TokenAccount is null, cannot load transactions');
    }

    final Map<String, List<TransactionDetails?>> storedTransactions = await loadStoredTransactions();

    if (storedTransactions.isNotEmpty) {
      transactions = Map<String, List<TransactionDetails?>>.from(storedTransactions);

      _updateOldestSignature(storedTransactions);

      updateHasMoreTransactions();
      isLoadingTransactions = false;
      notifyListeners();

      // If we already have transactions loaded (from the limited fetch during access),
      // we don't need to fetch them again immediately
      if (!isRefreshing && transactions.isNotEmpty) {
        return;
      }
    }

    (_walletRepository as WalletRepositoryImpl).resetCancellation();

    if (storedTransactions.isEmpty || isRefreshing) {
      final String? lastSignature = await _walletRepository.getLastTransactionSignature(
        walletAddress: tokenAccount!.pubkey,
      );

      loadedTransactions = 0;
      notifyListeners();

      try {
        await _walletRepository.getNewerTransactions(
          walletAddress: tokenAccount!.pubkey,
          lastKnownSignature: lastSignature,
          onBatchLoaded: (List<TransactionDetails?> batch) async {
            if (_walletRepository.isCancelled) {
              return;
            }

            await _processNewTransactionBatch(batch, storedTransactions);
            loadedTransactions += batch.where((TransactionDetails? tx) => tx != null).length;

            transactions = Map<String, List<TransactionDetails?>>.from(storedTransactions);

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

  // Load transactions from the repository
  Future<Map<String, List<TransactionDetails?>>> loadStoredTransactions() async {
    if (tokenAccount == null) {
      return <String, List<TransactionDetails?>>{};
    }

    final Map<String, List<TransactionDetails?>> storedTransactions = await _walletRepository.getStoredTransactions(
      walletAddress: tokenAccount!.pubkey,
    );

    // Filter out system swap transactions by checking memo
    const String systemSwapMemo = 'system swap contract';
    final Map<String, List<TransactionDetails?>> filteredTransactions = <String, List<TransactionDetails?>>{};

    for (final String monthKey in storedTransactions.keys) {
      final List<TransactionDetails?> filteredTxs = storedTransactions[monthKey]!.where((TransactionDetails? tx) {
        if (tx == null) return false;

        // Check if transaction has system swap memo
        final String? memo = TransactionDetailsParser.extractMemo(tx);
        if (memo != null && memo == systemSwapMemo) {
          // Skip system swap transactions
          return false;
        }
        return true;
      }).toList();

      if (filteredTxs.isNotEmpty) {
        filteredTransactions[monthKey] = filteredTxs;
      }
    }

    transactions = Map<String, List<TransactionDetails?>>.from(filteredTransactions);
    notifyListeners();

    return filteredTransactions;
  }

  Future<void> refreshTransactionsFromButton() async {
    unawaited(refreshIndicatorKey?.currentState?.show());
  }

  Future<void> refreshTransactions() async {
    if (isRefreshing) return;

    isRefreshing = true;
    notifyListeners();

    try {
      await refreshBalances();
      await loadTransactions();
    } catch (e) {
      throw Exception('Error in refreshTransactions: $e');
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
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

    final List<String> sortedMonths = transactions.keys.toList()..sort((String a, String b) => b.compareTo(a));

    for (final String monthKey in sortedMonths) {
      final int displayedCount = transactions[monthKey]!.where((TransactionDetails? tx) {
        final TransactionTransferInfo? transferInfo = parseTransferDetails(tx);
        return transferInfo != null && transferInfo.amount != 0;
      }).length;

      transactionItems.add(<String, dynamic>{
        'type': 'header',
        'month': monthKey,
        'monthKey': monthKey,
        'count': displayedCount,
      });

      final List<TransactionDetails?> sortedTransactions = List<TransactionDetails?>.from(transactions[monthKey]!)
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

    final Map<String, List<TransactionDetails?>> storedTransactions = Map<String, List<TransactionDetails?>>.from(
      transactions,
    );

    try {
      await _walletRepository.getOlderTransactions(
        walletAddress: tokenAccount!.pubkey,
        oldestSignature: oldestLoadedSignature!,
        onBatchLoaded: (List<TransactionDetails?> batch) async {
          if (_walletRepository.isCancelled) {
            return;
          }

          await _processNewTransactionBatch(
            batch,
            storedTransactions,
            isOlderTransactions: true,
          );
          loadedTransactions += batch.where((TransactionDetails? tx) => tx != null).length;

          transactions = Map<String, List<TransactionDetails?>>.from(storedTransactions);
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
      loadedCount += txList.where((TransactionDetails? tx) => tx != null).length;
    }

    loadedTransactions = loadedCount;
    hasMoreTransactionsToLoad = loadedTransactions < totalSignatures;
    notifyListeners();
  }

  Future<void> updateTransactionCount() async {
    if (tokenAccount == null) return;

    try {
      final int networkCount = await _walletRepository.getTransactionCount(tokenAccount!.pubkey);
      totalSignatures = networkCount;

      await _walletRepository.storeTransactionCount(networkCount);
      updateHasMoreTransactions();
    } catch (e) {
      final int? storedCount = await _walletRepository.getStoredTransactionCount();
      if (storedCount != null) {
        totalSignatures = storedCount;
        updateHasMoreTransactions();
      }
    }
  }

  Future<void> _processNewTransactionBatch(
    List<TransactionDetails?> batch,
    Map<String, List<TransactionDetails?>> storedTransactions, {
    bool isOlderTransactions = false,
  }) async {
    const String systemSwapMemo = 'system swap contract';

    for (final TransactionDetails? tx in batch) {
      if (tx == null) continue;

      // Check if transaction has system swap memo
      final String? memo = TransactionDetailsParser.extractMemo(tx);
      if (memo != null && memo == systemSwapMemo) {
        // Skip system swap transactions
        continue;
      }

      final DateTime txDate = DateTime.fromMillisecondsSinceEpoch(
        tx.blockTime! * 1000,
      );
      final String monthKey = '${txDate.year}-${txDate.month.toString().padLeft(2, '0')}';

      if (!storedTransactions.containsKey(monthKey)) {
        storedTransactions[monthKey] = <TransactionDetails?>[];
      }

      if (isOlderTransactions) {
        storedTransactions[monthKey]!.add(tx);
      } else {
        storedTransactions[monthKey]!.insert(0, tx);
      }
    }

    if (tokenAccount != null) {
      await _walletRepository.storeTransactions(
        storedTransactions,
        walletAddress: tokenAccount!.pubkey,
      );
    }
  }

  /// Update the oldest signature based on the current transactions
  void updateOldestSignature() {
    if (transactions.isNotEmpty) {
      _updateOldestSignature(transactions);
    }
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
            oldestLoadedSignature = tx.transaction.toJson()['signatures'][0];
          }
        }
      }
    }
  }

  /// Cancel ongoing operations to prevent memory leaks
  void cancelOperations() {
    (_walletRepository as WalletRepositoryImpl).cancelTransactions();
  }

  /// Start continuous monitoring of legacy account
  void startLegacyMonitoring() {
    if (_isMonitoringLegacy || wallet == null || _disposed) return;

    _isMonitoringLegacy = true;

    // Check immediately
    checkLegacyBalance();

    // Then check every 30 seconds
    _legacyMonitorTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (!_disposed) {
          checkLegacyBalance();
        }
      },
    );
  }

  /// Stop monitoring legacy account
  void stopLegacyMonitoring() {
    _legacyMonitorTimer?.cancel();
    _legacyMonitorTimer = null;
    _isMonitoringLegacy = false;
  }

  /// Check legacy account balance and drain if needed
  Future<void> checkLegacyBalance() async {
    if (wallet == null || _disposed) return;

    try {
      final ({
        bool hasLegacyAccount,
        bool needsMigration,
        bool migrationComplete,
        String? migrationSignature,
        int? migrationTimestamp,
      })
      result = await _walletRepository.checkAndMigrateLegacyIfNeeded(wallet!);

      if (_disposed) return; // Check again after async operation

      if (result.hasLegacyAccount && result.migrationSignature != null) {
        // Drain transaction includes memo "system swap contract" - will be filtered automatically
        // Reload transactions to update UI (system swap transactions will be filtered by memo check)
        await loadTransactions();
      }
    } catch (e) {
      if (!_disposed) {
        debugPrint('[WalletVM] Legacy balance check failed: $e');
      }
      // Don't fail if check fails
    }
  }

  /// Check legacy migration if needed (for existing wallets on app start)
  Future<void> checkLegacyMigrationIfNeeded() async {
    if (wallet == null || _disposed) return;

    try {
      // Initial check
      await checkLegacyBalance();

      if (_disposed) return; // Check after async operation

      // Start continuous monitoring
      startLegacyMonitoring();
    } catch (e) {
      if (!_disposed) {
        debugPrint('[WalletVM] Legacy migration check failed: $e');
      }
      // Don't fail the app if migration check fails
    }
  }

  @override
  void dispose() {
    _disposed = true;
    stopLegacyMonitoring();
    cancelOperations();
    super.dispose();
  }
}
