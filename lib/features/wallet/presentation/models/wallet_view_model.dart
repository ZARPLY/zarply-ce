import 'dart:async';

import 'package:flutter/material.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/services/transaction_parser_service.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/repositories/wallet_repository.dart';

class WalletViewModel extends ChangeNotifier {
  final WalletRepository _walletRepository = WalletRepositoryImpl();

  ProgramAccount? tokenAccount;
  Wallet? wallet;
  double walletAmount = 0;
  double solBalance = 0;
  bool isLoading = true;
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

    if (providedWallet != null && providedTokenAccount != null) {
      wallet = providedWallet;
      tokenAccount = providedTokenAccount;

      await refreshBalances();

      await updateTransactionCount();

      isLoading = false;
      notifyListeners();

      await loadTransactions();
    } else {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshBalances() async {
    if (tokenAccount != null && wallet != null) {
      final double newWalletAmount =
          await _walletRepository.getZarpBalance(tokenAccount!.pubkey);
      final double newSolBalance =
          await _walletRepository.getSolBalance(wallet!.address);

      walletAmount = newWalletAmount;
      solBalance = newSolBalance;
      notifyListeners();
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

      notifyListeners();
    }

    if (storedTransactions.isEmpty || isRefreshing) {
      final String? lastSignature =
          await _walletRepository.getLastTransactionSignature();

      isLoadingMore = true;
      loadedTransactions = 0;
      notifyListeners();

      try {
        await _walletRepository.getAccountTransactions(
          walletAddress: tokenAccount!.pubkey,
          afterSignature: lastSignature,
          onBatchLoaded: (List<TransactionDetails?> batch) {
            if ((_walletRepository as WalletRepositoryImpl).isCancelled) {
              return;
            }

            _processNewTransactionBatch(batch, storedTransactions);
            loadedTransactions +=
                batch.where((TransactionDetails? tx) => tx != null).length;

            transactions =
                Map<String, List<TransactionDetails?>>.from(storedTransactions);

            _updateOldestSignature(storedTransactions);

            notifyListeners();
          },
        );
      } finally {
        if (!(_walletRepository as WalletRepositoryImpl).isCancelled) {
          isLoadingMore = false;
          isRefreshing = false;

          updateHasMoreTransactions();
        } else {
          isLoadingMore = false;
          isRefreshing = false;
        }
        notifyListeners();
      }
    }
  }

  Future<void> _processNewTransactionBatch(
    List<TransactionDetails?> batchTransactions,
    Map<String, List<TransactionDetails?>> storedTransactions, {
    bool isOlderTransactions = false,
  }) async {
    final Set<String> existingSignatures = <String>{};

    for (final List<TransactionDetails?> monthTransactions
        in storedTransactions.values) {
      for (final TransactionDetails? tx in monthTransactions) {
        if (tx != null) {
          final String sig = tx.transaction.toJson()['signatures'][0];
          existingSignatures.add(sig);
        }
      }
    }

    final Map<String, List<TransactionDetails?>> groupedBatch =
        <String, List<TransactionDetails?>>{};

    for (final TransactionDetails? transaction in batchTransactions) {
      if (transaction == null) continue;

      final DateTime transactionDate = transaction.blockTime != null
          ? DateTime.fromMillisecondsSinceEpoch(transaction.blockTime! * 1000)
          : DateTime.now();

      final String monthKey =
          '${transactionDate.year}-${transactionDate.month.toString().padLeft(2, '0')}';

      if (!groupedBatch.containsKey(monthKey)) {
        groupedBatch[monthKey] = <TransactionDetails?>[];
      }
      groupedBatch[monthKey]!.add(transaction);
    }

    bool hasNewTransactions = false;
    for (final String monthKey in groupedBatch.keys) {
      if (!storedTransactions.containsKey(monthKey)) {
        storedTransactions[monthKey] = <TransactionDetails?>[];
      }

      final List<TransactionDetails?> uniqueNewTransactions =
          groupedBatch[monthKey]!.where((TransactionDetails? tx) {
        if (tx == null) return false;
        final String sig = tx.transaction.toJson()['signatures'][0];
        final bool isUnique = !existingSignatures.contains(sig);
        if (isUnique) {
          existingSignatures.add(sig);
          hasNewTransactions = true;
        }
        return isUnique;
      }).toList();

      if (uniqueNewTransactions.isNotEmpty) {
        if (isOlderTransactions) {
          storedTransactions[monthKey]!.addAll(uniqueNewTransactions);
        } else {
          storedTransactions[monthKey]!.insertAll(0, uniqueNewTransactions);
        }
      }
    }

    transactions =
        Map<String, List<TransactionDetails?>>.from(storedTransactions);

    if (hasNewTransactions) {
      await _walletRepository.storeTransactions(storedTransactions);
    }
  }

  Future<void> refreshTransactionsFromButton() async {
    unawaited(refreshIndicatorKey?.currentState?.show());
  }

  Future<void> refreshTransactions() async {
    isRefreshing = true;
    notifyListeners();

    await Future.wait(<Future<void>>[
      refreshBalances(),
      loadTransactions(),
    ]);
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
      // Count displayed transactions
      final int displayedCount =
          transactions[monthKey]!.where((TransactionDetails? tx) {
        final TransactionTransferInfo? transferInfo = parseTransferDetails(tx);
        return transferInfo != null && transferInfo.amount != 0;
      }).length;

      transactionItems.add(<String, dynamic>{
        'type': 'header',
        'month': monthKey, // Will be formatted in the view
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

  void cancelOperations() {
    (_walletRepository as WalletRepositoryImpl).cancelTransactions();
  }

  @override
  void dispose() {
    cancelOperations();
    super.dispose();
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
      await _walletRepository.getAccountTransactions(
        walletAddress: tokenAccount!.pubkey,
        limit: 100,
        beforeSignature: oldestLoadedSignature,
        onBatchLoaded: (List<TransactionDetails?> batch) {
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
      notifyListeners();
    }
  }

  void _updateOldestSignature(
    Map<String, List<TransactionDetails?>> transactions,
  ) {
    DateTime? oldestDate;
    String? oldestSig;

    for (final List<TransactionDetails?> list in transactions.values) {
      for (final TransactionDetails? tx in list) {
        if (tx != null) {
          final DateTime txDate = tx.blockTime != null
              ? DateTime.fromMillisecondsSinceEpoch(tx.blockTime! * 1000)
              : DateTime.now();

          if (oldestDate == null || txDate.isBefore(oldestDate)) {
            oldestDate = txDate;
            oldestSig = tx.transaction.toJson()['signatures'][0];
          }
        }
      }
    }

    oldestLoadedSignature = oldestSig;
  }

  Future<void> updateTransactionCount() async {
    if (tokenAccount == null) return;

    final int? storedCount =
        await _walletRepository.getStoredTransactionCount();

    if (storedCount != null) {
      totalSignatures = storedCount;
    } else {
      final int count = await _walletRepository.getTransactionCount(
        tokenAccount!.pubkey,
      );
      totalSignatures = count;
      await _walletRepository.storeTransactionCount(count);
    }

    updateHasMoreTransactions();
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
}
