import 'dart:developer';

import 'package:solana/dto.dart';

import '../utils/formatters.dart';

class TransactionDetailsParser {
  /// Returns [transaction].transaction as [ParsedTransaction], or parses via [ParsedTransaction.fromJson] when possible.
  static ParsedTransaction? asParsedTransaction(Transaction transaction) {
    if (transaction is ParsedTransaction) return transaction;
    try {
      final Object? json = transaction.toJson();
      if (json is Map) {
        return ParsedTransaction.fromJson(Map<String, dynamic>.from(json));
      }
    } catch (_) {
      // Raw or unsupported format
    }
    return null;
  }

  /// Returns the first signature (transaction id) of [details], or null if not a parsed transaction.
  static String? getFirstSignature(TransactionDetails details) {
    final ParsedTransaction? parsed = asParsedTransaction(details.transaction);
    if (parsed == null || parsed.signatures.isEmpty) return null;
    return parsed.signatures.first;
  }

  static TransactionTransferInfo? parseTransferDetails(
    TransactionDetails transaction,
    String accountOwner,
  ) {
    try {
      if (transaction.meta!.preTokenBalances.isEmpty && transaction.meta!.postTokenBalances.isEmpty) {
        return null;
      }

      final ParsedTransaction? parsed = asParsedTransaction(transaction.transaction);
      if (parsed == null) return null;

      final List<AccountKey> accountKeys = parsed.message.accountKeys;
      int userTokenAccountIndex = -1;
      double preBalance = 0;
      double postBalance = 0;

      for (int i = 0; i < accountKeys.length; i++) {
        if (accountKeys[i].pubkey == accountOwner) {
          userTokenAccountIndex = i;
          break;
        }
      }

      if (userTokenAccountIndex == -1) {
        return null;
      }

      for (final TokenBalance tokenBalance in transaction.meta!.preTokenBalances) {
        if (tokenBalance.accountIndex == userTokenAccountIndex) {
          preBalance = double.parse(
            tokenBalance.uiTokenAmount.uiAmountString ?? '0',
          );
          break;
        }
      }

      for (final TokenBalance tokenBalance in transaction.meta!.postTokenBalances) {
        if (tokenBalance.accountIndex == userTokenAccountIndex) {
          postBalance = double.parse(
            tokenBalance.uiTokenAmount.uiAmountString ?? '0',
          );
          break;
        }
      }

      final double amount = postBalance - preBalance;
      final bool isRecipient = amount > 0;

      String otherTokenAccountPubkey = '';
      for (final TokenBalance tokenBalance in transaction.meta!.postTokenBalances) {
        if (tokenBalance.accountIndex != userTokenAccountIndex) {
          final int otherTokenAccountKeyIndex = tokenBalance.accountIndex;
          if (otherTokenAccountKeyIndex >= 0 && otherTokenAccountKeyIndex < accountKeys.length) {
            otherTokenAccountPubkey = accountKeys[otherTokenAccountKeyIndex].pubkey;
          }
          break;
        }
      }

      bool isExternalFunding = false;
      if (accountKeys.length > 4 && isRecipient && transaction.meta!.postTokenBalances.length > 1) {
        isExternalFunding = true;
      }

      final DateTime? date = transaction.blockTime != null
          ? DateTime.fromMillisecondsSinceEpoch(transaction.blockTime! * 1000)
          : null;

      return TransactionTransferInfo(
        sender: isRecipient ? otherTokenAccountPubkey : 'myself',
        recipient: isRecipient ? 'myself' : otherTokenAccountPubkey,
        amount: amount,
        timestamp: date,
        isExternalFunding: isExternalFunding,
      );
    } catch (e) {
      log('Error parsing transaction details: $e');
      return null;
    }
  }

  /// Returns true if the transaction involves the migration legacy ATA

  static bool isMigrationLegacyTransaction(
    TransactionDetails transaction,
    String migrationLegacyAta,
  ) {
    if (migrationLegacyAta.isEmpty) return false;
    final ParsedTransaction? parsed = asParsedTransaction(transaction.transaction);
    if (parsed == null) return false;
    try {
      final List<AccountKey> accountKeys = parsed.message.accountKeys;

      final Set<int> tokenAccountIndices = <int>{};
      for (final TokenBalance balance in transaction.meta!.preTokenBalances) {
        tokenAccountIndices.add(balance.accountIndex);
      }
      for (final TokenBalance balance in transaction.meta!.postTokenBalances) {
        tokenAccountIndices.add(balance.accountIndex);
      }

      for (final int index in tokenAccountIndices) {
        if (index >= 0 && index < accountKeys.length) {
          if (accountKeys[index].pubkey == migrationLegacyAta) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Returns true if the given wallet address appears in the transaction's account keys.
  /// Used to hide any transactions that involve the migration/faucet wallet
  static bool isWalletInTransaction(
    TransactionDetails transaction,
    String walletAddress,
  ) {
    if (walletAddress.isEmpty) return false;
    final ParsedTransaction? parsed = asParsedTransaction(transaction.transaction);
    if (parsed == null) return false;
    for (final AccountKey key in parsed.message.accountKeys) {
      if (key.pubkey == walletAddress) return true;
    }
    return false;
  }
}

class TransactionTransferInfo {
  TransactionTransferInfo({
    required this.sender,
    required this.recipient,
    required this.amount,
    this.timestamp,
    this.isExternalFunding = false,
  });
  final String sender;
  final String recipient;
  final double amount;
  final DateTime? timestamp;
  final bool isExternalFunding;

  String get formattedAmount => Formatters.formatAmount(amount);
}
