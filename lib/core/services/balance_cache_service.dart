import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../models/wallet_balances.dart';
import 'secure_storage_service.dart';

class BalanceCacheService {
  BalanceCacheService({
    SecureStorageService? secureStorageService,
    WalletRepository? walletRepository,
  }) : _secureStorageService = secureStorageService ?? SecureStorageService(),
       _walletRepository = walletRepository;

  final SecureStorageService _secureStorageService;
  final WalletRepository? _walletRepository;

  /// Get ZARP balance from the network.
  Future<double> getZarpBalance(String address) async {
    if (_walletRepository == null) {
      throw Exception('WalletRepository not available for balance fetching');
    }
    return _walletRepository.getZarpBalance(address);
  }

  /// Get SOL balance from the network.
  Future<double> getSolBalance(String address) async {
    if (_walletRepository == null) {
      throw Exception('WalletRepository not available for balance fetching');
    }
    return _walletRepository.getSolBalance(address);
  }

  Future<WalletBalances> getBothBalances({
    required String zarpAddress,
    required String solAddress,
  }) async {
    final List<double> balances = await Future.wait(<Future<double>>[
      getZarpBalance(zarpAddress),
      getSolBalance(solAddress),
    ]);

    return WalletBalances(zarpBalance: balances[0], solBalance: balances[1]);
  }

  Future<WalletBalances> refreshBalances({
    required String zarpAddress,
    required String solAddress,
  }) async {
    if (_walletRepository == null) {
      throw Exception('WalletRepository not available for balance fetching');
    }

    final List<double> balances = await Future.wait(<Future<double>>[
      _walletRepository.getZarpBalance(zarpAddress),
      _walletRepository.getSolBalance(solAddress),
    ]);

    final WalletBalances result = WalletBalances(
      zarpBalance: balances[0],
      solBalance: balances[1],
    );
    await _secureStorageService.saveBalances(
      zarpBalance: result.zarpBalance,
      solBalance: result.solBalance,
    );

    return result;
  }

  Future<void> updateZarpBalance(double newBalance) async {
    await _secureStorageService.saveZarpBalance(newBalance);
  }
}
