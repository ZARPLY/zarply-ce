import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/models/wallet_balances.dart';
import '../../../../core/services/balance_cache_service.dart';
import '../../../../core/services/transaction_parser_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import 'transaction_list_item.dart';

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
  Timer? _newerPollTimer;
  bool _isMonitoringLegacy = false;
  bool _newerPollInProgress = false;
  bool _disposed = false;

  ProgramAccount? tokenAccount;
  Wallet? wallet;
  double walletAmount = 0;
  double solBalance = 0;
  bool isExpanded = false;
  bool isRefreshing = false;
  bool isLoadingMore = false;

  Map<String, List<TransactionDetails?>> transactions = <String, List<TransactionDetails?>>{};

  bool hasMoreTransactionsToLoad = false;

  /// Oldest month (YYYY-MM) currently shown in the list; newer months are hidden until "Load more".
  String? _visibleOldestMonth;

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

  bool _shouldHideSystemTransaction(TransactionDetails transaction) {
    return (_migrationWalletAddress != null &&
            TransactionDetailsParser.isWalletInTransaction(transaction, _migrationWalletAddress!)) ||
        (_migrationLegacyAta != null &&
            TransactionDetailsParser.isMigrationLegacyTransaction(transaction, _migrationLegacyAta!));
  }

  /// Returns a copy of [merged] with system transactions removed and duplicates by signature dropped.
  Map<String, List<TransactionDetails?>> _filterSystemTransactionsFromMap(
    Map<String, List<TransactionDetails?>> merged,
  ) {
    final Map<String, List<TransactionDetails?>> result = <String, List<TransactionDetails?>>{};
    for (final MapEntry<String, List<TransactionDetails?>> entry in merged.entries) {
      final Set<String> seen = <String>{};
      final List<TransactionDetails?> filtered = <TransactionDetails?>[];
      for (final TransactionDetails? transaction in entry.value) {
        if (transaction == null || _shouldHideSystemTransaction(transaction)) continue;
        final String? sig = TransactionDetailsParser.getFirstSignature(transaction);
        if (sig == null || !seen.add(sig)) continue;
        filtered.add(transaction);
      }
      if (filtered.isNotEmpty) result[entry.key] = filtered;
    }
    return result;
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

  Future<void> _loadBalances(Future<WalletBalances> Function() loader) async {
    final WalletBalances balances = await loader();
    walletAmount = balances.zarpBalance;
    solBalance = balances.solBalance;
    notifyListeners();
  }

  /// Pushes [merged] to UI: filtered list, hasMore, notify.
  Future<void> _applyMergedToUi(Map<String, List<TransactionDetails?>> merged) async {
    transactions = Map<String, List<TransactionDetails?>>.from(_filterSystemTransactionsFromMap(merged));
    await updateHasMoreTransactions();
    notifyListeners();
  }

  /// Fetches first N main and first N legacy in parallel, merges and stores. Optionally notifies after main so UI updates early.
  Future<Map<String, List<TransactionDetails?>>> _fetchInitialMainAndLegacy({
    Future<void> Function(Map<String, List<TransactionDetails?>>)? onMainFetched,
  }) async {
    const int initialPageSize = 25;
    Map<String, List<TransactionDetails?>> merged = await _walletRepository.getStoredTransactions(
      walletAddress: tokenAccount!.pubkey,
    );

    final Future<List<TransactionDetails?>> mainFuture = _walletRepository.getFirstNTransactions(
      tokenAccount!.pubkey,
      initialPageSize,
      isCancelled: () => _walletRepository.isCancelled,
    );
    final Future<List<TransactionDetails?>> legacyFuture = _userLegacyAta != null
        ? _walletRepository.getFirstNTransactions(
            _userLegacyAta!.pubkey,
            initialPageSize,
            isCancelled: () => _walletRepository.isCancelled,
            isLegacy: true,
          )
        : Future<List<TransactionDetails?>>.value(<TransactionDetails?>[]);

    final List<List<TransactionDetails?>> results = await Future.wait(<Future<List<TransactionDetails?>>>[
      mainFuture,
      legacyFuture,
    ]);
    final List<TransactionDetails?> mainList = results[0];
    final List<TransactionDetails?> legacyList = results[1];
    if (_walletRepository.isCancelled) return merged;

    merged = await _mergeBatchIntoStoredAndStore(mainList, atFront: true);
    await _storeLastSignatureFromListIfNonEmpty(
      mainList,
      tokenAccount!.pubkey,
      isLegacy: false,
    );
    await onMainFetched?.call(merged);

    if (legacyList.isNotEmpty) {
      merged = await _mergeBatchIntoStoredAndStore(legacyList, atFront: true);
    }

    await _walletRepository.storeOldestLoadedSignatures(
      mainSignature: _oldestSignatureFromList(mainList),
      legacySignature: legacyList.isNotEmpty ? _oldestSignatureFromList(legacyList) : null,
    );
    return merged;
  }

  /// Flattens a month-grouped map to a single list, newest first.
  List<TransactionDetails?> _groupedMapToList(Map<String, List<TransactionDetails?>> grouped) {
    if (grouped.isEmpty) return <TransactionDetails?>[];
    final List<String> keys = grouped.keys.toList()..sort((String a, String b) => b.compareTo(a));
    final List<TransactionDetails?> result = <TransactionDetails?>[];
    for (final String key in keys) {
      result.addAll(grouped[key]!);
    }
    return result;
  }

  /// Fetches newer transactions for main and legacy in parallel, then merges once and updates UI.
  Future<void> _fetchNewerAndMergeParallel() async {
    if (tokenAccount == null) return;

    final List<Future<String?>> lastSigFutures = <Future<String?>>[
      _walletRepository.getLastTransactionSignature(
        walletAddress: tokenAccount!.pubkey,
        isLegacy: false,
      ),
      _userLegacyAta != null
          ? _walletRepository.getLastTransactionSignature(
              walletAddress: _userLegacyAta!.pubkey,
              isLegacy: true,
            )
          : Future<String?>.value(null),
    ];
    final List<String?> lastSigs = await Future.wait(lastSigFutures);
    final String? mainLastSig = lastSigs[0];
    final String? legacyLastSig = lastSigs[1];

    final Future<Map<String, List<TransactionDetails?>>> mainFuture = mainLastSig != null
        ? _walletRepository.getNewerTransactions(
            walletAddress: tokenAccount!.pubkey,
            lastKnownSignature: mainLastSig,
            onBatchLoaded: null,
            isLegacy: false,
          )
        : Future<Map<String, List<TransactionDetails?>>>.value(<String, List<TransactionDetails?>>{});
    final Future<Map<String, List<TransactionDetails?>>> legacyFuture =
        (legacyLastSig != null && _userLegacyAta != null)
        ? _walletRepository.getNewerTransactions(
            walletAddress: _userLegacyAta!.pubkey,
            lastKnownSignature: legacyLastSig,
            onBatchLoaded: null,
            isLegacy: true,
          )
        : Future<Map<String, List<TransactionDetails?>>>.value(<String, List<TransactionDetails?>>{});

    final List<Map<String, List<TransactionDetails?>>> results = await Future.wait(
      <Future<Map<String, List<TransactionDetails?>>>>[mainFuture, legacyFuture],
    );
    final Map<String, List<TransactionDetails?>> mainMap = results[0];
    final Map<String, List<TransactionDetails?>> legacyMap = results[1];

    final List<TransactionDetails?> mainList = _groupedMapToList(mainMap);
    final List<TransactionDetails?> legacyList = _groupedMapToList(legacyMap);
    if (mainList.isEmpty && legacyList.isEmpty) return;

    Map<String, List<TransactionDetails?>> stored = await _walletRepository.getStoredTransactions(
      walletAddress: tokenAccount!.pubkey,
    );
    stored = _mergeIntoMap(mainList, stored, atFront: true);
    stored = _mergeIntoMap(legacyList, stored, atFront: true);
    await _walletRepository.storeTransactions(stored, walletAddress: tokenAccount!.pubkey);

    await _storeLastSignatureFromListIfNonEmpty(
      mainList,
      tokenAccount!.pubkey,
      isLegacy: false,
    );
    if (_userLegacyAta != null) {
      await _storeLastSignatureFromListIfNonEmpty(
        legacyList,
        _userLegacyAta!.pubkey,
        isLegacy: true,
      );
    }
    await _applyMergedToUi(stored);
  }

  /// Loads transactions: show from storage first, then quick path (new transactions), then initial 10+10 or refresh as needed.
  Future<void> loadTransactions() async {
    if (tokenAccount == null) {
      throw Exception('TokenAccount is null, cannot load transactions');
    }

    await _ensureUserLegacyAta();
    await _ensureMigrationLegacyAta();

    Map<String, List<TransactionDetails?>> merged = await _walletRepository.getStoredTransactions(
      walletAddress: tokenAccount!.pubkey,
    );

    if (merged.isNotEmpty) {
      await _applyMergedToUi(merged);
      if (!isRefreshing) {
        final ({String? mainSignature, String? legacySignature}) cursors = await _walletRepository
            .getOldestLoadedSignatures();
        final bool hasMainCursor = cursors.mainSignature != null;
        final bool hasLegacyCursor = cursors.legacySignature != null;
        final bool canSkipFullFetch = _userLegacyAta == null ? hasMainCursor : (hasMainCursor && hasLegacyCursor);
        if (canSkipFullFetch) {
          _startNewerPollTimer();
          notifyListeners();
          return;
        }
      }
      notifyListeners();
    }

    _walletRepository.resetCancellation();

    try {
      await _fetchNewerAndMergeParallel();
      if (_walletRepository.isCancelled) {
        _startNewerPollTimer();
        notifyListeners();
        return;
      }

      final ({String? mainSignature, String? legacySignature}) cursors = await _walletRepository
          .getOldestLoadedSignatures();
      final int storedCount = merged.values.fold<int>(0, (int s, List<TransactionDetails?> list) => s + list.length);
      final bool needBackfill = storedCount < 10 && cursors.mainSignature == null && cursors.legacySignature == null;

      if (isRefreshing && !needBackfill) {
        merged = await _walletRepository.getStoredTransactions(walletAddress: tokenAccount!.pubkey);
        await _applyMergedToUi(merged);
      } else {
        merged = await _fetchInitialMainAndLegacy(
          onMainFetched: merged.isEmpty ? _applyMergedToUi : null,
        );
        await _applyMergedToUi(merged);
        hasMoreTransactionsToLoad = true;
      }
      _startNewerPollTimer();
      notifyListeners();
      await updateTransactionCount();
    } catch (e) {
      throw Exception('Error loading transactions: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Polls for newer transactions and refreshes balance every 2s so new payments appear quickly.
  void _startNewerPollTimer() {
    _newerPollTimer?.cancel();
    if (_disposed || tokenAccount == null) return;
    _newerPollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollNewerTransactions(),
    );
  }

  Future<void> _pollNewerTransactions() async {
    if (_disposed || tokenAccount == null || _newerPollInProgress) return;
    _newerPollInProgress = true;
    try {
      await _fetchNewerAndMergeParallel();
      if (!_disposed && tokenAccount != null && wallet != null) {
        await refreshBalances();
      }
    } catch (_) {
      // Ignore; next poll will retry.
    } finally {
      _newerPollInProgress = false;
    }
  }

  /// Gets stored transactions, merges [batch] in (with dedup), persists, and returns the merged map.
  Future<Map<String, List<TransactionDetails?>>> _mergeBatchIntoStoredAndStore(
    List<TransactionDetails?> batch, {
    bool atFront = true,
  }) async {
    if (tokenAccount == null) return <String, List<TransactionDetails?>>{};
    final Map<String, List<TransactionDetails?>> stored = await _walletRepository.getStoredTransactions(
      walletAddress: tokenAccount!.pubkey,
    );
    final Map<String, List<TransactionDetails?>> merged = _mergeIntoMap(batch, stored, atFront: atFront);
    await _walletRepository.storeTransactions(merged, walletAddress: tokenAccount!.pubkey);
    return merged;
  }

  /// If [list] has at least one transaction, stores its first signature for [walletAddress] (main or legacy).
  Future<void> _storeLastSignatureFromListIfNonEmpty(
    List<TransactionDetails?> list,
    String walletAddress, {
    bool isLegacy = false,
  }) async {
    if (list.isEmpty || list.first == null) return;
    final String? sig = TransactionDetailsParser.getFirstSignature(list.first!);
    if (sig != null) {
      await _walletRepository.storeLastTransactionSignature(
        sig,
        walletAddress: walletAddress,
        isLegacy: isLegacy,
      );
    }
  }

  /// Merges [transactions] into [merged]: dedup by signature, add by month. [atFront] = insert at start (new) or append (load more).
  /// System transaction filtering happens only at display time, not during merge (so we store all).
  Map<String, List<TransactionDetails?>> _mergeIntoMap(
    List<TransactionDetails?> transactions,
    Map<String, List<TransactionDetails?>> merged, {
    bool atFront = true,
  }) {
    final Set<String> existing = <String>{};
    for (final List<TransactionDetails?> list in merged.values) {
      for (final TransactionDetails? transaction in list) {
        final String? sig = transaction != null ? TransactionDetailsParser.getFirstSignature(transaction) : null;
        if (sig != null) existing.add(sig);
      }
    }
    final Map<String, List<TransactionDetails?>> result = Map<String, List<TransactionDetails?>>.from(merged);
    for (final TransactionDetails? transaction in transactions) {
      if (transaction == null) continue;
      final String? sig = TransactionDetailsParser.getFirstSignature(transaction);
      if (sig == null || existing.contains(sig)) continue;
      existing.add(sig);
      final String monthKey = Formatters.monthKeyFromDate(
        DateTime.fromMillisecondsSinceEpoch(transaction.blockTime! * 1000),
      );
      if (!result.containsKey(monthKey)) result[monthKey] = <TransactionDetails?>[];
      if (atFront) {
        result[monthKey]!.insert(0, transaction);
      } else {
        result[monthKey]!.add(transaction);
      }
    }
    return result;
  }

  String? _oldestSignatureFromList(List<TransactionDetails?> list) {
    TransactionDetails? oldestTransaction;
    for (final TransactionDetails? transaction in list) {
      if (transaction == null || transaction.blockTime == null) continue;
      if (oldestTransaction == null || transaction.blockTime! < oldestTransaction.blockTime!) {
        oldestTransaction = transaction;
      }
    }
    return oldestTransaction != null ? TransactionDetailsParser.getFirstSignature(oldestTransaction) : null;
  }

  String? _oldestSignatureFromMap(Map<String, List<TransactionDetails?>> map) {
    final List<TransactionDetails?> flat = <TransactionDetails?>[];
    for (final List<TransactionDetails?> list in map.values) {
      flat.addAll(list);
    }
    return _oldestSignatureFromList(flat);
  }

  /// Refreshes balances and transactions (e.g. from the refresh button).
  Future<void> refreshTransactionsFromButton() async {
    await refreshTransactions();
  }

  /// Refreshes balances and transactions.
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
  TransactionTransferInfo? parseTransferDetails(TransactionDetails? transaction) {
    if (transaction == null) return null;
    for (final ProgramAccount? account in <ProgramAccount?>[tokenAccount, _userLegacyAta]) {
      if (account == null) continue;
      final TransactionTransferInfo? info = _walletRepository.parseTransferDetails(transaction, account.pubkey);
      if (info != null) return info;
    }
    return null;
  }

  /// Builds the list for the transaction list UI: month headers and items, limited by [_visibleOldestMonth].
  List<TransactionListItem> getSortedTransactionItems() {
    final List<TransactionListItem> transactionItems = <TransactionListItem>[];
    final List<String> sortedMonths = transactions.keys.toList()..sort((String a, String b) => b.compareTo(a));

    if (_visibleOldestMonth == null && sortedMonths.isNotEmpty) {
      final String currentMonthKey = Formatters.monthKeyFromDate(DateTime.now());
      _visibleOldestMonth = sortedMonths.contains(currentMonthKey) ? currentMonthKey : sortedMonths.first;
    }

    for (final String monthKey in sortedMonths) {
      if (_visibleOldestMonth != null && monthKey.compareTo(_visibleOldestMonth!) < 0) continue;

      final List<TransactionDetails?> monthTransactions = transactions[monthKey]!;
      final int displayedCount = monthTransactions.where((TransactionDetails? transaction) {
        final TransactionTransferInfo? transferInfo = parseTransferDetails(transaction);
        return transferInfo != null && transferInfo.amount != 0;
      }).length;
      transactionItems.add(TransactionMonthHeader(monthKey: monthKey, displayedCount: displayedCount));

      final List<TransactionDetails?> sortedTransactions = List<TransactionDetails?>.from(monthTransactions)
        ..sort((TransactionDetails? a, TransactionDetails? b) {
          if (a == null || b == null) return 0;
          return (b.blockTime ?? 0).compareTo(a.blockTime ?? 0);
        });
      for (final TransactionDetails? transaction in sortedTransactions) {
        transactionItems.add(TransactionEntry(transaction));
      }
    }
    return transactionItems;
  }

  /// Fetches older transactions from main and legacy in one big grab and appends to the list.
  Future<void> loadMoreTransactions() async {
    if (tokenAccount == null || isLoadingMore || !hasMoreTransactionsToLoad) {
      return;
    }
    if (transactions.isEmpty) {
      hasMoreTransactionsToLoad = false;
      notifyListeners();
      return;
    }

    final ({String? mainSignature, String? legacySignature}) oldestSignatures = await _walletRepository
        .getOldestLoadedSignatures();
    if (oldestSignatures.mainSignature == null && oldestSignatures.legacySignature == null) {
      hasMoreTransactionsToLoad = false;
      notifyListeners();
      return;
    }

    isLoadingMore = true;
    notifyListeners();

    try {
      Map<String, List<TransactionDetails?>> merged = await _walletRepository.getStoredTransactions(
        walletAddress: tokenAccount!.pubkey,
      );

      const int loadMoreLimit = 100;
      bool hasMoreMain = false;
      bool hasMoreLegacy = false;
      String? currentOldestMain = oldestSignatures.mainSignature;
      String? currentOldestLegacy = oldestSignatures.legacySignature;

      final List<({String pubkey, String oldestSig, bool isMain})> toFetch =
          <({String pubkey, String oldestSig, bool isMain})>[];
      if (oldestSignatures.mainSignature != null) {
        toFetch.add((
          pubkey: tokenAccount!.pubkey,
          oldestSig: oldestSignatures.mainSignature!,
          isMain: true,
        ));
      }
      if (_userLegacyAta != null && oldestSignatures.legacySignature != null) {
        toFetch.add((
          pubkey: _userLegacyAta!.pubkey,
          oldestSig: oldestSignatures.legacySignature!,
          isMain: false,
        ));
      }
      for (final ({String pubkey, String oldestSig, bool isMain}) task in toFetch) {
        final ({Map<String, List<TransactionDetails?>> merged, String? currentOldest, bool hasMore}) result =
            await _fetchOlderForAccount(task.pubkey, task.oldestSig, merged, loadMoreLimit);
        merged = result.merged;
        if (task.isMain) {
          currentOldestMain = result.currentOldest;
          hasMoreMain = result.hasMore;
        } else {
          currentOldestLegacy = result.currentOldest;
          hasMoreLegacy = result.hasMore;
        }
      }

      await _walletRepository.storeOldestLoadedSignatures(
        mainSignature: currentOldestMain,
        legacySignature: currentOldestLegacy,
      );

      await _walletRepository.storeTransactions(
        merged,
        walletAddress: tokenAccount!.pubkey,
      );

      transactions = Map<String, List<TransactionDetails?>>.from(_filterSystemTransactionsFromMap(merged));
      await updateHasMoreTransactions();
      hasMoreTransactionsToLoad =
          hasMoreMain || hasMoreLegacy || (currentOldestMain != null || currentOldestLegacy != null);
    } catch (e) {
      throw Exception('Error loading more transactions: $e');
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Flattens month-keyed map to list (oldest month first, then by blockTime within month).
  List<TransactionDetails?> _flattenMapToList(
    Map<String, List<TransactionDetails?>> map,
  ) {
    final List<TransactionDetails?> result = <TransactionDetails?>[];
    final List<String> keys = map.keys.toList()..sort();
    for (final String key in keys) {
      result.addAll(map[key]!);
    }
    return result;
  }

  /// Fetches older transactions for one account (main or legacy), with one retry if empty. Returns merged map, new oldest signature, and whether more are available.
  Future<({Map<String, List<TransactionDetails?>> merged, String? currentOldest, bool hasMore})> _fetchOlderForAccount(
    String walletAddress,
    String oldestSignature,
    Map<String, List<TransactionDetails?>> merged,
    int loadMoreLimit,
  ) async {
    Map<String, List<TransactionDetails?>> older = await _walletRepository.getOlderTransactions(
      walletAddress: walletAddress,
      oldestSignature: oldestSignature,
      onBatchLoaded: null,
      limit: loadMoreLimit,
    );
    List<TransactionDetails?> flat = _flattenMapToList(older);
    if (flat.isEmpty) {
      await Future<void>.delayed(const Duration(seconds: 2));
      older = await _walletRepository.getOlderTransactions(
        walletAddress: walletAddress,
        oldestSignature: oldestSignature,
        onBatchLoaded: null,
        limit: loadMoreLimit,
      );
      flat = _flattenMapToList(older);
    }
    final bool hasMore = flat.length >= loadMoreLimit;
    final Map<String, List<TransactionDetails?>> newMerged = _mergeIntoMap(flat, merged, atFront: false);
    final String? currentOldest = flat.isNotEmpty ? (_oldestSignatureFromMap(older) ?? oldestSignature) : null;
    return (merged: newMerged, currentOldest: currentOldest, hasMore: hasMore);
  }

  /// Updates [hasMoreTransactionsToLoad].
  /// "Load more" is true when there are older months to reveal in the list OR we have RPC cursors (can fetch older history).
  Future<void> updateHasMoreTransactions() async {
    bool moreMonthsToReveal = false;
    if (transactions.isNotEmpty) {
      final String globalOldest = _getGlobalOldestMonthKey();
      if (_visibleOldestMonth == null) {
        moreMonthsToReveal = transactions.keys.length > 1;
      } else {
        moreMonthsToReveal = globalOldest.compareTo(_visibleOldestMonth!) < 0;
      }
    }

    final ({String? mainSignature, String? legacySignature}) cursors = await _walletRepository
        .getOldestLoadedSignatures();
    final bool canFetchMoreFromRpc = cursors.mainSignature != null || cursors.legacySignature != null;

    hasMoreTransactionsToLoad = moreMonthsToReveal || canFetchMoreFromRpc;
    notifyListeners();
  }

  /// Oldest month key (YYYY-MM) present in [transactions], or empty string if none.
  String _getGlobalOldestMonthKey() {
    if (transactions.isEmpty) return '';
    final List<String> keys = transactions.keys.toList()..sort();
    return keys.first;
  }

  /// Fetches total transaction count from the network and stores it; uses stored count on failure.
  Future<void> updateTransactionCount() async {
    if (tokenAccount == null) return;

    try {
      final int networkCount = await _walletRepository.getTransactionCount(tokenAccount!.pubkey);
      await _walletRepository.storeTransactionCount(networkCount);
      await updateHasMoreTransactions();
    } catch (e) {
      final int? storedCount = await _walletRepository.getStoredTransactionCount();
      if (storedCount != null) {
        await updateHasMoreTransactions();
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
      if (!_disposed) {}
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
      if (!_disposed) {}
      // Don't fail the app if migration check fails
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _newerPollTimer?.cancel();
    _newerPollTimer = null;
    stopLegacyMonitoring();
    cancelOperations();
    super.dispose();
  }
}
