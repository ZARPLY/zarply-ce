import 'package:flutter/material.dart';

import '../../utils/formatters.dart';

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
          Text(
            Formatters.formatAmount(walletAmount, isLamport: isLamport),
            style: Theme.of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
