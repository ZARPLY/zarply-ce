import 'package:flutter/material.dart';

class RecentTransactions extends StatelessWidget {
  const RecentTransactions({
    super.key,
    required this.transactions,
    required this.isLamport,
  });

  final List<Map<String, dynamic>> transactions;
  final bool isLamport;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: SizedBox(
            width: 600,
            height: 600,
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return ListTile(
                  title: Text(transaction['description']),
                  subtitle: Text(transaction['date']),
                  trailing: Text(
                    '${transaction['amount'] < 0 ? '-' : '+'}${isLamport ? transaction['amount'].abs().toStringAsFixed(2) + ' LAM' : 'R ' + (transaction['amount'] * 1.5).abs().toStringAsFixed(2)}',
                    style: TextStyle(
                      color:
                          transaction['amount'] < 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
