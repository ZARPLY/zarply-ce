import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/foundation.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../wallet/data/services/wallet_solana_service.dart';
import '../../../wallet/data/services/wallet_storage_service.dart';
import '../../domain/repositories/welcome_repository.dart';

class WelcomeRepositoryImpl implements WelcomeRepository {
  WelcomeRepositoryImpl({
    WalletSolanaService? walletService,
    WalletStorageService? storageService,
  }) : _walletService = walletService,
       _storageService = storageService ?? WalletStorageService();

  final WalletSolanaService? _walletService;
  final WalletStorageService _storageService;
  final SecureStorageService _secureStorage = SecureStorageService();

  Future<WalletSolanaService> get _service async {
    return _walletService ?? await WalletSolanaService.create();
  }

  @override
  Future<({String? recoveryPhrase, Wallet? wallet, ProgramAccount? tokenAccount, String? errorMessage})>
  createWallet() async {
    try {
      final WalletSolanaService service = await _service;
      final String recoveryPhrase = bip39.generateMnemonic();
      await _secureStorage.saveRecoveryPhrase(recoveryPhrase);
      final Wallet wallet = await service.createWalletFromMnemonic(recoveryPhrase);
      ProgramAccount? tokenAccount;

      if (WalletSolanaService.isFaucetEnabled) {
        // Non-mainnet (e.g. devnet/QA): fund via faucet and create ATA immediately
        await Future<void>.delayed(const Duration(seconds: 20));
        tokenAccount = await service.createAssociatedTokenAccount(wallet);
        await service.requestZARP(wallet);
      } else {
        // Mainnet/prod: skip ATA creation and faucet-based ZARP funding.
        // The associated token account can be created later once the wallet
        // has been funded with SOL.
        tokenAccount = null;
      }

      return (
        recoveryPhrase: recoveryPhrase,
        wallet: wallet,
        tokenAccount: tokenAccount,
        errorMessage: null,
      );
    } catch (e, stackTrace) {
      debugPrint('[WelcomeRepo] createWallet failed: $e');
      debugPrint('[WelcomeRepo] StackTrace: $stackTrace');
      final String message = e.toString();
      return (
        recoveryPhrase: null,
        wallet: null,
        tokenAccount: null,
        errorMessage: 'Could not create wallet. Please try again later. $message',
      );
    }
  }

  @override
  Future<void> storeWalletKeys({
    required Wallet wallet,
    required ProgramAccount? tokenAccount,
  }) async {
    await _storageService.saveWalletPrivateKey(wallet);
    await _storageService.saveWalletPublicKey(wallet);
    await _storageService.saveAssociatedTokenAccountPublicKey(tokenAccount);
  }
}
