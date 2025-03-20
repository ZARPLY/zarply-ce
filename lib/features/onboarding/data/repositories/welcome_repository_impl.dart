import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../wallet/data/services/wallet_solana_service.dart';
import '../../../wallet/data/services/wallet_storage_service.dart';
import '../../domain/repositories/welcome_repository.dart';

class WelcomeRepositoryImpl implements WelcomeRepository {
  WelcomeRepositoryImpl({
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
  Future<({String recoveryPhrase, Wallet wallet, ProgramAccount tokenAccount})>
      createWallet() async {
    final String recoveryPhrase = bip39.generateMnemonic();
    final Wallet wallet =
        await _walletService.createWalletFromMnemonic(recoveryPhrase);
    await Future<void>.delayed(const Duration(seconds: 2));
    final ProgramAccount tokenAccount =
        await _walletService.createAssociatedTokenAccount(wallet);

    return (
      recoveryPhrase: recoveryPhrase,
      wallet: wallet,
      tokenAccount: tokenAccount,
    );
  }

  @override
  Future<void> storeWalletKeys({
    required Wallet wallet,
    required ProgramAccount tokenAccount,
  }) async {
    await _storageService.saveWalletPrivateKey(wallet);
    await _storageService.saveWalletPublicKey(wallet);
    await _storageService.saveAssociatedTokenAccountPublicKey(tokenAccount);
  }
}
