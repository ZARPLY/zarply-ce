import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

class TransactionDetailsParser {
  static TransactionTransferInfo? parseTransferDetails(
      TransactionDetails transaction) {
    try {
      final message = transaction.transaction.toJson()["message"];
      final accountKeys = message["accountKeys"];

      final recipient = accountKeys.last;
      final amount = (transaction.meta?.postBalances[0] ?? 0) -
          (transaction.meta?.preBalances[0] ?? 0);
      final date = transaction.blockTime != null
          ? DateTime.fromMillisecondsSinceEpoch(transaction.blockTime! * 1000)
          : null;

      return TransactionTransferInfo(
          sender: "myself",
          recipient: recipient,
          amount: amount / lamportsPerSol,
          timestamp: date);
    } catch (e) {
      print('Error parsing transaction details: $e');
    }

    return null;
  }
}

class TransactionTransferInfo {
  final String sender;
  final String recipient;
  final double amount;
  final DateTime? timestamp;

  TransactionTransferInfo({
    required this.sender,
    required this.recipient,
    required this.amount,
    this.timestamp,
  });

  String get formattedAmount => '${amount.toStringAsFixed(4)} SOL';
}
