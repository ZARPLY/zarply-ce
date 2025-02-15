import 'package:flutter/material.dart';
import '../../services/transaction_parser_service.dart';
import '../../utils/formatters.dart';

class ActivityItem extends StatelessWidget {
  const ActivityItem({required this.transferInfo, super.key});
  final TransactionTransferInfo transferInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      color: transferInfo.formattedAmount.startsWith('-')
                          ? const Color(0xFFFF6B6B)
                          : const Color(0xFF66BB6A),
                    ),
              ),
              Text(
                Formatters.shortenAddress(transferInfo.recipient),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          Image.asset(
            transferInfo.formattedAmount.startsWith('-')
                ? 'images/payed.png'
                : 'images/received.png',
            width: 40,
            height: 40,
          ),
        ],
      ),
    );
  }
}
