import 'package:solana/solana.dart';

import '../../../../core/provider/wallet_provider.dart';

abstract class RestoreWalletRepository {
  /// Validates if the provided mnemonic phrase is valid
  bool isValidMnemonic(String mnemonic);

  /// Validates if the provided private key is valid
  bool isValidPrivateKey(String privateKey);

  /// Restores a wallet from a mnemonic phrase
  Future<Wallet> restoreWalletFromMnemonic(String mnemonic);

  /// Restores a wallet from a private key
  Future<Wallet> restoreWalletFromPrivateKey(String privateKey);

  /// Stores the wallet in the provider and local storage
  Future<void> storeWallet(Wallet wallet, WalletProvider walletProvider);

  /// Gets and stores the associated token account for a wallet
  Future<void> restoreAssociatedTokenAccount(
    Wallet wallet,
    WalletProvider walletProvider,
  );
}
