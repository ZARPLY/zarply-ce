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
            style: TextStyle(
                fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // TODO: we can simplify code by creating formatter util methods
          // TODO: get rid of useless comments
          Text(
            isLamport
                ? '${walletAmount.toStringAsFixed(2)} LAM'
                : 'R ${(walletAmount * 1.5).toStringAsFixed(2)}', // Example conversion rate
            style: const TextStyle(
                fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
