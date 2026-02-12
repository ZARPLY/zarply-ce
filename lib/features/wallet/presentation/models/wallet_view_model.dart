import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/services/balance_cache_service.dart';
import '../../../../core/services/transaction_parser_service.dart';
import '../../data/repositories/wallet_repository_impl.dart';

/// View model for the wallet screen: balances, merged transaction history (new + legacy ZARP),
/// month-by-month visibility, and legacy migration monitoring.
class WalletViewModel extends ChangeNotifier {
  WalletViewModel() {
    _balanceCacheService = BalanceCacheService(
      walletRepository: _walletRepository,
    );
  }
  final WalletRepositoryImpl _walletRepository = WalletRepositoryImpl();
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

  /// Oldest month (YYYY-MM) currently shown in the list; newer months are hidden until "Load more".
  String? _visibleOldestMonth;

  GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;

  void toggleExpanded() {
    isExpanded = !isExpanded;
    notifyListeners();
  }

  String? _migrationLegacyAta;
  String? _migrationWalletAddress;
  ProgramAccount? _userLegacyAta;

  /// Resolves the migration/faucet wallet address and its legacy ATA from env.
  /// Used to filter out system transactions (faucet credits, migration drains) from the list.
  Future<void> _ensureMigrationLegacyAta() async {
    if (_migrationLegacyAta != null && _migrationWalletAddress != null) return;

    final String? migrationWalletAddress = dotenv.env['ZARP_MIGRATION_WALLET_ADDRESS'];
    if (migrationWalletAddress == null || migrationWalletAddress.isEmpty) {
      return;
    }

    try {
      _migrationWalletAddress = migrationWalletAddress;

      final ProgramAccount? migrationAccount = await _walletRepository.getLegacyAssociatedTokenAccount(
        migrationWalletAddress,
      );
      if (migrationAccount != null) {
        _migrationLegacyAta = migrationAccount.pubkey;
      }
    } catch (_) {
      // Skip filtering if resolution fails; list still works.
    }
  }

  /// Resolves the current user's legacy ZARP ATA so we can fetch and merge legacy history.
  Future<void> _ensureUserLegacyAta() async {
    if (_userLegacyAta != null || wallet == null) return;

    try {
      final ProgramAccount? legacyAccount = await _walletRepository.getLegacyAssociatedTokenAccount(wallet!.address);
      if (legacyAccount != null) {
        _userLegacyAta = legacyAccount;
      }
    } catch (_) {
      // No legacy ATA; we only show new-account history.
    }
  }

  /// Returns the first signature of [tx], or null if missing/malformed. Used for deduplication.
  String? _getTxSignature(TransactionDetails? tx) {
    if (tx == null) return null;
    try {
      final dynamic sigs = tx.transaction.toJson()['signatures'];
      if (sigs is List && sigs.isNotEmpty) {
        return sigs[0] as String?;
      }
    } catch (_) {
      // Malformed tx: skip dedup so it can still be shown.
    }
    return null;
  }

  /// True if [tx] should be hidden: involves migration/faucet wallet or migration legacy ATA.
  bool _shouldHideSystemTransaction(TransactionDetails tx) {
    if (_migrationWalletAddress != null &&
        TransactionDetailsParser.isWalletInTransaction(tx, _migrationWalletAddress!)) {
      return true;
    }
    if (_migrationLegacyAta != null &&
        TransactionDetailsParser.isMigrationLegacyTransaction(tx, _migrationLegacyAta!)) {
      return true;
    }
    return false;
  }

  /// If [tx] has a signature not in [signatures], adds it and returns true. Otherwise false. Used for dedup.
  bool _trackIfNewSignature(TransactionDetails? tx, Set<String> signatures) {
    final String? sig = _getTxSignature(tx);
    if (sig == null) return true;
    if (signatures.contains(sig)) return false;
    signatures.add(sig);
    return true;
  }

  /// Loads ZARP and SOL balances from cache only; falls back to refresh on failure.
  Future<void> loadCachedBalances() async {
    if (tokenAccount == null || wallet == null) return;

    try {
      await _loadBalances(
        () => _balanceCacheService.getBothBalances(
          zarpAddress: tokenAccount!.pubkey,
          solAddress: wallet!.address,
          forceRefresh: false,
        ),
      );
    } catch (_) {
      await refreshBalances();
    }
  }

  /// Refreshes ZARP and SOL balances from the network.
  Future<void> refreshBalances() async {
    if (tokenAccount == null || wallet == null) return;

    await _loadBalances(
      () => _balanceCacheService.refreshBalances(
        zarpAddress: tokenAccount!.pubkey,
        solAddress: wallet!.address,
      ),
    );
  }

  /// Forces a full network refresh of ZARP and SOL balances.
  Future<void> forceRefreshBalances() async {
    if (tokenAccount == null || wallet == null) return;

    await _loadBalances(
      () => _balanceCacheService.getBothBalances(
        zarpAddress: tokenAccount!.pubkey,
        solAddress: wallet!.address,
        forceRefresh: true,
      ),
    );
  }

  /// Runs [loader] and updates [walletAmount], [solBalance], then notifies listeners.
  Future<void> _loadBalances(
    Future<({double solBalance, double zarpBalance})> Function() loader,
  ) async {
    final ({double solBalance, double zarpBalance}) balances = await loader();
    walletAmount = balances.zarpBalance;
    solBalance = balances.solBalance;
    notifyListeners();
  }

  /// Loads transactions from local storage, then optionally fetches newer and legacy history from the network.
  Future<void> loadTransactions() async {
    if (tokenAccount == null) {
      throw Exception('TokenAccount is null, cannot load transactions');
    }

    final Map<String, List<TransactionDetails?>> storedTransactions = await loadStoredTransactions();

    await _ensureUserLegacyAta();

    if (storedTransactions.isNotEmpty) {
      transactions = Map<String, List<TransactionDetails?>>.from(storedTransactions);

      _updateOldestSignature(storedTransactions);

      updateHasMoreTransactions();
      isLoadingTransactions = false;
      notifyListeners();

      if (!isRefreshing && transactions.isNotEmpty) return;
    }

    _walletRepository.resetCancellation();

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

      if (_userLegacyAta != null) {
        try {
          await _walletRepository.getNewerTransactions(
            walletAddress: _userLegacyAta!.pubkey,
            lastKnownSignature: null,
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
        } catch (_) {}
      }
    }
  }

  /// Reads transactions from local storage, applies system filters and dedup, then returns the filtered map.
  Future<Map<String, List<TransactionDetails?>>> loadStoredTransactions() async {
    if (tokenAccount == null) {
      return <String, List<TransactionDetails?>>{};
    }

    final Map<String, List<TransactionDetails?>> storedTransactions = await _walletRepository.getStoredTransactions(
      walletAddress: tokenAccount!.pubkey,
    );

    await _ensureMigrationLegacyAta();

    final Map<String, List<TransactionDetails?>> filteredTransactions = <String, List<TransactionDetails?>>{};

    final Set<String> seenSignatures = <String>{};

    int originalCount = 0;
    for (final String monthKey in storedTransactions.keys) {
      final List<TransactionDetails?> filteredTxs = <TransactionDetails?>[];
      for (final TransactionDetails? tx in storedTransactions[monthKey]!) {
        originalCount++;
        if (tx == null) continue;

        if (_shouldHideSystemTransaction(tx)) continue;
        if (!_trackIfNewSignature(tx, seenSignatures)) {
          continue;
        }

        filteredTxs.add(tx);
      }

      if (filteredTxs.isNotEmpty) {
        filteredTransactions[monthKey] = filteredTxs;
      }
    }

    final int filteredCount = filteredTransactions.values.fold<int>(
      0,
      (int sum, List<TransactionDetails?> list) => sum + list.length,
    );
    if (filteredCount < originalCount) {
      await _walletRepository.storeTransactions(
        filteredTransactions,
        walletAddress: tokenAccount!.pubkey,
      );
    }

    transactions = Map<String, List<TransactionDetails?>>.from(filteredTransactions);
    notifyListeners();

    return filteredTransactions;
  }

  /// Triggers the pull-to-refresh indicator and thus [refreshTransactions].
  Future<void> refreshTransactionsFromButton() async {
    unawaited(refreshIndicatorKey?.currentState?.show());
  }

  /// Refreshes balances and transactions (used by RefreshIndicator and by the one-time background refresh).
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

  /// Parses sender/recipient/amount for [transaction], trying new ZARP ATA first then legacy ATA.
  TransactionTransferInfo? parseTransferDetails(
    TransactionDetails? transaction,
  ) {
    if (transaction == null) return null;

    TransactionTransferInfo? info;

    if (tokenAccount != null) {
      info = _walletRepository.parseTransferDetails(
        transaction,
        tokenAccount!.pubkey,
      );
    }

    if (info == null && _userLegacyAta != null) {
      info = _walletRepository.parseTransferDetails(
        transaction,
        _userLegacyAta!.pubkey,
      );
    }

    return info;
  }

  /// Builds the list for the transaction list UI: month headers and items, limited by [_visibleOldestMonth].
  List<dynamic> getSortedTransactionItems() {
    final List<dynamic> transactionItems = <dynamic>[];

    if (_visibleOldestMonth == null && transactions.isNotEmpty) {
      final DateTime now = DateTime.now();
      final String currentMonthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final List<String> monthKeys = transactions.keys.toList()
        ..sort((String a, String b) => b.compareTo(a)); // newest first

      if (monthKeys.contains(currentMonthKey)) {
        _visibleOldestMonth = currentMonthKey;
      } else {
        _visibleOldestMonth = monthKeys.first;
      }
    }

    final List<String> sortedMonths = transactions.keys.toList()..sort((String a, String b) => b.compareTo(a));

    for (final String monthKey in sortedMonths) {
      if (_visibleOldestMonth != null && monthKey.compareTo(_visibleOldestMonth!) < 0) {
        continue;
      }

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

  /// Fetches older transactions from the network, then reveals one more month in the list.
  Future<void> loadMoreTransactions() async {
    if (tokenAccount == null || isLoadingMore || !hasMoreTransactionsToLoad) {
      return;
    }

    _walletRepository.resetCancellation();

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

      _expandVisibleMonthsByOne();

      notifyListeners();
    }
  }

  /// Updates [loadedTransactions] and [hasMoreTransactionsToLoad] (including when older months are still hidden).
  void updateHasMoreTransactions() {
    int loadedCount = 0;
    for (final List<TransactionDetails?> txList in transactions.values) {
      loadedCount += txList.where((TransactionDetails? tx) => tx != null).length;
    }

    loadedTransactions = loadedCount;
    hasMoreTransactionsToLoad = loadedTransactions < totalSignatures;

    if (!hasMoreTransactionsToLoad && _visibleOldestMonth != null && transactions.isNotEmpty) {
      final String globalOldest = _getGlobalOldestMonthKey();
      if (globalOldest.compareTo(_visibleOldestMonth!) < 0) {
        hasMoreTransactionsToLoad = true;
      }
    }

    notifyListeners();
  }

  /// Oldest month key (YYYY-MM) present in [transactions], or empty string if none.
  String _getGlobalOldestMonthKey() {
    if (transactions.isEmpty) return '';
    final List<String> keys = transactions.keys.toList()..sort();
    return keys.first;
  }

  /// Reveals one older month in the list; on first call sets [_visibleOldestMonth] to current/newest month.
  void _expandVisibleMonthsByOne() {
    if (transactions.isEmpty) return;

    if (_visibleOldestMonth == null) {
      final DateTime now = DateTime.now();
      final String currentMonthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final List<String> monthKeys = transactions.keys.toList()
        ..sort((String a, String b) => b.compareTo(a)); // newest first

      if (monthKeys.contains(currentMonthKey)) {
        _visibleOldestMonth = currentMonthKey;
      } else {
        _visibleOldestMonth = monthKeys.first;
      }
      return;
    }

    final List<String> sorted = transactions.keys.toList()..sort();
    final int currentIndex = sorted.indexOf(_visibleOldestMonth!);
    if (currentIndex <= 0) {
      _visibleOldestMonth = sorted.first;
      return;
    }
    _visibleOldestMonth = sorted[currentIndex - 1];
  }

  /// Fetches total transaction count from the network and updates [totalSignatures]; uses stored count on failure.
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

  /// Filters and deduplicates [batch], merges into [storedTransactions] by month, then persists to storage.
  Future<void> _processNewTransactionBatch(
    List<TransactionDetails?> batch,
    Map<String, List<TransactionDetails?>> storedTransactions, {
    bool isOlderTransactions = false,
  }) async {
    await _ensureMigrationLegacyAta();

    final Set<String> existingSignatures = <String>{};
    for (final List<TransactionDetails?> monthList in storedTransactions.values) {
      for (final TransactionDetails? existingTx in monthList) {
        _trackIfNewSignature(existingTx, existingSignatures);
      }
    }

    for (final TransactionDetails? tx in batch) {
      if (tx == null) continue;

      if (_shouldHideSystemTransaction(tx)) continue;
      if (!_trackIfNewSignature(tx, existingSignatures)) {
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

  /// Recomputes [oldestLoadedSignature] from [transactions] (e.g. after external updates).
  void updateOldestSignature() {
    if (transactions.isNotEmpty) {
      _updateOldestSignature(transactions);
    }
  }

  /// Sets [oldestLoadedSignature] to the signature of the chronologically oldest tx in [storedTransactions].
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

  /// Cancels in-flight transaction fetches.
  void cancelOperations() {
    _walletRepository.cancelTransactions();
  }

  /// Starts periodic checks of the legacy ZARP account (every 30s) and drains if needed.
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

  /// Stops the legacy-account monitoring timer.
  void stopLegacyMonitoring() {
    _legacyMonitorTimer?.cancel();
    _legacyMonitorTimer = null;
    _isMonitoringLegacy = false;
  }

  /// Checks legacy ZARP balance and runs migration drain if needed; reloads transactions when a drain occurs.
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
        await loadTransactions();
      }
    } catch (e) {
      if (!_disposed) {
        debugPrint('[WalletVM] Legacy balance check failed: $e');
      }
      // Don't fail if check fails
    }
  }

  /// One-time legacy check on app start, then starts [startLegacyMonitoring].
  Future<void> checkLegacyMigrationIfNeeded() async {
    if (wallet == null || _disposed) return;

    try {
      await checkLegacyBalance();
      if (_disposed) return;
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
