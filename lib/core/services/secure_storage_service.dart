import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageException implements Exception {
  SecureStorageException(this.message);
  final String message;

  @override
  String toString() => 'SecureStorageException: $message';
}

class SecureStorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> savePin(String pin) async {
    try {
      if (pin.isEmpty) {
        throw SecureStorageException('PIN cannot be empty.');
      }
      await _secureStorage.write(key: 'user_pin', value: pin);
    } catch (e) {
      throw SecureStorageException('Failed to save PIN: $e');
    }
  }

  Future<String> getPin() async {
    try {
      final String? pin = await _secureStorage.read(key: 'user_pin');
      if (pin == null) {
        throw SecureStorageException('No PIN found.');
      }
      return pin;
    } catch (e) {
      throw SecureStorageException('Failed to retrieve PIN: $e');
    }
  }

  Future<void> deletePin() async {
    try {
      final bool exists = await _secureStorage.containsKey(key: 'user_pin');
      if (!exists) {
        throw SecureStorageException('No PIN to delete.');
      }
      await _secureStorage.delete(key: 'user_pin');
    } catch (e) {
      throw SecureStorageException('Failed to delete PIN: $e');
    }
  }

  Future<void> setRememberPassword({required bool value}) async {
    try {
      await _secureStorage.write(
        key: 'remember_password',
        value: value.toString(),
      );
    } catch (e) {
      throw SecureStorageException(
        'Failed to save remember password preference: $e',
      );
    }
  }

  Future<bool> getRememberPassword() async {
    try {
      final String? value = await _secureStorage.read(key: 'remember_password');
      return value == 'true';
    } catch (e) {
      return false;
    }
  }

  Future<void> saveZarpBalance(double balance) async {
    try {
      await _secureStorage.write(
        key: 'cached_zarp_balance',
        value: balance.toString(),
      );
      await _secureStorage.write(
        key: 'zarp_balance_timestamp',
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } catch (e) {
      throw SecureStorageException('Failed to save ZARP balance: $e');
    }
  }

  Future<double?> getCachedZarpBalance() async {
    try {
      final String? balanceStr =
          await _secureStorage.read(key: 'cached_zarp_balance');
      if (balanceStr == null) return null;

      return double.tryParse(balanceStr);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveSolBalance(double balance) async {
    try {
      await _secureStorage.write(
        key: 'cached_sol_balance',
        value: balance.toString(),
      );
      await _secureStorage.write(
        key: 'sol_balance_timestamp',
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } catch (e) {
      throw SecureStorageException('Failed to save SOL balance: $e');
    }
  }

  Future<double?> getCachedSolBalance() async {
    try {
      final String? balanceStr =
          await _secureStorage.read(key: 'cached_sol_balance');
      if (balanceStr == null) return null;

      return double.tryParse(balanceStr);
    } catch (e) {
      return null;
    }
  }

  Future<DateTime?> getZarpBalanceTimestamp() async {
    try {
      final String? timestampStr =
          await _secureStorage.read(key: 'zarp_balance_timestamp');
      if (timestampStr == null) return null;

      final int? timestamp = int.tryParse(timestampStr);
      if (timestamp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }

  Future<DateTime?> getSolBalanceTimestamp() async {
    try {
      final String? timestampStr =
          await _secureStorage.read(key: 'sol_balance_timestamp');
      if (timestampStr == null) return null;

      final int? timestamp = int.tryParse(timestampStr);
      if (timestamp == null) return null;

      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCachedBalances() async {
    try {
      await Future.wait(<Future<void>>[
        _secureStorage.delete(key: 'cached_zarp_balance'),
        _secureStorage.delete(key: 'cached_sol_balance'),
        _secureStorage.delete(key: 'zarp_balance_timestamp'),
        _secureStorage.delete(key: 'sol_balance_timestamp'),
      ]);
    } catch (e) {
      throw SecureStorageException('Failed to clear cached balances: $e');
    }
  }

  Future<void> saveBalances({
    required double zarpBalance,
    required double solBalance,
  }) async {
    try {
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      await Future.wait(<Future<void>>[
        _secureStorage.write(
          key: 'cached_zarp_balance',
          value: zarpBalance.toString(),
        ),
        _secureStorage.write(
          key: 'cached_sol_balance',
          value: solBalance.toString(),
        ),
        _secureStorage.write(key: 'zarp_balance_timestamp', value: timestamp),
        _secureStorage.write(key: 'sol_balance_timestamp', value: timestamp),
      ]);
    } catch (e) {
      throw SecureStorageException('Failed to save balances: $e');
    }
  }
}
