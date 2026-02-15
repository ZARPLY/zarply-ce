import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/services/transaction_parser_service.dart';

abstract class WalletRepository {
  /// Get ZARP token balance for a given address
  Future<double> getZarpBalance(String address);

  /// Get SOL balance for a given address
  Future<double> getSolBalance(String address);

  /// Get newer transactions for a wallet account (main or legacy ATA).
  Future<Map<String, List<TransactionDetails?>>> getNewerTransactions({
    required String walletAddress,
    String? lastKnownSignature,
    Future<void> Function(List<TransactionDetails?>)? onBatchLoaded,
    bool isLegacy = false,
  });

  /// Get older transactions for a wallet account
  Future<Map<String, List<TransactionDetails?>>> getOlderTransactions({
    required String walletAddress,
    required String oldestSignature,
    Future<void> Function(List<TransactionDetails?>)? onBatchLoaded,
    int limit = 100,
  });

  /// Get the first [n] (newest) transactions for an account. Used for initial load.
  Future<List<TransactionDetails?>> getFirstNTransactions(
    String walletAddress,
    int n, {
    bool Function()? isCancelled,
    bool isLegacy = false,
  });

  /// Store transactions in local storage
  Future<void> storeTransactions(
    Map<String, List<TransactionDetails?>> transactions, {
    required String walletAddress,
  });

  /// Merge [newTransactions] into stored data (by month, at front) and persist.
  Future<void> mergeAndStoreTransactions(
    List<TransactionDetails?> newTransactions, {
    required String walletAddress,
  });

  /// Get stored transactions from local storage (single source of truth for display).
  Future<Map<String, List<TransactionDetails?>>> getStoredTransactions({
    required String walletAddress,
  });

  /// Get the signature of the last transaction (main or legacy account).
  Future<String?> getLastTransactionSignature({
    required String walletAddress,
    bool isLegacy = false,
  });

  /// Store the signature of the last transaction (main or legacy account).
  Future<void> storeLastTransactionSignature(
    String signature, {
    required String walletAddress,
    bool isLegacy = false,
  });

  /// Store oldest loaded signatures (per account) for load-more pagination.
  Future<void> storeOldestLoadedSignatures({String? mainSignature, String? legacySignature});

  /// Get stored oldest loaded signatures for main and legacy.
  Future<({String? mainSignature, String? legacySignature})> getOldestLoadedSignatures();

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

  /// Check and migrate legacy account if needed
  Future<
    ({
      bool hasLegacyAccount,
      bool needsMigration,
      bool migrationComplete,
      String? migrationSignature,
      int? migrationTimestamp,
    })
  >
  checkAndMigrateLegacyIfNeeded(Wallet wallet);

  /// Get legacy associated token account from wallet address
  Future<ProgramAccount?> getLegacyAssociatedTokenAccount(String walletAddress);
}
