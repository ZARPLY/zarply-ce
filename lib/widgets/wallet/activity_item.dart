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
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                Formatters.shortenAddress(transferInfo.recipient),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF9BA1AC),
              borderRadius: BorderRadius.circular(80),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.call_received,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
