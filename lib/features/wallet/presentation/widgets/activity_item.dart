import 'package:flutter/material.dart';
import '../../../../core/services/transaction_parser_service.dart';
import '../../../../core/utils/formatters.dart';

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
                          ? Colors.black
                          : Colors.blue,
                    ),
              ),
              Text(
                transferInfo.formattedAmount.startsWith('-')
                    ? Formatters.shortenAddress(transferInfo.recipient)
                    : Formatters.shortenAddress(transferInfo.sender),
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
