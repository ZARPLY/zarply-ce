import 'package:solana/dto.dart';

import '../../../../core/services/transaction_parser_service.dart';

abstract class WalletRepository {
  /// Get ZARP token balance for a given address
  Future<double> getZarpBalance(String address);

  /// Get SOL balance for a given address
  Future<double> getSolBalance(String address);

  /// Get transactions for a wallet account
  Future<Map<String, List<TransactionDetails?>>> getAccountTransactions({
    required String walletAddress,
    int limit = 100,
    String? afterSignature,
    String? beforeSignature,
    Function(List<TransactionDetails?>)? onBatchLoaded,
  });

  /// Store transactions in local storage
  Future<void> storeTransactions(
    Map<String, List<TransactionDetails?>> transactions,
  );

  /// Get stored transactions from local storage
  Future<Map<String, List<TransactionDetails?>>> getStoredTransactions();

  /// Get the signature of the last transaction
  Future<String?> getLastTransactionSignature();

  /// Parse transfer details from a transaction
  TransactionTransferInfo? parseTransferDetails(
    TransactionDetails? transaction,
    String accountPubkey,
  );

  /// Get the total transaction count for a token address
  Future<int> getTransactionCount(String tokenAddress);

  /// Store the transaction count locally
  Future<void> storeTransactionCount(int count);

  /// Retrieve the stored transaction count
  Future<int?> getStoredTransactionCount();
}
