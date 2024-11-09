import 'package:flutter/material.dart';
import 'package:zarply/shared/auth_layout.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool isLamport = true;
  double walletAmount = 12345.67;
  List<Map<String, dynamic>> transactions = [
    {"date": "2024-11-01", "description": "Coffee Shop", "amount": -50.75},
    {"date": "2024-11-01", "description": "Grocery Store", "amount": -200.00},
    {"date": "2024-10-30", "description": "Salary", "amount": 5000.00},
    {"date": "2024-10-29", "description": "Subscription", "amount": -99.99},
  ]; // Example transactions

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: const Text("Wallet"),
      actions: [
        Switch(
          value: isLamport,
          onChanged: (value) {
            setState(() {
              isLamport = value;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Center(child: Text(isLamport ? "Lamport" : "Rand")),
        ),
      ],
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Amount in Wallet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isLamport
                  ? '${walletAmount.toStringAsFixed(2)} LAM'
                  : 'R ${(walletAmount * 1.5).toStringAsFixed(2)}', // Example conversion rate
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
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
                          color: transaction['amount'] < 0
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
