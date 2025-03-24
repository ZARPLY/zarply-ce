import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:solana/dto.dart';

class TransactionStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _transactionsKey = 'wallet_transactions';
  final String _lastTransactionKey = 'last_transaction_signature';
  final String _transactionCountKey = 'transaction_count';

  Future<void> storeTransactions(
    Map<String, List<TransactionDetails?>> transactions,
  ) async {
    try {
      final String encodedData = jsonEncode(
        transactions.map(
          (String key, List<TransactionDetails?> value) =>
              MapEntry<String, List<Map<String, dynamic>?>>(
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

  Future<Map<String, List<TransactionDetails?>>> getStoredTransactions() async {
    try {
      final String? encodedData =
          await _secureStorage.read(key: _transactionsKey);
      if (encodedData == null) return <String, List<TransactionDetails?>>{};

      final Map<String, dynamic> decodedData = jsonDecode(encodedData);
      return decodedData.map(
        (String key, dynamic value) =>
            MapEntry<String, List<TransactionDetails?>>(
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
      final String? count =
          await _secureStorage.read(key: _transactionCountKey);
      return count != null ? int.parse(count) : null;
    } catch (e) {
      throw Exception('Failed to retrieve transaction count: $e');
    }
  }
}
