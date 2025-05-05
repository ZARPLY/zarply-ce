import 'package:flutter/material.dart';

import '../../features/pay/presentation/models/payment_amount_view_model.dart';
import '../services/transaction_parser_service.dart';
import '../utils/formatters.dart';

class PreviouslyPaidInfo extends StatefulWidget {
  const PreviouslyPaidInfo({
    required this.viewModel,
    required this.recipientAddress,
    super.key,
  });

  final PaymentAmountViewModel viewModel;
  final String recipientAddress;

  @override
  State<PreviouslyPaidInfo> createState() => _PreviouslyPaidInfoState();
}

class _PreviouslyPaidInfoState extends State<PreviouslyPaidInfo> {
  TransactionTransferInfo? previousTransaction;

  Future<void> loadPreviousTransaction() async {
    previousTransaction = await widget.viewModel.getPreviousTransaction();
  }

  @override
  void initState() {
    super.initState();
    loadPreviousTransaction();
  }

  @override
  Widget build(BuildContext context) {
    if (previousTransaction == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text(
            Formatters.formatAmount(previousTransaction!.amount.abs()),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          previousTransaction!.timestamp != null
              ? Formatters.formatDate(previousTransaction!.timestamp!)
              : 'Unknown',
        ),
      ],
    );
  }
}
