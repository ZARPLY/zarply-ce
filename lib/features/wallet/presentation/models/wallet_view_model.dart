import 'dart:async';

import 'package:flutter/material.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/services/balance_cache_service.dart';
import '../../../../core/services/exchange_rate_service.dart';
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

  // Cache for parsed transactions to avoid re-parsing
  final Map<String, TransactionTransferInfo> _transactionCache =
      <String, TransactionTransferInfo>{};
  String? _lastSelectedCurrency;

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

  Map<String, List<TransactionDetails?>> transactions =
      <String, List<TransactionDetails?>>{};

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
        final ({double solBalance, double zarpBalance}) balances =
            await _balanceCacheService.getBothBalances(
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
        final ({double solBalance, double zarpBalance}) balances =
            await _balanceCacheService.refreshBalances(
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
        final ({double solBalance, double zarpBalance}) balances =
            await _balanceCacheService.getBothBalances(
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

  Future<void> loadTransactions({String? selectedCurrency}) async {
    // For SOL transactions, we need to load from the wallet address
    // For ZARP transactions, we load from the token account
    final String addressToUse = selectedCurrency == 'SOL' && wallet != null
        ? wallet!.address
        : (tokenAccount?.pubkey ?? '');

    if (addressToUse.isEmpty) return;

    final Map<String, List<TransactionDetails?>> storedTransactions =
        await loadStoredTransactions(selectedCurrency: selectedCurrency);

    if (storedTransactions.isNotEmpty) {
      transactions =
          Map<String, List<TransactionDetails?>>.from(storedTransactions);

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
      final String? lastSignature =
          await _walletRepository.getLastTransactionSignature();

      loadedTransactions = 0;
      notifyListeners();

      try {
        await _walletRepository.getNewerTransactions(
          walletAddress: addressToUse,
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

  // Load transactions from the repository
  Future<Map<String, List<TransactionDetails?>>> loadStoredTransactions(
      {String? selectedCurrency}) async {
    // For SOL transactions, we need to get transactions from wallet address
    // For ZARP transactions, we get from token account
    final String addressToUse = selectedCurrency == 'SOL' && wallet != null
        ? wallet!.address
        : (tokenAccount?.pubkey ?? '');

    if (addressToUse.isEmpty) return <String, List<TransactionDetails?>>{};

    final Map<String, List<TransactionDetails?>> storedTransactions =
        await _walletRepository.getStoredTransactions();

    // Filter transactions based on the selected currency
    final Map<String, List<TransactionDetails?>> filteredTransactions =
        <String, List<TransactionDetails?>>{};

    for (final MapEntry<String, List<TransactionDetails?>> entry
        in storedTransactions.entries) {
      final List<TransactionDetails?> filteredList = <TransactionDetails?>[];

      for (final TransactionDetails? tx in entry.value) {
        if (tx != null) {
          // For both SOL and ZARP, we want to show the same transactions
          // but with different amounts (ZARP amounts vs converted SOL amounts)
          filteredList.add(tx);
        }
      }

      if (filteredList.isNotEmpty) {
        filteredTransactions[entry.key] = filteredList;
      }
    }

    transactions =
        Map<String, List<TransactionDetails?>>.from(filteredTransactions);
    notifyListeners();

    return filteredTransactions;
  }

  Future<void> refreshTransactionsFromButton() async {
    unawaited(refreshIndicatorKey?.currentState?.show());
  }

  Future<void> refreshTransactions({String? selectedCurrency}) async {
    if (isRefreshing) return;

    isRefreshing = true;
    notifyListeners();

    try {
      await refreshBalances();
      await loadTransactions(selectedCurrency: selectedCurrency);
    } catch (e) {
      throw Exception('Error in refreshTransactions: $e');
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<TransactionTransferInfo?> parseTransferDetails(
    TransactionDetails? transaction,
    String? selectedCurrency,
  ) async {
    if (transaction == null) return null;

    // Create a simple cache key based on block time and currency
    final String cacheKey = '${transaction.blockTime}_$selectedCurrency';

    // Check if we have cached data and currency hasn't changed
    if (_transactionCache.containsKey(cacheKey) &&
        _lastSelectedCurrency == selectedCurrency) {
      return _transactionCache[cacheKey];
    }

    TransactionTransferInfo? result;

    if (selectedCurrency == 'SOL') {
      // For SOL, we'll convert ZARP transactions to SOL amounts
      final TransactionTransferInfo? zarpTransaction =
          _walletRepository.parseTransferDetails(
        transaction,
        tokenAccount?.pubkey ?? '',
      );

      if (zarpTransaction != null) {
        // Convert ZARP amount to SOL using real-time exchange rate
        final double solToZarRate = await ExchangeRateService.getSolToZarRate();
        final double solAmount = zarpTransaction.amount / solToZarRate;

        print(
            'Transaction conversion: ${zarpTransaction.amount} ZAR = $solAmount SOL (rate: $solToZarRate)'); // Debug log

        result = TransactionTransferInfo(
          sender: zarpTransaction.sender,
          recipient: zarpTransaction.recipient,
          amount: solAmount,
          timestamp: zarpTransaction.timestamp,
          isExternalFunding: zarpTransaction.isExternalFunding,
          currency: 'SOL',
        );
      }
    } else {
      // For ZARP, parse ZARP token transactions
      if (tokenAccount == null) return null;
      result = _walletRepository.parseTransferDetails(
        transaction,
        tokenAccount!.pubkey,
      );
    }

    // Cache the result
    if (result != null) {
      _transactionCache[cacheKey] = result;
    }

    _lastSelectedCurrency = selectedCurrency;
    return result;
  }

  Future<List<dynamic>> getSortedTransactionItems(
      {String? selectedCurrency}) async {
    final List<dynamic> transactionItems = <dynamic>[];

    final List<String> sortedMonths = transactions.keys.toList()
      ..sort((String a, String b) => b.compareTo(a));

    for (final String monthKey in sortedMonths) {
      int displayedCount = 0;
      for (final TransactionDetails? tx in transactions[monthKey]!) {
        final TransactionTransferInfo? transferInfo =
            await parseTransferDetails(tx, selectedCurrency);
        if (transferInfo != null && transferInfo.amount != 0) {
          displayedCount++;
        }
      }

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

  @override
  void dispose() {
    cancelOperations();
    super.dispose();
  }
}
