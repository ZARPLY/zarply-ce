import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  })  : _walletService = walletService ??
            WalletSolanaService(
              rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
              websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
            ),
        _storageService = storageService ?? WalletStorageService();

  final WalletSolanaService _walletService;
  final WalletStorageService _storageService;

  @override
  bool isValidMnemonic(String mnemonic) {
    return _walletService.isValidMnemonic(mnemonic);
  }

  @override
  bool isValidPrivateKey(String privateKey) {
    return _walletService.isValidPrivateKey(privateKey);
  }

  @override
  Future<Wallet> restoreWalletFromMnemonic(String mnemonic) {
    return _walletService.restoreWalletFromMnemonic(mnemonic);
  }

  @override
  Future<Wallet> restoreWalletFromPrivateKey(String privateKey) {
    return _walletService.restoreWalletFromPrivateKey(privateKey);
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
      final ProgramAccount? tokenAccount =
          await _walletService.getAssociatedTokenAccount(wallet.address);
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
