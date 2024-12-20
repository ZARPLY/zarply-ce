import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class BalanceAmount extends StatelessWidget {
  const BalanceAmount({
    required this.isLamport,
    required this.walletAmount,
    super.key,
  });

  final bool isLamport;
  final double walletAmount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: <Widget>[
          const Text(
            'Amount in Wallet',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.formatAmount(walletAmount, isLamport: isLamport),
            style: const TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
