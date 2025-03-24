import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/dto.dart';

import '../../../../core/services/transaction_parser_service.dart';
import '../../../../core/services/transaction_storage_service.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../services/wallet_solana_service.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletSolanaService _walletSolanaService = WalletSolanaService(
    rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
    websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
  );
  final TransactionStorageService _transactionStorageService =
      TransactionStorageService();

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
  }) {
    return _walletSolanaService.getAccountTransactions(
      walletAddress: walletAddress,
      afterSignature: afterSignature,
    );
  }

  @override
  Future<void> storeTransactions(
    Map<String, List<TransactionDetails?>> transactions,
  ) {
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
}
