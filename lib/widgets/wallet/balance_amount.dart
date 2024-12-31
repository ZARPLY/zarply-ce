import 'package:flutter/material.dart';

import '../../utils/formatters.dart';

class BalanceAmount extends StatelessWidget {
  const BalanceAmount({
    required this.walletAmount,
    super.key,
  });

  final double walletAmount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: <Widget>[
          Text(
            Formatters.formatAmount(walletAmount),
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
