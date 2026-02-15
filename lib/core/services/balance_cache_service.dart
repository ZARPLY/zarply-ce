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

  /// How long a cached ZARP or SOL balance is considered fresh before refetching (used by getZarpBalance and getSolBalance).
  static const Duration _balanceCacheExpiry = Duration(minutes: 5);

  /// Shared implementation for getZarpBalance and getSolBalance: returns the balance from cache if fresh, otherwise fetches from network, saves to cache, and returns.
  Future<double> _getCachedBalance({
    required Future<double?> Function() readCachedBalance,
    required Future<DateTime?> Function() getCachedBalanceTimestamp,
    required Future<double> Function() fetchFreshBalance,
    required Future<void> Function(double) saveBalanceToCache,
    bool bypassCache = false,
  }) async {
    try {
      if (!bypassCache) {
        final double? cachedBalance = await readCachedBalance();
        final DateTime? cacheTime = await getCachedBalanceTimestamp();

        if (cachedBalance != null && cacheTime != null) {
          final bool isCacheFresh = DateTime.now().difference(cacheTime) < _balanceCacheExpiry;
          if (isCacheFresh) {
            return cachedBalance;
          }
        }
      }

      if (_walletRepository == null) {
        throw Exception('WalletRepository not available for balance fetching');
      }

      final double freshBalance = await fetchFreshBalance();
      await saveBalanceToCache(freshBalance);
      return freshBalance;
    } catch (e) {
      final double? cachedBalance = await readCachedBalance();
      if (cachedBalance != null) {
        return cachedBalance;
      }
      rethrow;
    }
  }

  /// Get ZARP balance, using cache if available and fresh, otherwise fetch from network
  Future<double> getZarpBalance(
    String address, {
    bool forceRefresh = false,
  }) async {
    return _getCachedBalance(
      readCachedBalance: _secureStorageService.getCachedZarpBalance,
      getCachedBalanceTimestamp: _secureStorageService.getZarpBalanceTimestamp,
      fetchFreshBalance: () => _walletRepository!.getZarpBalance(address),
      saveBalanceToCache: _secureStorageService.saveZarpBalance,
      bypassCache: forceRefresh,
    );
  }

  /// Get SOL balance
  Future<double> getSolBalance(
    String address, {
    bool forceRefresh = false,
  }) async {
    return _getCachedBalance(
      readCachedBalance: _secureStorageService.getCachedSolBalance,
      getCachedBalanceTimestamp: _secureStorageService.getSolBalanceTimestamp,
      fetchFreshBalance: () => _walletRepository!.getSolBalance(address),
      saveBalanceToCache: _secureStorageService.saveSolBalance,
      bypassCache: forceRefresh,
    );
  }

  Future<WalletBalances> getBothBalances({
    required String zarpAddress,
    required String solAddress,
    bool forceRefresh = false,
  }) async {
    final List<double> balances = await Future.wait(<Future<double>>[
      getZarpBalance(zarpAddress, forceRefresh: forceRefresh),
      getSolBalance(solAddress, forceRefresh: forceRefresh),
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
