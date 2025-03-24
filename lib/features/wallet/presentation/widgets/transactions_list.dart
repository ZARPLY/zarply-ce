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
      child: transactionItems.isEmpty
          ? const Center(
              child: Text('No transactions found'),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: transactionItems.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == transactionItems.length) {
                  return _buildFooter(context);
                }

                final dynamic item = transactionItems[index];

                if (item is Map<String, dynamic> && item['type'] == 'header') {
                  return _buildMonthHeader(context, item);
                } else if (item is TransactionDetails) {
                  return _buildTransactionItem(context, item);
                }

                return const SizedBox.shrink();
              },
            ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (viewModel.isLoadingMore) {
      return Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(),
          ),
          Text(
            'Loading more transactions... ${viewModel.loadedTransactions} loaded',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (viewModel.hasMoreTransactionsToLoad) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: TextButton(
            onPressed: viewModel.loadMoreTransactions,
            child: const Text('Load More Transactions'),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildMonthHeader(BuildContext context, Map<String, dynamic> header) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            Formatters.formatMonthHeader(header['month']),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '${header['count']}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    TransactionDetails transaction,
  ) {
    return _buildTransactionTile(transaction);
  }
}
