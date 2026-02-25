import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentConstants {
  /// Minimum ZARP payment amount in Rands.
  static const double minZarpPaymentRands = 5;
}

// In your core/utils or core/services
class EnvironmentUtils {
  static bool get isMainnet {
    final String? rpcUrl = dotenv.env['solana_wallet_rpc_url'];
    if (rpcUrl == null) return false;
    return rpcUrl.contains('mainnet');
  }
}
