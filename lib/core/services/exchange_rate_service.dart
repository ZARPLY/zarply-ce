import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';

  /// Fetches the current SOL to ZAR exchange rate
  static Future<double> getSolToZarRate() async {
    try {
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/simple/price?ids=solana&vs_currencies=zar&t=${DateTime.now().millisecondsSinceEpoch}'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final double rate = data['solana']['zar']?.toDouble() ?? 2000.0;
        print('API returned SOL/ZAR rate: $rate'); // Debug log
        return rate;
      } else {
        print('API failed with status: ${response.statusCode}'); // Debug log
        // Fallback to default rate if API fails
        return 2000.0;
      }
    } catch (e) {
      print('API error: $e'); // Debug log
      // Fallback to default rate if there's an error
      return 2000.0;
    }
  }

  /// Fetches the current ZAR to SOL exchange rate (inverse)
  static Future<double> getZarToSolRate() async {
    final solToZar = await getSolToZarRate();
    return 1.0 / solToZar;
  }
}
