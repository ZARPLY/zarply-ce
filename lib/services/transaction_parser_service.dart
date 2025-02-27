import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:solana/dto.dart';

class TransactionDetailsParser {
  static TransactionTransferInfo? parseTransferDetails(
    TransactionDetails transaction,
    String accountOwner,
  ) {
    try {
      final Map<String, dynamic> message =
          transaction.transaction.toJson()['message'];
      final List<dynamic> accountKeys = message['accountKeys'];

      debugPrint('accountKeys: $accountKeys');
      debugPrint(
        'preTokenBalances[0]: ${transaction.meta!.preTokenBalances[0].uiTokenAmount.uiAmountString}',
      );
      debugPrint(
        'preTokenBalances[1]: ${transaction.meta!.preTokenBalances[1].uiTokenAmount.uiAmountString}',
      );
      debugPrint(
        'postTokenBalances[0]: ${transaction.meta!.postTokenBalances[0].uiTokenAmount.uiAmountString}',
      );
      debugPrint(
        'postTokenBalances[1]: ${transaction.meta!.postTokenBalances[1].uiTokenAmount.uiAmountString}',
      );
      double preBalance = 0;

      if (transaction.meta!.preTokenBalances.isNotEmpty) {
        preBalance = double.parse(
          transaction.meta!.preTokenBalances[0].uiTokenAmount.uiAmountString ??
              '0',
        );
      }

      double postBalance = 0;
      if (transaction.meta!.postTokenBalances.isNotEmpty) {
        postBalance = double.parse(
          transaction.meta!.postTokenBalances[0].uiTokenAmount.uiAmountString ??
              '0',
        );
      }

      final String recipient = accountKeys[2];

      final bool isRecipient = accountOwner == recipient;

      double amount = (postBalance - preBalance).abs();

      if (!isRecipient) {
        amount = -amount;
      }

      // initial funding if outside of ZARPLY
      if (accountKeys.length > 4) {
        if (transaction.meta!.postTokenBalances.isNotEmpty &&
            transaction.meta!.postTokenBalances.length > 1) {
          final double initialFunding = double.parse(
            transaction
                    .meta!.postTokenBalances[1].uiTokenAmount.uiAmountString ??
                '0',
          );
          debugPrint('initialFunding: $initialFunding');
          amount = initialFunding;
        }
      }

      final DateTime? date = transaction.blockTime != null
          ? DateTime.fromMillisecondsSinceEpoch(transaction.blockTime! * 1000)
          : null;

      return TransactionTransferInfo(
        sender: 'myself',
        recipient: recipient,
        amount: amount,
        timestamp: date,
      );
    } catch (e) {
      log('Error parsing transaction details: $e');
    }

    return null;
  }
}

class TransactionTransferInfo {
  TransactionTransferInfo({
    required this.sender,
    required this.recipient,
    required this.amount,
    this.timestamp,
  });
  final String sender;
  final String recipient;
  final double amount;
  final DateTime? timestamp;

  String get formattedAmount => formatAmount(amount);
}

String formatAmount(double amount) {
  final String sign = amount >= 0 ? '' : '-';
  final double absoluteAmount = amount.abs();
  return '${sign}R${absoluteAmount.toStringAsFixed(2)}';
}
