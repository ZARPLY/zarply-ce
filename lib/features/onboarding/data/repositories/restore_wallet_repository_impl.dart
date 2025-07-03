import 'package:bip39/bip39.dart' as bip39;
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../../../wallet/data/services/wallet_solana_service.dart';
import '../../../wallet/data/services/wallet_storage_service.dart';
import '../../domain/repositories/restore_wallet_repository.dart';

class RestoreWalletRepositoryImpl implements RestoreWalletRepository {
  RestoreWalletRepositoryImpl({
    WalletSolanaService? walletService,
    WalletStorageService? storageService,
  })  : _walletService = walletService,
        _storageService = storageService ?? WalletStorageService();

  final WalletSolanaService? _walletService;
  final WalletStorageService _storageService;

  Future<WalletSolanaService> get _service async {
    return _walletService ?? await WalletSolanaService.create();
  }

  @override
  bool isValidMnemonic(String mnemonic) {
    // Use BIP39 validation directly - this doesn't require RPC connection
    return bip39.validateMnemonic(mnemonic);
  }

  @override
  bool isValidPrivateKey(String privateKey) {
    // Basic validation - this doesn't require RPC connection
    return privateKey.length == 64;
  }

  @override
  Future<Wallet> restoreWalletFromMnemonic(String mnemonic) async {
    final WalletSolanaService service = await _service;
    return service.restoreWalletFromMnemonic(mnemonic);
  }

  @override
  Future<Wallet> restoreWalletFromPrivateKey(String privateKey) async {
    final WalletSolanaService service = await _service;
    return service.restoreWalletFromPrivateKey(privateKey);
  }

  @override
  Future<void> storeWallet(Wallet wallet, WalletProvider walletProvider) async {
    await walletProvider.storeWallet(wallet);
    await _storageService.saveWalletPrivateKey(wallet);
    await _storageService.saveWalletPublicKey(wallet);
  }

  @override
  Future<void> restoreAssociatedTokenAccount(
    Wallet wallet,
    WalletProvider walletProvider,
  ) async {
    try {
      final WalletSolanaService service = await _service;
      final ProgramAccount? tokenAccount =
          await service.getAssociatedTokenAccount(wallet.address);
      if (tokenAccount == null) return;
      await walletProvider.storeAssociatedTokenAccount(tokenAccount);
    } catch (e) {
      throw WalletStorageException(
        'Failed to restore associated token account: $e',
      );
    }
  }
}

class WalletStorageException implements Exception {
  WalletStorageException(this.message);
  final String message;

  @override
  String toString() => message;
}
