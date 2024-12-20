import 'package:flutter/material.dart';
import '../services/transaction_parser_service.dart';
import '../utils/formatters.dart';

class ActivityItem extends StatelessWidget {
  const ActivityItem({required this.transferInfo, super.key});
  final TransactionTransferInfo transferInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 218, 218, 218),
        borderRadius: BorderRadius.circular(16),
      ),
      width: 350,
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    Formatters.formatDateTime(transferInfo.timestamp!),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    transferInfo.formattedAmount,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    Formatters.shortenAddress(transferInfo.recipient),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 99, 110, 128),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.send,
                color: Color.fromARGB(255, 99, 110, 128),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
