import 'package:solana/dto.dart';

import '../../../../core/services/transaction_parser_service.dart';

abstract class WalletRepository {
  /// Get ZARP token balance for a given address
  Future<double> getZarpBalance(String address);

  /// Get SOL balance for a given address
  Future<double> getSolBalance(String address);

  /// Get newer transactions for a wallet account
  Future<Map<String, List<TransactionDetails?>>> getNewerTransactions({
    required String walletAddress,
    String? lastKnownSignature,
    Function(List<TransactionDetails?>)? onBatchLoaded,
  });

  /// Get older transactions for a wallet account
  Future<Map<String, List<TransactionDetails?>>> getOlderTransactions({
    required String walletAddress,
    required String oldestSignature,
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

  /// Store the signature of the last transaction
  Future<void> storeLastTransactionSignature(String signature);

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

  /// Get associated token account from wallet address
  Future<ProgramAccount?> getAssociatedTokenAccount(String walletAddress);
}
