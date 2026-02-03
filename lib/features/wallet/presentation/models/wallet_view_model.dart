import 'dart:async';

import 'package:flutter/material.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/services/balance_cache_service.dart';
import '../../../../core/services/transaction_parser_service.dart';
import '../../../../core/services/transaction_storage_service.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/repositories/wallet_repository.dart';

class WalletViewModel extends ChangeNotifier {
  WalletViewModel() {
    _balanceCacheService = BalanceCacheService(
      walletRepository: _walletRepository,
    );
  }
  final WalletRepository _walletRepository = WalletRepositoryImpl();
  final TransactionStorageService _transactionStorageService = TransactionStorageService();
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
    if (_disposed) return;
    if (tokenAccount == null) {
      throw Exception('TokenAccount is null, cannot load transactions');
    }

    final Map<String, List<TransactionDetails?>> storedTransactions = await loadStoredTransactions();
    
    if (_disposed) return; // Check again after async operation

    if (storedTransactions.isNotEmpty) {
      transactions = Map<String, List<TransactionDetails?>>.from(storedTransactions);

      _updateOldestSignature(storedTransactions);

      updateHasMoreTransactions();
      isLoadingTransactions = false;
      if (!_disposed) {
        notifyListeners();
      }

      // If we already have transactions loaded (from the limited fetch during access),
      // we don't need to fetch them again immediately
      if (!isRefreshing && transactions.isNotEmpty) {
        // Merge legacy history before returning
        await _mergeLegacyHistory();
        if (_disposed) return;
        return;
      }
    }

    if (_disposed) return; // Check before starting new operations

    (_walletRepository as WalletRepositoryImpl).resetCancellation();

    if (storedTransactions.isEmpty || isRefreshing) {
      final String? lastSignature = await _walletRepository.getLastTransactionSignature();

      loadedTransactions = 0;
      notifyListeners();

      try {
        await _walletRepository.getNewerTransactions(
          walletAddress: tokenAccount!.pubkey,
          lastKnownSignature: lastSignature,
          onBatchLoaded: (List<TransactionDetails?> batch) {
            if (_walletRepository.isCancelled || _disposed) {
              return;
            }

            // Process batch and store signatures asynchronously (fire and forget)
            _processNewTransactionBatch(batch, storedTransactions).then((_) {
              if (!_disposed && !_walletRepository.isCancelled) {
                loadedTransactions += batch.where((TransactionDetails? tx) => tx != null).length;
                transactions = Map<String, List<TransactionDetails?>>.from(storedTransactions);
                _updateOldestSignature(storedTransactions);
                isLoadingTransactions = false;
                if (!_disposed) {
                  notifyListeners();
                }
              }
            }).catchError((Object e) {
              debugPrint('[WalletVM] Error processing batch: $e');
            });
          },
        );
        
        if (_disposed) return; // Check after async operation
        
        // Merge legacy history after loading new transactions
        if (!_disposed) {
          await _mergeLegacyHistory();
        }
      } catch (e) {
        if (!_disposed) {
          throw Exception('Error loading transactions: $e');
        }
      }
    }
  }

  /// Merge legacy transaction history with current transactions
  Future<void> _mergeLegacyHistory() async {
    if (_disposed) return;
    
    try {
      // Load legacy transactions (already filtered by signatures in getStoredLegacyTransactions)
      final Map<String, List<TransactionDetails?>> legacyTx =
          await _walletRepository.getStoredLegacyTransactions();

      if (_disposed) return; // Check after async operation
      if (legacyTx.isEmpty) return; // No legacy history

      // Merge with current transactions
      final Map<String, List<TransactionDetails?>> merged = Map<String, List<TransactionDetails?>>.from(transactions);

      legacyTx.forEach((String monthKey, List<TransactionDetails?> legacyList) {
        if (merged.containsKey(monthKey)) {
          merged[monthKey] = <TransactionDetails?>[...merged[monthKey]!, ...legacyList];
        } else {
          merged[monthKey] = legacyList;
        }
      });

      // Sort within each month by blockTime (newest first)
      merged.forEach((String key, List<TransactionDetails?> txList) {
        txList.sort((TransactionDetails? a, TransactionDetails? b) {
          final int timeA = a?.blockTime ?? 0;
          final int timeB = b?.blockTime ?? 0;
          return timeB.compareTo(timeA); // Descending
        });
      });

      transactions = merged;
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      // Don't fail if legacy merge fails
      debugPrint('[WalletVM] Failed to merge legacy history: $e');
    }
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
      }) result = await _walletRepository.checkAndMigrateLegacyIfNeeded(wallet!);

      if (_disposed) return; // Check again after async operation

      if (result.hasLegacyAccount && result.migrationSignature != null) {
        // Mark as system transaction
        await _transactionStorageService.addSystemTransactionSignature(result.migrationSignature!);

        if (_disposed) return; // Check again after async operation

        // Reload transactions to update UI (system transactions will be filtered automatically)
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

  // Load transactions from the repository
  Future<Map<String, List<TransactionDetails?>>> loadStoredTransactions() async {
    // getStoredTransactions already filters system transactions by signatures
    final Map<String, List<TransactionDetails?>> storedTransactions = await _walletRepository.getStoredTransactions();

    transactions = Map<String, List<TransactionDetails?>>.from(storedTransactions);
    notifyListeners();

    return storedTransactions;
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
          onBatchLoaded: (List<TransactionDetails?> batch) {
            if (_walletRepository.isCancelled || _disposed) {
              return;
            }

            // Process batch and store signatures asynchronously (fire and forget)
            _processNewTransactionBatch(
              batch,
              storedTransactions,
              isOlderTransactions: true,
            ).then((_) {
              if (!_disposed && !_walletRepository.isCancelled) {
                loadedTransactions += batch.where((TransactionDetails? tx) => tx != null).length;
                transactions = Map<String, List<TransactionDetails?>>.from(storedTransactions);
                _updateOldestSignature(storedTransactions);
                if (!_disposed) {
                  notifyListeners();
                }
              }
            }).catchError((Object e) {
              debugPrint('[WalletVM] Error processing batch: $e');
            });
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
    // Extract signatures from transactions and store them
    final Map<String, List<String>> signaturesByMonth = <String, List<String>>{};
    
    for (final TransactionDetails? tx in batch) {
      if (tx == null) continue;

      // Extract signature from transaction
      String? signature;
      try {
        final dynamic txJson = tx.transaction.toJson();
        if (txJson is Map<String, dynamic> && txJson['signatures'] != null) {
          final List<dynamic> sigs = txJson['signatures'] as List<dynamic>;
          if (sigs.isNotEmpty) {
            signature = sigs[0].toString();
          }
        }
      } catch (e) {
        debugPrint('[WalletVM] Failed to extract signature: $e');
      }

      final DateTime txDate = DateTime.fromMillisecondsSinceEpoch(
        tx.blockTime! * 1000,
      );
      final String monthKey = '${txDate.year}-${txDate.month.toString().padLeft(2, '0')}';

      if (!storedTransactions.containsKey(monthKey)) {
        storedTransactions[monthKey] = <TransactionDetails?>[];
        signaturesByMonth[monthKey] = <String>[];
      }

      if (isOlderTransactions) {
        storedTransactions[monthKey]!.add(tx);
        if (signature != null) {
          signaturesByMonth[monthKey]!.add(signature);
        }
      } else {
        storedTransactions[monthKey]!.insert(0, tx);
        if (signature != null) {
          signaturesByMonth[monthKey]!.insert(0, signature);
        }
      }
    }

    // Store transactions
    await _walletRepository.storeTransactions(storedTransactions);
    
    // Store signatures for filtering
    if (signaturesByMonth.isNotEmpty) {
      // Merge with existing signatures, preserving order
      final Map<String, List<String>> existingSignatures = await _transactionStorageService.getStoredTransactionSignatures();
      
      // For each month, merge signatures while preserving order
      final Map<String, List<String>> mergedSignatures = <String, List<String>>{};
      
      // First, add existing signatures
      existingSignatures.forEach((String monthKey, List<String> sigs) {
        mergedSignatures[monthKey] = List<String>.from(sigs);
      });
      
      // Then, add new signatures in the correct position
      signaturesByMonth.forEach((String monthKey, List<String> newSigs) {
        if (!mergedSignatures.containsKey(monthKey)) {
          mergedSignatures[monthKey] = <String>[];
        }
        
        // For newer transactions (inserted at start), prepend new signatures
        if (!isOlderTransactions) {
          // Prepend new signatures, avoiding duplicates
          for (final String sig in newSigs.reversed) {
            if (!mergedSignatures[monthKey]!.contains(sig)) {
              mergedSignatures[monthKey]!.insert(0, sig);
            }
          }
        } else {
          // For older transactions (appended at end), append new signatures
          for (final String sig in newSigs) {
            if (!mergedSignatures[monthKey]!.contains(sig)) {
              mergedSignatures[monthKey]!.add(sig);
            }
          }
        }
      });
      
      await _transactionStorageService.storeTransactionSignatures(mergedSignatures);
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

  @override
  void dispose() {
    _disposed = true;
    stopLegacyMonitoring();
    cancelOperations();
    super.dispose();
  }
}
