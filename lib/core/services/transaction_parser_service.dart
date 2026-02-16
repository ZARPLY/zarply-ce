import 'dart:developer';

import 'package:solana/dto.dart';

import '../utils/formatters.dart';

class TransactionDetailsParser {
  /// Returns [transaction].transaction as [ParsedTransaction], or parses via [ParsedTransaction.fromJson] when possible.
  static ParsedTransaction toParsedTransaction(Transaction transaction) {
    if (transaction is ParsedTransaction) return transaction;
    final dynamic json = transaction.toJson();
    return ParsedTransaction.fromJson(json);
  }

  /// Returns the first signature (transaction id) of [transactionDetails], or null if not a parsed transaction.
  static String? getFirstSignature(TransactionDetails transactionDetails) {
    final ParsedTransaction parsed = toParsedTransaction(transactionDetails.transaction);
    if (parsed.signatures.isEmpty) return null;
    return parsed.signatures.first;
  }

  static TransactionTransferInfo? parseTransferDetails(
    TransactionDetails transactionDertails,
    String accountOwner,
  ) {
    try {
      if (transactionDertails.meta!.preTokenBalances.isEmpty && transactionDertails.meta!.postTokenBalances.isEmpty) {
        return null;
      }

      final ParsedTransaction parsed = toParsedTransaction(transactionDertails.transaction);

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

      for (final TokenBalance tokenBalance in transactionDertails.meta!.preTokenBalances) {
        if (tokenBalance.accountIndex == userTokenAccountIndex) {
          preBalance = double.parse(
            tokenBalance.uiTokenAmount.uiAmountString ?? '0',
          );
          break;
        }
      }

      for (final TokenBalance tokenBalance in transactionDertails.meta!.postTokenBalances) {
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
      for (final TokenBalance tokenBalance in transactionDertails.meta!.postTokenBalances) {
        if (tokenBalance.accountIndex != userTokenAccountIndex) {
          final int otherTokenAccountKeyIndex = tokenBalance.accountIndex;
          if (otherTokenAccountKeyIndex >= 0 && otherTokenAccountKeyIndex < accountKeys.length) {
            otherTokenAccountPubkey = accountKeys[otherTokenAccountKeyIndex].pubkey;
          }
          break;
        }
      }

      bool isExternalFunding = false;
      if (accountKeys.length > 4 && isRecipient && transactionDertails.meta!.postTokenBalances.length > 1) {
        isExternalFunding = true;
      }

      final DateTime? date = transactionDertails.blockTime != null
          ? DateTime.fromMillisecondsSinceEpoch(transactionDertails.blockTime! * 1000)
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
    TransactionDetails transactionDetails,
    String migrationLegacyAta,
  ) {
    if (migrationLegacyAta.isEmpty) return false;
    final ParsedTransaction parsed = toParsedTransaction(transactionDetails.transaction);
    try {
      final List<AccountKey> accountKeys = parsed.message.accountKeys;

      final Set<int> tokenAccountIndices = <int>{};
      for (final TokenBalance balance in transactionDetails.meta!.preTokenBalances) {
        tokenAccountIndices.add(balance.accountIndex);
      }
      for (final TokenBalance balance in transactionDetails.meta!.postTokenBalances) {
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
    TransactionDetails transactionDetails,
    String walletAddress,
  ) {
    if (walletAddress.isEmpty) return false;
    final ParsedTransaction parsed = toParsedTransaction(transactionDetails.transaction);
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
