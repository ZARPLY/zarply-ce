import 'dart:developer';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

class TransactionDetailsParser {
  static TransactionTransferInfo? parseTransferDetails(
    TransactionDetails transaction,
  ) {
    try {
      final Map<String, dynamic> message =
          transaction.transaction.toJson()['message'];
      final List<dynamic> accountKeys = message['accountKeys'];

      final String recipient = accountKeys.last;
      final int amount = (transaction.meta?.postBalances[0] ?? 0) -
          (transaction.meta?.preBalances[0] ?? 0);
      final DateTime? date = transaction.blockTime != null
          ? DateTime.fromMillisecondsSinceEpoch(transaction.blockTime! * 1000)
          : null;

      return TransactionTransferInfo(
        sender: 'myself',
        recipient: recipient,
        amount: amount / lamportsPerSol,
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

  String get formattedAmount => '${amount.toStringAsFixed(4)} SOL';
}
