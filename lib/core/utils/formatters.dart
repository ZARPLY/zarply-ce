import 'package:intl/intl.dart';

class Formatters {
  static String shortenAddress(String address) {
    if (address.length <= 20) return address;
    return '${address.substring(0, 20)}...';
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd • HH:mm').format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd').format(dateTime);
  }

  static String formatAmount(double amount) {
    final NumberFormat currencyFormat = NumberFormat.currency(
      symbol: 'R',
      decimalDigits: 2,
      locale: 'en_US',
    );
    return currencyFormat.format(amount);
  }

  /// Converts amount in cents (string) to rands (double). Uses 0 if input is invalid.
  static double centsToRands(String cents) {
    return (double.tryParse(cents) ?? 0) / 100;
  }

  /// Returns a balance label string for UI (e.g. "(Balance: R123.45)").
  static String formatBalanceLabel(double balance) {
    return '(Balance: ${formatAmount(balance)})';
  }

  /// Returns a sortable key for the given date (e.g. "2025-02").
  static String monthKeyFromDate(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  static String formatMonthHeader(String monthKey) {
    final List<String> parts = monthKey.split('-');
    final String year = parts[0];
    final int month = int.parse(parts[1]);

    final List<String> monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${monthNames[month - 1]} $year';
  }
}
