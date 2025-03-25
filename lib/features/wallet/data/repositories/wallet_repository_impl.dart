import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/dto.dart';

import '../../../../core/services/transaction_parser_service.dart';
import '../../../../core/services/transaction_storage_service.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../services/wallet_solana_service.dart';

class WalletRepositoryImpl implements WalletRepository {
  factory WalletRepositoryImpl() => _instance;

  WalletRepositoryImpl._internal()
      : _walletSolanaService = WalletSolanaService(
          rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
          websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
        ),
        _transactionStorageService = TransactionStorageService();
  static final WalletRepositoryImpl _instance =
      WalletRepositoryImpl._internal();

  final WalletSolanaService _walletSolanaService;
  final TransactionStorageService _transactionStorageService;

  bool _isCancelled = false;

  void cancelTransactions() {
    _isCancelled = true;
  }

  void resetCancellation() {
    _isCancelled = false;
  }

  bool get isCancelled => _isCancelled;

  @override
  Future<double> getZarpBalance(String address) {
    return _walletSolanaService.getZarpBalance(address);
  }

  @override
  Future<double> getSolBalance(String address) {
    return _walletSolanaService.getSolBalance(address);
  }

  @override
  Future<Map<String, List<TransactionDetails?>>> getAccountTransactions({
    required String walletAddress,
    String? afterSignature,
    String? beforeSignature,
    Function(List<TransactionDetails?>)? onBatchLoaded,
    int limit = 100,
  }) {
    return _walletSolanaService.getAccountTransactions(
      walletAddress: walletAddress,
      afterSignature: afterSignature,
      beforeSignature: beforeSignature,
      onBatchLoaded: (List<TransactionDetails?> batch) {
        if (_isCancelled) {
          return;
        }
        if (onBatchLoaded != null) {
          onBatchLoaded(batch);
        }
      },
      isCancelled: () => _isCancelled,
      limit: limit,
    );
  }

  @override
  Future<void> storeTransactions(
    Map<String, List<TransactionDetails?>> transactions,
  ) {
    if (_isCancelled) {
      return Future<void>.value();
    }
    return _transactionStorageService.storeTransactions(transactions);
  }

  @override
  Future<Map<String, List<TransactionDetails?>>> getStoredTransactions() {
    return _transactionStorageService.getStoredTransactions();
  }

  @override
  Future<String?> getLastTransactionSignature() {
    return _transactionStorageService.getLastTransactionSignature();
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
  Future<int> getTransactionCount(String tokenAddress) {
    return _walletSolanaService.getTransactionCount(tokenAddress);
  }

  @override
  Future<void> storeTransactionCount(int count) {
    return _transactionStorageService.storeTransactionCount(count);
  }

  @override
  Future<int?> getStoredTransactionCount() {
    return _transactionStorageService.getStoredTransactionCount();
  }
}
