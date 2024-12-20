import 'package:intl/intl.dart';

class Formatters {
  static String shortenAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 5)}...${address.substring(address.length - 5)}';
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd').format(dateTime);
  }

  static String formatAmount(double amount, {required bool isLamport}) {
    return isLamport
        ? '${amount.toStringAsFixed(2)} LAM'
        : 'R ${(amount * 1.5).toStringAsFixed(2)}';
  }

  static String formatAmountWithSign(double amount, {required bool isLamport}) {
    return amount < 0
        ? '-${amount.toStringAsFixed(2)}'
        : '+${amount.toStringAsFixed(2)}';
  }
}
