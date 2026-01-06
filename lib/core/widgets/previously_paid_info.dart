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
  late Future<TransactionTransferInfo?> _previousTransactionFuture;

  @override
  void initState() {
    super.initState();
    _previousTransactionFuture = widget.viewModel.getPreviousTransaction();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TransactionTransferInfo?>(
      future: _previousTransactionFuture,
      builder:
          (
            BuildContext context,
            AsyncSnapshot<TransactionTransferInfo?> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }

            if (snapshot.hasError) {
              return const Text(
                'Error loading previous payment',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              );
            }

            final TransactionTransferInfo? previousTransaction = snapshot.data;

            if (previousTransaction == null) {
              return const Text(
                'No previous payment',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      Formatters.formatAmount(previousTransaction.amount.abs()),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Last payment',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          previousTransaction.timestamp != null
                              ? Formatters.formatDate(
                                  previousTransaction.timestamp!,
                                )
                              : 'Unknown date',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }
}
