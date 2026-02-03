import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solana/dto.dart';

class TransactionStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _transactionsKey = 'wallet_transactions';
  final String _transactionSignaturesKey = 'wallet_transaction_signatures';
  final String _legacyTransactionSignaturesKey = 'legacy_wallet_transaction_signatures';
  final String _lastTransactionKey = 'last_transaction_signature';
  final String _transactionCountKey = 'transaction_count';
  static const String _legacyMigrationCheckedKey = 'legacy_migration_checked_';
  static const String _legacyTransactionsKey = 'legacy_wallet_transactions';
  static const String _hiddenMigrationTxSignatureKey = 'hidden_migration_tx_signature';
  static const String _hiddenMigrationTxTimestampKey = 'hidden_migration_tx_timestamp';
  static const String _systemTransactionsKey = 'system_transaction_signatures';

  Future<void> storeTransactions(
    Map<String, List<TransactionDetails?>> transactions,
  ) async {
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
    } catch (e) {
      throw Exception('Failed to store transactions: $e');
    }
  }

  /// Store transaction signatures grouped by month
  Future<void> storeTransactionSignatures(
    Map<String, List<String>> signaturesByMonth,
  ) async {
    try {
      final String encodedData = jsonEncode(signaturesByMonth);
      await _secureStorage.write(
        key: _transactionSignaturesKey,
        value: encodedData,
      );
    } catch (e) {
      throw Exception('Failed to store transaction signatures: $e');
    }
  }

  /// Get stored transaction signatures grouped by month
  Future<Map<String, List<String>>> getStoredTransactionSignatures() async {
    try {
      final String? encodedData = await _secureStorage.read(key: _transactionSignaturesKey);
      if (encodedData == null) return <String, List<String>>{};

      final Map<String, dynamic> decodedData = jsonDecode(encodedData);
      return decodedData.map(
        (String key, dynamic value) => MapEntry<String, List<String>>(
          key,
          (value as List<dynamic>).map((dynamic sig) => sig.toString()).toList(),
        ),
      );
    } catch (e) {
      return <String, List<String>>{};
    }
  }

  /// Store legacy transaction signatures grouped by month
  Future<void> storeLegacyTransactionSignatures(
    Map<String, List<String>> signaturesByMonth,
  ) async {
    try {
      final String encodedData = jsonEncode(signaturesByMonth);
      await _secureStorage.write(
        key: _legacyTransactionSignaturesKey,
        value: encodedData,
      );
    } catch (e) {
      throw Exception('Failed to store legacy transaction signatures: $e');
    }
  }

  /// Get stored legacy transaction signatures grouped by month
  Future<Map<String, List<String>>> getStoredLegacyTransactionSignatures() async {
    try {
      final String? encodedData = await _secureStorage.read(key: _legacyTransactionSignaturesKey);
      if (encodedData == null) return <String, List<String>>{};

      final Map<String, dynamic> decodedData = jsonDecode(encodedData);
      return decodedData.map(
        (String key, dynamic value) => MapEntry<String, List<String>>(
          key,
          (value as List<dynamic>).map((dynamic sig) => sig.toString()).toList(),
        ),
      );
    } catch (e) {
      return <String, List<String>>{};
    }
  }

  Future<Map<String, List<TransactionDetails?>>> getStoredTransactions() async {
    try {
      final String? encodedData = await _secureStorage.read(key: _transactionsKey);
      if (encodedData == null) return <String, List<TransactionDetails?>>{};

      final Map<String, dynamic> decodedData = jsonDecode(encodedData);
      final Map<String, List<TransactionDetails?>> transactions = decodedData.map(
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

      // Filter out system transactions by extracting signature from each transaction
      final Set<String> systemTxs = await getSystemTransactionSignatures();
      
      if (systemTxs.isEmpty) return transactions; // No system transactions to filter

      final Map<String, List<TransactionDetails?>> filtered = <String, List<TransactionDetails?>>{};
      
      transactions.forEach((String monthKey, List<TransactionDetails?> txList) {
        final List<TransactionDetails?> filteredList = <TransactionDetails?>[];
        
        for (final TransactionDetails? tx in txList) {
          if (tx == null) {
            continue;
          }
          
          // Extract signature directly from transaction
          String? txSignature;
          try {
            final dynamic txJson = tx.transaction.toJson();
            if (txJson is Map<String, dynamic> && txJson['signatures'] != null) {
              final List<dynamic> sigs = txJson['signatures'] as List<dynamic>;
              if (sigs.isNotEmpty) {
                txSignature = sigs[0].toString();
              }
            }
          } catch (e) {
            // If we can't extract signature, include the transaction
          }
          
          // Skip if this is a system transaction
          if (txSignature != null && systemTxs.contains(txSignature)) {
            continue;
          }
          
          filteredList.add(tx);
        }
        
        if (filteredList.isNotEmpty) {
          filtered[monthKey] = filteredList;
        }
      });
      
      return filtered;
    } catch (e) {
      throw Exception('Failed to retrieve transactions: $e');
    }
  }

  Future<void> storeLastTransactionSignature(String signature) async {
    try {
      await _secureStorage.write(
        key: _lastTransactionKey,
        value: signature,
      );
    } catch (e) {
      throw Exception('Failed to store last transaction signature: $e');
    }
  }

  Future<String?> getLastTransactionSignature() async {
    try {
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

  /// Check if legacy migration has been checked for a wallet
  Future<bool> hasLegacyMigrationBeenChecked(String walletAddress) async {
    try {
      final String? checked = await _secureStorage.read(
        key: '$_legacyMigrationCheckedKey$walletAddress',
      );
      return checked == 'true' || checked == 'migrated';
    } catch (e) {
      return false;
    }
  }

  /// Mark legacy migration as checked (balance was 0)
  Future<void> markLegacyMigrationAsChecked(String walletAddress) async {
    await _secureStorage.write(
      key: '$_legacyMigrationCheckedKey$walletAddress',
      value: 'true',
    );
  }

  /// Mark legacy migration as completed (balance was > 0 and drained)
  Future<void> markLegacyMigrationAsNeeded(String walletAddress) async {
    await _secureStorage.write(
      key: '$_legacyMigrationCheckedKey$walletAddress',
      value: 'migrated',
    );
  }

  /// Store legacy transactions
  Future<void> storeLegacyTransactions(
    Map<String, List<TransactionDetails?>> transactions,
  ) async {
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
        key: _legacyTransactionsKey,
        value: encodedData,
      );
    } catch (e) {
      throw Exception('Failed to store legacy transactions: $e');
    }
  }

  /// Get stored legacy transactions
  Future<Map<String, List<TransactionDetails?>>> getStoredLegacyTransactions() async {
    try {
      final String? encodedData = await _secureStorage.read(key: _legacyTransactionsKey);
      if (encodedData == null) return <String, List<TransactionDetails?>>{};

      final Map<String, dynamic> decodedData = jsonDecode(encodedData);
      final Map<String, List<TransactionDetails?>> transactions = decodedData.map(
        (String key, dynamic value) => MapEntry<String, List<TransactionDetails?>>(
          key,
          (value as List<dynamic>)
              .map(
                (dynamic tx) => tx == null
                    ? null
                    : TransactionDetails.fromJson(tx as Map<String, dynamic>),
              )
              .toList(),
        ),
      );

      // Filter out system transactions by extracting signature from each transaction
      final Set<String> systemTxs = await getSystemTransactionSignatures();
      
      if (systemTxs.isEmpty) return transactions; // No system transactions to filter

      final Map<String, List<TransactionDetails?>> filtered = <String, List<TransactionDetails?>>{};
      
      transactions.forEach((String monthKey, List<TransactionDetails?> txList) {
        final List<TransactionDetails?> filteredList = <TransactionDetails?>[];
        
        for (final TransactionDetails? tx in txList) {
          if (tx == null) {
            continue;
          }
          
          // Extract signature directly from transaction
          String? txSignature;
          try {
            final dynamic txJson = tx.transaction.toJson();
            if (txJson is Map<String, dynamic> && txJson['signatures'] != null) {
              final List<dynamic> sigs = txJson['signatures'] as List<dynamic>;
              if (sigs.isNotEmpty) {
                txSignature = sigs[0].toString();
              }
            }
          } catch (e) {
            // If we can't extract signature, include the transaction
          }
          
          // Skip if this is a system transaction
          if (txSignature != null && systemTxs.contains(txSignature)) {
            continue;
          }
          
          filteredList.add(tx);
        }
        
        if (filteredList.isNotEmpty) {
          filtered[monthKey] = filteredList;
        }
      });
      
      return filtered;
    } catch (e) {
      return <String, List<TransactionDetails?>>{};
    }
  }

  /// Store migration transaction info (signature and timestamp)
  Future<void> storeMigrationTransactionInfo({
    required String signature,
    required int? timestamp,
  }) async {
    await _secureStorage.write(
      key: _hiddenMigrationTxSignatureKey,
      value: signature,
    );
    if (timestamp != null) {
      await _secureStorage.write(
        key: _hiddenMigrationTxTimestampKey,
        value: timestamp.toString(),
      );
    }
  }

  /// Get hidden migration transaction signature
  Future<String?> getHiddenMigrationSignature() async {
    return await _secureStorage.read(key: _hiddenMigrationTxSignatureKey);
  }

  /// Get hidden migration transaction timestamp
  Future<int?> getHiddenMigrationTimestamp() async {
    final String? timestampStr = await _secureStorage.read(key: _hiddenMigrationTxTimestampKey);
    return timestampStr != null ? int.tryParse(timestampStr) : null;
  }

  /// Add a system transaction signature (to hide from UI)
  Future<void> addSystemTransactionSignature(String signature) async {
    try {
      final Set<String> systemTxs = await getSystemTransactionSignatures();
      systemTxs.add(signature);
      await _secureStorage.write(
        key: _systemTransactionsKey,
        value: jsonEncode(systemTxs.toList()),
      );
    } catch (e) {
      throw Exception('Failed to store system transaction signature: $e');
    }
  }

  /// Get all system transaction signatures
  Future<Set<String>> getSystemTransactionSignatures() async {
    try {
      final String? data = await _secureStorage.read(key: _systemTransactionsKey);
      if (data == null) return <String>{};
      final List<dynamic> list = jsonDecode(data);
      return list.map((dynamic e) => e.toString()).toSet();
    } catch (e) {
      return <String>{};
    }
  }
}
