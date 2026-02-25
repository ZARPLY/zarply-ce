import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'secure_storage_service.dart';

class RpcService {
  RpcService({SecureStorageService? storageService}) : _storageService = storageService ?? SecureStorageService();

  final SecureStorageService _storageService;

  /// Get RPC configuration with user preference priority
  Future<({String rpcUrl, String websocketUrl})> getRpcConfiguration() async {
    
      // Try to get user-configured RPC settings first
      final ({String? rpcUrl, String? websocketUrl}) config = await _storageService.getRpcConfiguration();

      if (config.rpcUrl != null && config.websocketUrl != null) {
        return (
          rpcUrl: config.rpcUrl!,
          websocketUrl: config.websocketUrl!,
        );
      }
      return (
        rpcUrl: dotenv.env['solana_wallet_rpc_url']!,
        websocketUrl: dotenv.env['solana_wallet_websocket_url']!,
      );
   
  }

  Future<bool> validateRpcEndpoint(String rpcUrl) async {
    try {
      // Basic validation - you can enhance this with actual connectivity test
      final Uri uri = Uri.parse(rpcUrl);
      return uri.isAbsolute && (uri.scheme == 'https' || uri.scheme == 'http');
    } catch (e) {
      return false;
    }
  }

  /// Save RPC configuration
  Future<void> saveConfiguration({
    required String rpcUrl,
    required String websocketUrl,
  }) async {
    if (!await validateRpcEndpoint(rpcUrl)) {
      throw Exception('Invalid RPC URL format');
    }

    await _storageService.saveRpcConfiguration(
      rpcUrl: rpcUrl,
      websocketUrl: websocketUrl,
    );
  }

  /// Clear RPC configuration (revert to defaults)
  Future<void> clearConfiguration() async {
    await _storageService.clearRpcConfiguration();
  }
}
