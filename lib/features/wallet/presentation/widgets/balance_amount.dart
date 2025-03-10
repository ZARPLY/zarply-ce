import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/formatters.dart';

class BalanceAmount extends StatefulWidget {
  const BalanceAmount({
    required this.walletAmount,
    required this.walletAddress,
    super.key,
  });

  final double walletAmount;
  final String walletAddress;

  @override
  State<BalanceAmount> createState() => _BalanceAmountState();
}

class _BalanceAmountState extends State<BalanceAmount> {
  bool _showCheckmark = false;

  Future<void> _copyToClipboard(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.walletAddress));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address copied to clipboard')),
      );
      setState(() {
        _showCheckmark = true;
      });
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showCheckmark = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: <Widget>[
          Text(
            Formatters.formatAmount(widget.walletAmount),
            style: Theme.of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _copyToClipboard(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    Formatters.shortenAddress(widget.walletAddress),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(width: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _showCheckmark
                        ? Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white.withOpacity(0.8),
                            key: const ValueKey<String>('check'),
                          )
                        : Icon(
                            Icons.copy,
                            size: 14,
                            color: Colors.white.withOpacity(0.8),
                            key: const ValueKey<String>('copy'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
