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
  Future<TransactionDetails?> getTransactionDetails(String txSignature) async {
    final WalletSolanaService service = await _service;
    return await service.getTransactionDetails(txSignature);
  }

  @override
  Future<void> storeTransactionDetails(
    TransactionDetails txDetails, {
    required String walletAddress,
  }) async {
    final Map<String, List<TransactionDetails?>> stored = await _transactionStorageService.getStoredTransactions(
      walletAddress: walletAddress,
    );

    final DateTime txDate = DateTime.fromMillisecondsSinceEpoch(
      txDetails.blockTime! * 1000,
    );
    final String monthKey = '${txDate.year}-${txDate.month.toString().padLeft(2, '0')}';

    if (!stored.containsKey(monthKey)) {
      stored[monthKey] = <TransactionDetails?>[];
    }
    stored[monthKey]!.insert(0, txDetails);

    await _transactionStorageService.storeTransactions(
      stored,
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
