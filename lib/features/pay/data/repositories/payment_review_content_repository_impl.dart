import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/services/balance_cache_service.dart';
import '../../../../core/services/transaction_storage_service.dart';
import '../../../wallet/data/services/wallet_solana_service.dart';
import '../../domain/repositories/payment_review_content_repository.dart';

class PaymentReviewContentRepositoryImpl implements PaymentReviewContentRepository {
  PaymentReviewContentRepositoryImpl({
    WalletSolanaService? walletSolanaService,
    TransactionStorageService? transactionStorageService,
  }) : _walletSolanaService = walletSolanaService,
       _transactionStorageService = transactionStorageService ?? TransactionStorageService();
  final WalletSolanaService? _walletSolanaService;
  final TransactionStorageService _transactionStorageService;
  final BalanceCacheService _balanceCacheService = BalanceCacheService();

  Future<WalletSolanaService> get _service async {
    return _walletSolanaService ?? await WalletSolanaService.create();
  }

  @override
  Future<String> makeTransaction({
    required Wallet wallet,
    required ProgramAccount? senderTokenAccount,
    required ProgramAccount? recipientTokenAccount,
    required double amount,
  }) async {
    final WalletSolanaService service = await _service;
    return await service.sendTransaction(
      senderWallet: wallet,
      senderTokenAccount: senderTokenAccount,
      recipientTokenAccount: recipientTokenAccount,
      zarpAmount: amount,
    );
  }

  @override
  Future<TransactionDetails?> getTransactionDetails(String transactionSignature) async {
    final WalletSolanaService service = await _service;
    return await service.getTransactionDetails(transactionSignature);
  }

  @override
  Future<void> storeTransactionDetails(
    TransactionDetails transactionDetails, {
    required String walletAddress,
  }) async {
    await _transactionStorageService.mergeAndStoreTransactions(
      <TransactionDetails>[transactionDetails],
      walletAddress: walletAddress,
    );
  }

  @override
  Future<double> getZarpBalance(String publicKey) async {
    return await _balanceCacheService.getZarpBalance(publicKey);
  }

  @override
  Future<void> updateZarpBalance(double newBalance) async {
    await _balanceCacheService.updateZarpBalance(newBalance);
  }
}
