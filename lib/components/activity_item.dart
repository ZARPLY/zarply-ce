import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:zarply/services/transaction_parser_service.dart';

class ActivityItem extends StatelessWidget {
  final TransactionTransferInfo transferInfo;

  const ActivityItem({required this.transferInfo, super.key});

  // TODO: we can create a separate file for all utility methods and use it across the project
  // TODO: get rid of useless comments
  // Utility method to shorten wallet addresses
  String _shortenAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 5)}...${address.substring(address.length - 5)}';
  }

  // Utility method to format datetime
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd').format(dateTime);
  }

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
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _formatDateTime(transferInfo.timestamp!),
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
                children: [
                  Text(
                    transferInfo.formattedAmount,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    _shortenAddress(transferInfo.recipient),
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
            children: [
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
