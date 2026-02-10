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
    Function(List<TransactionDetails?>)? onBatchLoaded,
  }) async {
    final WalletSolanaService service = await _service;
    return service.getAccountTransactions(
      walletAddress: walletAddress,
      until: lastKnownSignature,
      onBatchLoaded: (List<TransactionDetails?> batch) {
        if (_isCancelled) return;
        if (onBatchLoaded != null) onBatchLoaded(batch);
      },
      isCancelled: () => _isCancelled,
    );
  }

  @override
  Future<Map<String, List<TransactionDetails?>>> getOlderTransactions({
    required String walletAddress,
    required String oldestSignature,
    Function(List<TransactionDetails?>)? onBatchLoaded,
  }) async {
    final WalletSolanaService service = await _service;
    return service.getAccountTransactions(
      walletAddress: walletAddress,
      before: oldestSignature,
      limit: 20,
      onBatchLoaded: (List<TransactionDetails?> batch) {
        if (_isCancelled) return;
        if (onBatchLoaded != null) onBatchLoaded(batch);
      },
      isCancelled: () => _isCancelled,
    );
  }

  @override
  Future<void> storeTransactions(
    Map<String, List<TransactionDetails?>> transactions, {
    required String walletAddress,
  }) {
    if (_isCancelled) {
      return Future<void>.value();
    }
    return _transactionStorageService.storeTransactions(
      transactions,
      walletAddress: walletAddress,
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
  Future<String?> getLastTransactionSignature({required String walletAddress}) {
    return _transactionStorageService.getLastTransactionSignature(
      walletAddress: walletAddress,
    );
  }

  @override
  Future<void> storeLastTransactionSignature(String signature, {required String walletAddress}) {
    return _transactionStorageService.storeLastTransactionSignature(
      signature,
      walletAddress: walletAddress,
    );
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
