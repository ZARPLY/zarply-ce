import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';

class PaymentSuccess extends StatelessWidget {
  const PaymentSuccess({
    required this.amount,
    super.key,
  });
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Payment Complete',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.go('/wallet'),
              ),
            ],
          ),
          const SizedBox(height: 96),
          Container(
            width: 200,
            height: 200,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 100,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            Formatters.formatAmount(double.parse(amount) / 100),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 32),
          Text(
            'Payment Successful',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            DateTime.now().toString().substring(0, 16),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/wallet'),
              style: ElevatedButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
