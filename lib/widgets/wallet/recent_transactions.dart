import 'package:flutter/material.dart';

import '../../utils/formatters.dart';

class RecentTransactions extends StatelessWidget {
  const RecentTransactions({
    required this.transactions,
    required this.isLamport,
    super.key,
  });

  final List<Map<String, dynamic>> transactions;
  final bool isLamport;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
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
              itemBuilder: (BuildContext context, int index) {
                final Map<String, dynamic> transaction = transactions[index];
                return ListTile(
                  title: Text(transaction['description']),
                  subtitle: Text(transaction['date']),
                  trailing: Text(
                    Formatters.formatAmountWithSign(
                      transaction['amount'].abs(),
                    ),
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
