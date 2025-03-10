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
}
