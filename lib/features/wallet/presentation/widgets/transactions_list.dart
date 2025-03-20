import 'package:flutter/material.dart';
import 'package:solana/dto.dart';

import '../../../../core/services/transaction_parser_service.dart';
import '../../../../core/utils/formatters.dart';
import '../models/wallet_view_model.dart';
import 'activity_item.dart';

class TransactionsList extends StatelessWidget {
  const TransactionsList({
    required this.viewModel,
    super.key,
  });

  final WalletViewModel viewModel;

  Widget _buildTransactionTile(TransactionDetails? transaction) {
    if (transaction == null) return const SizedBox.shrink();

    final TransactionTransferInfo? transferInfo =
        viewModel.parseTransferDetails(transaction);

    if (transferInfo == null || transferInfo.amount == 0) {
      return const SizedBox.shrink();
    }

    return ActivityItem(
      transferInfo: transferInfo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> transactionItems =
        viewModel.getSortedTransactionItems();

    return RefreshIndicator(
      onRefresh: viewModel.refreshTransactions,
      child: ListView.builder(
        itemCount: transactionItems.length,
        itemBuilder: (BuildContext context, int index) {
          final dynamic item = transactionItems[index];

          if (item is Map && item['type'] == 'header') {
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    Formatters.formatMonthHeader(item['month']),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${item['count']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return _buildTransactionTile(item);
        },
      ),
    );
  }
}
