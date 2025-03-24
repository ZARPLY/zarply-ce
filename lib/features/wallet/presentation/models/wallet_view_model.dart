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

  Map<String, List<TransactionDetails?>> transactions =
      <String, List<TransactionDetails?>>{};

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

      await Future.wait(<Future<void>>[
        refreshBalances(),
        loadTransactions(),
      ]);
    }

    isLoading = false;
    notifyListeners();
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

    if (storedTransactions.isEmpty || isRefreshing) {
      final String? lastSignature =
          await _walletRepository.getLastTransactionSignature();

      final Map<String, List<TransactionDetails?>> newTransactions =
          await _walletRepository.getAccountTransactions(
        walletAddress: tokenAccount!.pubkey,
        afterSignature: lastSignature,
      );

      final Set<String> existingSignatures = <String>{};
      if (lastSignature != null) {
        for (final List<TransactionDetails?> monthTransactions
            in storedTransactions.values) {
          for (final TransactionDetails? tx in monthTransactions) {
            if (tx != null) {
              final String sig = tx.transaction.toJson()['signatures'][0];
              existingSignatures.add(sig);
            }
          }
        }
      }

      bool hasNewTransactions = false;
      for (final String monthKey in newTransactions.keys) {
        if (!storedTransactions.containsKey(monthKey)) {
          storedTransactions[monthKey] = <TransactionDetails?>[];
        }

        final List<TransactionDetails?> uniqueNewTransactions =
            newTransactions[monthKey]!.where((TransactionDetails? tx) {
          if (tx == null) return false;
          final String sig = tx.transaction.toJson()['signatures'][0];
          final bool isUnique = !existingSignatures.contains(sig);
          if (isUnique) {
            hasNewTransactions = true;
          }
          return isUnique;
        }).toList();

        if (uniqueNewTransactions.isNotEmpty) {
          storedTransactions[monthKey]!.insertAll(0, uniqueNewTransactions);
        }
      }

      if (hasNewTransactions) {
        await _walletRepository.storeTransactions(storedTransactions);
      }
    }

    transactions = storedTransactions;
    isRefreshing = false;
    notifyListeners();
  }

  Future<void> refreshTransactions() async {
    isRefreshing = true;
    notifyListeners();

    await Future.wait(<Future<void>>[
      refreshBalances(),
      loadTransactions(),
    ]);
  }

  // Helper method to parse transaction details
  TransactionTransferInfo? parseTransferDetails(
    TransactionDetails? transaction,
  ) {
    if (transaction == null || tokenAccount == null) return null;

    return _walletRepository.parseTransferDetails(
      transaction,
      tokenAccount!.pubkey,
    );
  }

  // Get sorted transaction items for display
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
}
