import 'package:flutter/material.dart';
import 'package:solana/dto.dart';

import '../../../../core/services/transaction_parser_service.dart';
import '../../../../core/utils/formatters.dart';
import '../models/transaction_list_item.dart';
import '../models/wallet_view_model.dart';
import 'transaction_item.dart';

class TransactionsList extends StatefulWidget {
  const TransactionsList({
    required this.viewModel,
    super.key,
  });

  final WalletViewModel viewModel;

  @override
  State<TransactionsList> createState() => _TransactionsListState();
}

class _TransactionsListState extends State<TransactionsList> {
  @override
  Widget build(BuildContext context) {
    final List<TransactionListItem> transactionItems = widget.viewModel.getSortedTransactionItems();
    if (transactionItems.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: const Center(
            child: Text('No transactions found'),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: transactionItems.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == transactionItems.length) {
          return _buildFooter(context);
        }

        final TransactionListItem item = transactionItems[index];

        switch (item) {
          case TransactionMonthHeader(:final String monthKey, :final int displayedCount):
            return _buildMonthHeader(context, monthKey, displayedCount);
          case TransactionEntry(:final TransactionDetails? transaction):
            return transaction != null ? _buildTransactionItem(context, transaction) : const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (widget.viewModel.isLoadingMore) {
      return Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: CircularProgressIndicator(
              color: Colors.blue,
            ),
          ),
          Text(
            'Loading more transactions...',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (widget.viewModel.hasMoreTransactionsToLoad) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: TextButton(
            onPressed: widget.viewModel.loadMoreTransactions,
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
            child: const Text('Load More Transactions'),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildMonthHeader(BuildContext context, String monthKey, int displayedCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            Formatters.formatMonthHeader(monthKey),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '$displayedCount',
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

  Widget _buildTransactionTile(TransactionDetails? transaction) {
    if (transaction == null) return const SizedBox.shrink();

    final TransactionTransferInfo? transferInfo = widget.viewModel.parseTransferDetails(transaction);

    if (transferInfo == null) {
      return const SizedBox.shrink(); // Only filter out null transfer info
    }

    return TransactionItem(
      transferInfo: transferInfo,
    );
  }
}
