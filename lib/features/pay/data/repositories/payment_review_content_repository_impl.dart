import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/services/transaction_storage_service.dart';
import '../../../wallet/data/services/wallet_solana_service.dart';
import '../../domain/repositories/payment_review_content_repository.dart';

class PaymentReviewContentRepositoryImpl
    implements PaymentReviewContentRepository {
  PaymentReviewContentRepositoryImpl({
    WalletSolanaService? walletSolanaService,
    TransactionStorageService? transactionStorageService,
  })  : _walletSolanaService = walletSolanaService ??
            WalletSolanaService(
              rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
              websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
            ),
        _transactionStorageService =
            transactionStorageService ?? TransactionStorageService();
  final WalletSolanaService _walletSolanaService;
  final TransactionStorageService _transactionStorageService;

  @override
  Future<String> makeTransaction({
    required Wallet wallet,
    required String recipientAddress,
    required double amount,
  }) async {
    if (recipientAddress.isEmpty) {
      throw Exception('Recipient address not found');
    }

    return await _walletSolanaService.sendTransaction(
      senderWallet: wallet,
      recipientAddress: recipientAddress,
      zarpAmount: amount / 100,
    );
  }

  @override
  Future<TransactionDetails?> getTransactionDetails(String txSignature) async {
    return await _walletSolanaService.getTransactionDetails(txSignature);
  }

  @override
  Future<void> storeTransactionDetails(TransactionDetails txDetails) async {
    final Map<String, List<TransactionDetails?>> stored =
        await _transactionStorageService.getStoredTransactions();

    final DateTime txDate = DateTime.fromMillisecondsSinceEpoch(
      txDetails.blockTime! * 1000,
    );
    final String monthKey =
        '${txDate.year}-${txDate.month.toString().padLeft(2, '0')}';

    if (!stored.containsKey(monthKey)) {
      stored[monthKey] = <TransactionDetails?>[];
    }
    stored[monthKey]!.insert(0, txDetails);

    await _transactionStorageService.storeTransactions(stored);
  }
}
