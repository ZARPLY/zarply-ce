import 'dart:developer';
import 'package:solana/dto.dart';

class TransactionDetailsParser {
  static TransactionTransferInfo? parseTransferDetails(
    TransactionDetails transaction,
    String accountOwner,
  ) {
    try {
      if (transaction.meta!.preTokenBalances.isEmpty &&
          transaction.meta!.postTokenBalances.isEmpty) {
        return null;
      }

      final Map<String, dynamic> message =
          transaction.transaction.toJson()['message'];
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

      for (final TokenBalance tokenBalance
          in transaction.meta!.preTokenBalances) {
        if (tokenBalance.accountIndex == userTokenAccountIndex) {
          preBalance = double.parse(
            tokenBalance.uiTokenAmount.uiAmountString ?? '0',
          );
          break;
        }
      }

      for (final TokenBalance tokenBalance
          in transaction.meta!.postTokenBalances) {
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
      for (final TokenBalance tokenBalance
          in transaction.meta!.postTokenBalances) {
        if (tokenBalance.accountIndex != userTokenAccountIndex) {
          otherParty = accountKeys[tokenBalance.accountIndex];
          break;
        }
      }

      bool isExternalFunding = false;
      if (accountKeys.length > 4 &&
          isRecipient &&
          transaction.meta!.postTokenBalances.length > 1) {
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
