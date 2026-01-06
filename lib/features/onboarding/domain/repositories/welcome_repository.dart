import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

abstract class WelcomeRepository {
  Future<({String? recoveryPhrase, Wallet? wallet, ProgramAccount? tokenAccount, String? errorMessage})> createWallet();
  Future<void> storeWalletKeys({
    required Wallet wallet,
    required ProgramAccount tokenAccount,
  });
}
