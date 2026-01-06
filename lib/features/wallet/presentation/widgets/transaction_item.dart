import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/transaction_parser_service.dart';
import '../../../../core/utils/formatters.dart';

class TransactionItem extends StatelessWidget {
  const TransactionItem({required this.transferInfo, super.key});
  final TransactionTransferInfo transferInfo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(
        '/transaction_details',
        extra: <String, String?>{
          'sender': transferInfo.sender,
          'receiver': transferInfo.recipient,
          'timestamp': transferInfo.timestamp?.toIso8601String(),
          'amount': transferInfo.amount.toString(),
        },
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F4),
          borderRadius: BorderRadius.circular(16),
        ),
        width: 350,
        height: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  transferInfo.formattedAmount,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: transferInfo.formattedAmount.startsWith('-') ? Colors.black : Colors.blue,
                  ),
                ),
                Text(
                  transferInfo.timestamp != null ? Formatters.formatDate(transferInfo.timestamp!) : 'Unknown',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            Image.asset(
              transferInfo.formattedAmount.startsWith('-') ? 'images/payed.png' : 'images/received.png',
              width: 40,
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}
