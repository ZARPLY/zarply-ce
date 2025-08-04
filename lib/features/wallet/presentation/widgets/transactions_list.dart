import 'package:flutter/material.dart';
import 'package:solana/dto.dart';

import '../../../../core/services/transaction_parser_service.dart';
import '../../../../core/utils/formatters.dart';
import '../models/wallet_view_model.dart';
import 'transaction_item.dart';

class TransactionsList extends StatefulWidget {
  const TransactionsList({
    required this.viewModel,
    required this.selectedCurrency,
    super.key,
  });

  final WalletViewModel viewModel;
  final String selectedCurrency;

  @override
  State<TransactionsList> createState() => _TransactionsListState();
}

class _TransactionsListState extends State<TransactionsList> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    widget.viewModel.refreshIndicatorKey = _refreshIndicatorKey;
  }

  Widget _buildTransactionTile(TransactionDetails? transaction) {
    if (transaction == null) return const SizedBox.shrink();

    return FutureBuilder<TransactionTransferInfo?>(
      future: widget.viewModel
          .parseTransferDetails(transaction, widget.selectedCurrency),
      builder: (context, snapshot) {
        // Show cached data immediately, only show loading for new data
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final TransactionTransferInfo? transferInfo = snapshot.data;
        if (transferInfo == null || transferInfo.amount == 0) {
          return const SizedBox.shrink();
        }

        return TransactionItem(
          transferInfo: transferInfo,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: _refreshIndicatorKey,
      color: Colors.blue,
      onRefresh: () => widget.viewModel
          .refreshTransactions(selectedCurrency: widget.selectedCurrency),
      child: FutureBuilder<List<dynamic>>(
        future: widget.viewModel.getSortedTransactionItems(
            selectedCurrency: widget.selectedCurrency),
        builder: (context, snapshot) {
          // Show cached data immediately if available
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading transactions'),
            );
          }

          final List<dynamic> transactionItems = snapshot.data ?? [];

          // Only show loading indicator for new data, not for cached data
          if (widget.viewModel.isLoadingTransactions &&
              transactionItems.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            );
          }

          return transactionItems.isEmpty
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

                    if (item is Map<String, dynamic> &&
                        item['type'] == 'header') {
                      return _buildMonthHeader(context, item);
                    } else if (item is TransactionDetails) {
                      return _buildTransactionItem(context, item);
                    }

                    return const SizedBox.shrink();
                  },
                );
        },
      ),
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
