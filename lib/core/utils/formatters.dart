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

  static String formatAmount(double amount, {String currency = 'ZARP'}) {
    if (currency == 'SOL') {
      final NumberFormat numberFormat = NumberFormat('#,##0.00', 'en_US');
      return 'SOL ${numberFormat.format(amount)}';
    } else {
      // For ZARP, format with R symbol
      final NumberFormat currencyFormat = NumberFormat.currency(
        symbol: 'R',
        decimalDigits: 2,
        locale: 'en_US',
      );
      return currencyFormat.format(amount);
    }
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
