import 'package:flutter/material.dart';
import 'package:zarply/components/balance_amount.dart';

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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
            ),
            BalanceAmount(isLamport: isLamport, walletAmount: walletAmount),
            const SizedBox(height: 24),
            // RecentTransactions(
            //     transactions: transactions, isLamport: isLamport),
          ],
        ),
      ),
    );
  }
}
