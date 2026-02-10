import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solana/dto.dart';

class TransactionStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _transactionsKey = 'wallet_transactions';
  final String _lastTransactionKey = 'last_transaction_signature';
  final String _transactionCountKey = 'transaction_count';
  static const String _cachedWalletAddressKey = 'cached_wallet_address';
  static const String _systemTransactionsKey = 'system_transaction_signatures';

  /// Store the wallet address that transactions belong to
  Future<void> storeCachedWalletAddress(String walletAddress) async {
    try {
      await _secureStorage.write(
        key: _cachedWalletAddressKey,
        value: walletAddress,
      );
    } catch (e) {
      throw Exception('Failed to store cached wallet address: $e');
    }
  }

  /// Get the wallet address that cached transactions belong to
  Future<String?> getCachedWalletAddress() async {
    try {
      return await _secureStorage.read(key: _cachedWalletAddressKey);
    } catch (e) {
      throw Exception('Failed to get cached wallet address: $e');
    }
  }

  /// Check if the cached wallet matches the current wallet
  Future<bool> isCachedWalletMatch(String walletAddress) async {
    final String? cachedAddress = await getCachedWalletAddress();
    return cachedAddress == walletAddress;
  }

  Future<void> storeTransactions(
    Map<String, List<TransactionDetails?>> transactions, {
    required String walletAddress,
  }) async {
    try {
      final String encodedData = jsonEncode(
        transactions.map(
          (String key, List<TransactionDetails?> value) => MapEntry<String, List<Map<String, dynamic>?>>(
            key,
            value.map((TransactionDetails? tx) => tx?.toJson()).toList(),
          ),
        ),
      );

      await _secureStorage.write(
        key: _transactionsKey,
        value: encodedData,
      );

      // Store the wallet address for future validation
      await storeCachedWalletAddress(walletAddress);
    } catch (e) {
      throw Exception('Failed to store transactions: $e');
    }
  }

  Future<Map<String, List<TransactionDetails?>>> getStoredTransactions({
    required String walletAddress,
  }) async {
    try {
      // Check if cached wallet matches current wallet
      final bool walletMatch = await isCachedWalletMatch(walletAddress);
      if (!walletMatch) {
        // Clear cache if wallet doesn't match
        await clearTransactionCache();
        return <String, List<TransactionDetails?>>{};
      }

      final String? encodedData = await _secureStorage.read(key: _transactionsKey);
      if (encodedData == null) return <String, List<TransactionDetails?>>{};

      final Map<String, dynamic> decodedData = jsonDecode(encodedData);
      return decodedData.map(
        (String key, dynamic value) => MapEntry<String, List<TransactionDetails?>>(
          key,
          (value as List<dynamic>)
              .map(
                (dynamic tx) => tx == null
                    ? null
                    : TransactionDetails.fromJson(
                        tx as Map<String, dynamic>,
                      ),
              )
              .toList(),
        ),
      );
    } catch (e) {
      throw Exception('Failed to retrieve transactions: $e');
    }
  }

  Future<void> storeLastTransactionSignature(String signature, {required String walletAddress}) async {
    try {
      await _secureStorage.write(
        key: _lastTransactionKey,
        value: signature,
      );
      // Update cached wallet address when storing signature
      await storeCachedWalletAddress(walletAddress);
    } catch (e) {
      throw Exception('Failed to store last transaction signature: $e');
    }
  }

  Future<String?> getLastTransactionSignature({required String walletAddress}) async {
    try {
      // Check if cached wallet matches current wallet
      final bool walletMatch = await isCachedWalletMatch(walletAddress);
      if (!walletMatch) {
        // Clear cache if wallet doesn't match
        await clearTransactionCache();
        return null;
      }

      return await _secureStorage.read(key: _lastTransactionKey);
    } catch (e) {
      throw Exception('Failed to get last transaction signature: $e');
    }
  }

  Future<void> storeTransactionCount(int count) async {
    try {
      await _secureStorage.write(
        key: _transactionCountKey,
        value: count.toString(),
      );
    } catch (e) {
      throw Exception('Failed to store transaction count: $e');
    }
  }

  Future<int?> getStoredTransactionCount() async {
    try {
      final String? count = await _secureStorage.read(key: _transactionCountKey);
      return count != null ? int.parse(count) : null;
    } catch (e) {
      throw Exception('Failed to retrieve transaction count: $e');
    }
  }

  /// Clear all transaction cache data
  Future<void> clearTransactionCache() async {
    try {
      await _secureStorage.delete(key: _transactionsKey);
      await _secureStorage.delete(key: _lastTransactionKey);
      await _secureStorage.delete(key: _transactionCountKey);
      await _secureStorage.delete(key: _cachedWalletAddressKey);
    } catch (e) {
      throw Exception('Failed to clear transaction cache: $e');
    }
  }

  /// Add a system transaction signature (e.g., drain transactions) to filter list
  Future<void> addSystemTransactionSignature(String signature) async {
    try {
      final Set<String> systemTxs = await getSystemTransactionSignatures();
      systemTxs.add(signature);
      final String encodedData = jsonEncode(systemTxs.toList());
      await _secureStorage.write(
        key: _systemTransactionsKey,
        value: encodedData,
      );
    } catch (e) {
      throw Exception('Failed to add system transaction signature: $e');
    }
  }

  /// Get all system transaction signatures that should be filtered out
  Future<Set<String>> getSystemTransactionSignatures() async {
    try {
      final String? encodedData = await _secureStorage.read(key: _systemTransactionsKey);
      if (encodedData == null) return <String>{};
      final List<dynamic> decodedData = jsonDecode(encodedData);
      return decodedData.map((dynamic sig) => sig as String).toSet();
    } catch (e) {
      return <String>{};
    }
  }
}
