import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:solana/dto.dart';

class TransactionDetailsParser {
  static TransactionTransferInfo? parseTransferDetails(
    TransactionDetails transaction,
  ) {
    try {
      final Map<String, dynamic> message =
          transaction.transaction.toJson()['message'];
      debugPrint('message: $message');
      final List<dynamic> accountKeys = message['accountKeys'];

      final String recipient = accountKeys[2];
      final double amount = double.parse(
            transaction
                    .meta?.postTokenBalances[0].uiTokenAmount.uiAmountString ??
                '0',
          ) -
          double.parse(
            transaction
                    .meta?.preTokenBalances[0].uiTokenAmount.uiAmountString ??
                '0',
          );
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
  final String sign = amount >= 0 ? '+' : '-';
  final double absoluteAmount = amount.abs();
  return '${sign}R${absoluteAmount.toStringAsFixed(2)}';
}
