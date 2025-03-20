abstract class PrivateKeysRepository {
  Future<String?> getWalletPrivateKey();
  Future<String?> getTokenAccountPublicKey();
  Future<void> copyKeysToClipboard(String walletKey, String tokenKey);
}
