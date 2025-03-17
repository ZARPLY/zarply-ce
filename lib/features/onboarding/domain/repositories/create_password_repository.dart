abstract class CreatePasswordRepository {
  /// Returns true if the password was saved successfully, false otherwise
  Future<bool> savePassword(String password);
}
