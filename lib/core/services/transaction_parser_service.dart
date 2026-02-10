import 'dart:convert';
import 'dart:developer';

import 'package:solana/base58.dart';
import 'package:solana/dto.dart';

class TransactionDetailsParser {
  /// Extract memo from transaction if present
  static String? extractMemo(TransactionDetails transaction) {
    try {
      final Map<String, dynamic> message = transaction.transaction.toJson()['message'];
      final List<dynamic> instructions = (message['instructions'] as List<dynamic>?) ?? <dynamic>[];
      final List<dynamic> accountKeys = (message['accountKeys'] as List<dynamic>?) ?? <dynamic>[];

      // Memo program ID
      const String memoProgramId = 'MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr';

      for (final dynamic instruction in instructions) {
        if (instruction is Map<String, dynamic>) {
          final int? programIdIndex = instruction['programIdIndex'] as int?;
          if (programIdIndex != null && programIdIndex < accountKeys.length) {
            final String programId = accountKeys[programIdIndex].toString();
            if (programId == memoProgramId) {
              // Extract memo data
              final dynamic data = instruction['data'];
              if (data != null) {
                try {
                  String memoData;
                  if (data is String) {
                    // Try to decode base58 if it's a string
                    try {
                      final List<int> decoded = base58decode(data);
                      memoData = utf8.decode(decoded);
                    } catch (e) {
                      // If base58 decode fails, use as-is
                      memoData = data;
                    }
                  } else if (data is List) {
                    // If data is already a list of bytes, decode directly
                    memoData = utf8.decode(data.cast<int>());
                  } else {
                    memoData = data.toString();
                  }
                  return memoData;
                } catch (e) {
                  // If decoding fails, return null
                  return null;
                }
              }
            }
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static TransactionTransferInfo? parseTransferDetails(
    TransactionDetails transaction,
    String accountOwner,
  ) {
    try {
      if (transaction.meta!.preTokenBalances.isEmpty && transaction.meta!.postTokenBalances.isEmpty) {
        return null;
      }

      final Map<String, dynamic> message = transaction.transaction.toJson()['message'];
      final List<dynamic> accountKeys = message['accountKeys'];

      int userTokenAccountIndex = -1;
      double preBalance = 0;
      double postBalance = 0;

      for (int i = 0; i < accountKeys.length; i++) {
        if (accountKeys[i] == accountOwner) {
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

      String otherParty = '';
      for (final TokenBalance tokenBalance in transaction.meta!.postTokenBalances) {
        if (tokenBalance.accountIndex != userTokenAccountIndex) {
          otherParty = accountKeys[tokenBalance.accountIndex];
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
        sender: isRecipient ? otherParty : 'myself',
        recipient: isRecipient ? 'myself' : otherParty,
        amount: amount,
        timestamp: date,
        isExternalFunding: isExternalFunding,
      );
    } catch (e) {
      log('Error parsing transaction details: $e');
      return null;
    }
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

  String get formattedAmount => formatAmount(amount);
}

String formatAmount(double amount) {
  final String sign = amount >= 0 ? '' : '-';
  final double absoluteAmount = amount.abs();
  return '${sign}R${absoluteAmount.toStringAsFixed(2)}';
}
