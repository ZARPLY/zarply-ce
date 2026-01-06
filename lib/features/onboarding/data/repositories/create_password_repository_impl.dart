import '../../../../core/services/secure_storage_service.dart';
import '../../domain/repositories/create_password_repository.dart';

class CreatePasswordRepositoryImpl implements CreatePasswordRepository {
  CreatePasswordRepositoryImpl({SecureStorageService? secureStorage})
    : _secureStorage = secureStorage ?? SecureStorageService();
  final SecureStorageService _secureStorage;

  @override
  Future<bool> savePassword(String password) async {
    try {
      await _secureStorage.savePin(password);
      return true;
    } catch (e) {
      throw Exception('Error saving password: $e');
    }
  }
}
