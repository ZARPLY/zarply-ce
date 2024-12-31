import 'package:intl/intl.dart';

class Formatters {
  static String shortenAddress(String address) {
    if (address.length <= 20) return address;
    return '${address.substring(0, 20)}...';
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd').format(dateTime);
  }

  static String formatAmount(double amount) {
    final NumberFormat currencyFormat = NumberFormat.currency(
      symbol: 'R',
      decimalDigits: 2,
    );
    return currencyFormat.format(amount);
  }

  static String formatAmountWithSign(double amount) {
    final NumberFormat currencyFormat = NumberFormat.currency(
      symbol: 'R',
      decimalDigits: 2,
    );
    return amount < 0
        ? '-${currencyFormat.format(amount)}'
        : currencyFormat.format(amount);
  }
}
