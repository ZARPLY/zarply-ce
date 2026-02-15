import 'package:solana/dto.dart';

/// A single item in the transaction list UI: either a month header or a transaction row.
sealed class TransactionListItem {}

/// Month section header in the transaction list.
final class TransactionMonthHeader implements TransactionListItem {
  const TransactionMonthHeader({
    required this.monthKey,
    required this.displayedCount,
  });

  final String monthKey;
  final int displayedCount;
}

/// A transaction row in the list.
final class TransactionEntry implements TransactionListItem {
  const TransactionEntry(this.transaction);

  final TransactionDetails? transaction;
}
