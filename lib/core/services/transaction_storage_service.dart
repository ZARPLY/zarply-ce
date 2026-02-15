import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solana/dto.dart';

import '../utils/formatters.dart';

class TransactionStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Single source of truth for display. Month-keyed filtered transactions.
  final String _transactionsKey = 'wallet_transactions';
  final String _lastTransactionKey = 'last_transaction_signature';
  final String _lastTransactionLegacyKey = 'last_transaction_signature_legacy';
  final String _transactionCountKey = 'transaction_count';
  final String _oldestLoadedSigMainKey = 'oldest_loaded_signature_main';
  final String _oldestLoadedSigLegacyKey = 'oldest_loaded_signature_legacy';
  static const String _cachedWalletAddressKey = 'cached_wallet_address';

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
          (String key, List<TransactionDetails?> value) => MapEntry<String, List<Map<String, Object?>?>>(
            key,
            value.map((TransactionDetails? transaction) => transaction?.toJson() as Map<String, Object?>?).toList(),
          ),
        ),
      );

      await _secureStorage.write(
        key: _transactionsKey,
        value: encodedData,
      );

      await storeCachedWalletAddress(walletAddress);
    } catch (e) {
      throw Exception('Failed to store transactions: $e');
    }
  }

  /// Merges [newTransactions] into stored data (by month, at front) and persists.
  Future<void> mergeAndStoreTransactions(
    List<TransactionDetails?> newTransactions, {
    required String walletAddress,
  }) async {
    final Map<String, List<TransactionDetails?>> stored = await getStoredTransactions(
      walletAddress: walletAddress,
    );
    for (final TransactionDetails? transaction in newTransactions) {
      if (transaction == null) continue;
      final DateTime transactionDate = DateTime.fromMillisecondsSinceEpoch(
        transaction.blockTime! * 1000,
      );
      final String monthKey = Formatters.monthKeyFromDate(transactionDate);
      if (!stored.containsKey(monthKey)) {
        stored[monthKey] = <TransactionDetails?>[];
      }
      stored[monthKey]!.insert(0, transaction);
    }
    await storeTransactions(stored, walletAddress: walletAddress);
  }

  /// Returns the merged-list (only source of truth for display).
  Future<Map<String, List<TransactionDetails?>>> getStoredTransactions({
    required String walletAddress,
  }) async {
    try {
      final bool walletMatch = await isCachedWalletMatch(walletAddress);
      if (!walletMatch) {
        await clearTransactionCache();
        return <String, List<TransactionDetails?>>{};
      }

      final String? encodedData = await _secureStorage.read(key: _transactionsKey);
      if (encodedData == null) return <String, List<TransactionDetails?>>{};

      final Map<String, Object?> decodedData = jsonDecode(encodedData) as Map<String, Object?>;
      return decodedData.map(
        (String key, Object? value) => MapEntry<String, List<TransactionDetails?>>(
          key,
          (value as List<Object?>)
              .map(
                (Object? item) => item == null
                    ? null
                    : TransactionDetails.fromJson(
                        item as Map<String, dynamic>,
                      ),
              )
              .toList(),
        ),
      );
    } catch (e) {
      throw Exception('Failed to retrieve transactions: $e');
    }
  }

  Future<void> storeLastTransactionSignature(
    String signature, {
    required String walletAddress,
    bool isLegacy = false,
  }) async {
    try {
      final String key = isLegacy ? _lastTransactionLegacyKey : _lastTransactionKey;
      await _secureStorage.write(key: key, value: signature);
      if (!isLegacy) await storeCachedWalletAddress(walletAddress);
    } catch (e) {
      throw Exception('Failed to store last transaction signature: $e');
    }
  }

  Future<String?> getLastTransactionSignature({
    required String walletAddress,
    bool isLegacy = false,
  }) async {
    try {
      final String key = isLegacy ? _lastTransactionLegacyKey : _lastTransactionKey;
      if (!isLegacy && !await isCachedWalletMatch(walletAddress)) {
        await clearTransactionCache();
        return null;
      }
      return await _secureStorage.read(key: key);
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

  /// Store oldest loaded signatures (per account) for "load more" pagination.
  Future<void> storeOldestLoadedSignatures({
    String? mainSignature,
    String? legacySignature,
  }) async {
    try {
      if (mainSignature != null) {
        await _secureStorage.write(key: _oldestLoadedSigMainKey, value: mainSignature);
      }
      if (legacySignature != null) {
        await _secureStorage.write(key: _oldestLoadedSigLegacyKey, value: legacySignature);
      }
    } catch (e) {
      throw Exception('Failed to store oldest loaded signatures: $e');
    }
  }

  /// Retrieve oldest loaded signatures for main and legacy accounts.
  Future<({String? mainSignature, String? legacySignature})> getOldestLoadedSignatures() async {
    try {
      final String? main = await _secureStorage.read(key: _oldestLoadedSigMainKey);
      final String? legacy = await _secureStorage.read(key: _oldestLoadedSigLegacyKey);
      return (mainSignature: main, legacySignature: legacy);
    } catch (e) {
      throw Exception('Failed to get oldest loaded signatures: $e');
    }
  }

  /// Clear all transaction cache data.
  Future<void> clearTransactionCache() async {
    try {
      await _secureStorage.delete(key: _transactionsKey);
      await _secureStorage.delete(key: _lastTransactionKey);
      await _secureStorage.delete(key: _lastTransactionLegacyKey);
      await _secureStorage.delete(key: _transactionCountKey);
      await _secureStorage.delete(key: _oldestLoadedSigMainKey);
      await _secureStorage.delete(key: _oldestLoadedSigLegacyKey);
      await _secureStorage.delete(key: _cachedWalletAddressKey);
    } catch (e) {
      throw Exception('Failed to clear transaction cache: $e');
    }
  }
}
