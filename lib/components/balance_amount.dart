import 'package:flutter/material.dart';

class BalanceAmount extends StatelessWidget {
  const BalanceAmount({
    super.key,
    required this.isLamport,
    required this.walletAmount,
  });

  final bool isLamport;
  final double walletAmount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
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
        ],
      ),
    );
  }
}
