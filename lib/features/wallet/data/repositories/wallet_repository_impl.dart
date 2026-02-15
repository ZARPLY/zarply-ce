import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/services/transaction_parser_service.dart';
import '../../../../core/services/transaction_storage_service.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../services/wallet_solana_service.dart';

class WalletRepositoryImpl implements WalletRepository {
  factory WalletRepositoryImpl() => _instance;

  WalletRepositoryImpl._internal() : _transactionStorageService = TransactionStorageService();
  static final WalletRepositoryImpl _instance = WalletRepositoryImpl._internal();

  WalletSolanaService? _walletSolanaService;
  final TransactionStorageService _transactionStorageService;

  Future<WalletSolanaService> get _service async {
    _walletSolanaService ??= await WalletSolanaService.create();
    return _walletSolanaService!;
  }

  bool _isCancelled = false;

  void cancelTransactions() {
    _isCancelled = true;
  }

  void resetCancellation() {
    _isCancelled = false;
  }

  bool get isCancelled => _isCancelled;

  Future<void> _onBatchLoaded(
    List<TransactionDetails?> batch,
    Future<void> Function(List<TransactionDetails?>)? onBatchLoaded,
  ) async {
    if (_isCancelled) return;
    if (onBatchLoaded != null) await onBatchLoaded(batch);
  }

  @override
  Future<double> getZarpBalance(String address) async {
    final WalletSolanaService service = await _service;
    return service.getZarpBalance(address);
  }

  @override
  Future<double> getSolBalance(String address) async {
    final WalletSolanaService service = await _service;
    return service.getSolBalance(address);
  }

  @override
  Future<Map<String, List<TransactionDetails?>>> getNewerTransactions({
    required String walletAddress,
    String? lastKnownSignature,
    Future<void> Function(List<TransactionDetails?>)? onBatchLoaded,
    bool isLegacy = false,
  }) async {
    final WalletSolanaService service = await _service;
    return service.getAccountTransactions(
      walletAddress: walletAddress,
      until: lastKnownSignature,
      onBatchLoaded: (List<TransactionDetails?> batch) => _onBatchLoaded(batch, onBatchLoaded),
      isCancelled: () => _isCancelled,
      isLegacy: isLegacy,
    );
  }

  @override
  Future<Map<String, List<TransactionDetails?>>> getOlderTransactions({
    required String walletAddress,
    required String oldestSignature,
    Future<void> Function(List<TransactionDetails?>)? onBatchLoaded,
    int limit = 100,
  }) async {
    final WalletSolanaService service = await _service;
    return service.getAccountTransactions(
      walletAddress: walletAddress,
      before: oldestSignature,
      limit: limit,
      onBatchLoaded: (List<TransactionDetails?> batch) => _onBatchLoaded(batch, onBatchLoaded),
      isCancelled: () => _isCancelled,
    );
  }

  /// Fetches the first [n] transactions for [walletAddress] and returns them
  /// as a single list, newest first. The underlying service returns transactions
  /// grouped by month; this method flattens and reorders by month so the
  /// combined list is chronological (most recent first).
  @override
  Future<List<TransactionDetails?>> getFirstNTransactions(
    String walletAddress,
    int n, {
    bool Function()? isCancelled,
    bool isLegacy = false,
  }) async {
    final WalletSolanaService service = await _service;
    final Map<String, List<TransactionDetails?>> grouped = await service.getAccountTransactions(
      walletAddress: walletAddress,
      limit: n,
      onBatchLoaded: null,
      isCancelled: isCancelled,
      isLegacy: isLegacy,
    );
    if (grouped.isEmpty) return <TransactionDetails?>[];
    // Month keys sort descending so we iterate newest months first.
    final List<String> monthKeys = grouped.keys.toList()..sort((String a, String b) => b.compareTo(a));
    final List<TransactionDetails?> result = <TransactionDetails?>[];
    for (final String key in monthKeys) {
      for (final TransactionDetails? transaction in grouped[key]!) {
        result.add(transaction);
      }
    }
    return result;
  }

  Future<void> _storeIfNotCancelled(Future<void> Function() action) {
    if (_isCancelled) return Future<void>.value();
    return action();
  }

  @override
  Future<void> storeTransactions(
    Map<String, List<TransactionDetails?>> transactions, {
    required String walletAddress,
  }) {
    return _storeIfNotCancelled(
      () => _transactionStorageService.storeTransactions(transactions, walletAddress: walletAddress),
    );
  }

  @override
  Future<void> mergeAndStoreTransactions(
    List<TransactionDetails?> newTransactions, {
    required String walletAddress,
  }) {
    return _storeIfNotCancelled(
      () => _transactionStorageService.mergeAndStoreTransactions(newTransactions, walletAddress: walletAddress),
    );
  }

  @override
  Future<Map<String, List<TransactionDetails?>>> getStoredTransactions({
    required String walletAddress,
  }) {
    return _transactionStorageService.getStoredTransactions(
      walletAddress: walletAddress,
    );
  }

  @override
  Future<String?> getLastTransactionSignature({
    required String walletAddress,
    bool isLegacy = false,
  }) {
    return _transactionStorageService.getLastTransactionSignature(
      walletAddress: walletAddress,
      isLegacy: isLegacy,
    );
  }

  @override
  Future<void> storeLastTransactionSignature(
    String signature, {
    required String walletAddress,
    bool isLegacy = false,
  }) {
    return _transactionStorageService.storeLastTransactionSignature(
      signature,
      walletAddress: walletAddress,
      isLegacy: isLegacy,
    );
  }

  @override
  Future<void> storeOldestLoadedSignatures({String? mainSignature, String? legacySignature}) {
    return _transactionStorageService.storeOldestLoadedSignatures(
      mainSignature: mainSignature,
      legacySignature: legacySignature,
    );
  }

  @override
  Future<({String? mainSignature, String? legacySignature})> getOldestLoadedSignatures() {
    return _transactionStorageService.getOldestLoadedSignatures();
  }

  @override
  TransactionTransferInfo? parseTransferDetails(
    TransactionDetails? transaction,
    String accountPubkey,
  ) {
    if (transaction == null) return null;

    return TransactionDetailsParser.parseTransferDetails(
      transaction,
      accountPubkey,
    );
  }

  @override
  Future<int> getTransactionCount(String tokenAddress) async {
    final WalletSolanaService service = await _service;
    return service.getTransactionCount(tokenAddress);
  }

  @override
  Future<void> storeTransactionCount(int count) {
    return _transactionStorageService.storeTransactionCount(count);
  }

  @override
  Future<int?> getStoredTransactionCount() {
    return _transactionStorageService.getStoredTransactionCount();
  }

  @override
  Future<ProgramAccount?> getAssociatedTokenAccount(
    String walletAddress,
  ) async {
    final WalletSolanaService service = await _service;
    return service.getAssociatedTokenAccount(walletAddress);
  }

  @override
  Future<
    ({
      bool hasLegacyAccount,
      bool needsMigration,
      bool migrationComplete,
      String? migrationSignature,
      int? migrationTimestamp,
    })
  >
  checkAndMigrateLegacyIfNeeded(Wallet wallet) async {
    final WalletSolanaService service = await _service;
    return service.checkAndMigrateLegacyIfNeeded(wallet);
  }

  @override
  Future<ProgramAccount?> getLegacyAssociatedTokenAccount(String walletAddress) async {
    final WalletSolanaService service = await _service;
    return service.getLegacyAssociatedTokenAccount(walletAddress);
  }
}
