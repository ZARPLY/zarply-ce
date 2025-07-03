import '../../features/wallet/domain/repositories/wallet_repository.dart';
import 'secure_storage_service.dart';

class BalanceCacheService {
  BalanceCacheService({
    SecureStorageService? secureStorageService,
    WalletRepository? walletRepository,
  })  : _secureStorageService = secureStorageService ?? SecureStorageService(),
        _walletRepository = walletRepository;

  final SecureStorageService _secureStorageService;
  final WalletRepository? _walletRepository;

  /// Cache expiry duration - balances are considered fresh for 5 minutes
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Get ZARP balance, using cache if available and fresh, otherwise fetch from network
  Future<double> getZarpBalance(
    String address, {
    bool forceRefresh = false,
  }) async {
    try {
      // If force refresh is requested, skip cache
      if (!forceRefresh) {
        final double? cachedBalance =
            await _secureStorageService.getCachedZarpBalance();
        final DateTime? cacheTime =
            await _secureStorageService.getZarpBalanceTimestamp();

        if (cachedBalance != null && cacheTime != null) {
          final bool isCacheFresh =
              DateTime.now().difference(cacheTime) < _cacheExpiry;
          if (isCacheFresh) {
            return cachedBalance;
          }
        }
      }

      // Cache is stale or doesn't exist, fetch from network
      if (_walletRepository == null) {
        throw Exception('WalletRepository not available for balance fetching');
      }

      final double freshBalance =
          await _walletRepository.getZarpBalance(address);

      await _secureStorageService.saveZarpBalance(freshBalance);

      return freshBalance;
    } catch (e) {
      final double? cachedBalance =
          await _secureStorageService.getCachedZarpBalance();
      if (cachedBalance != null) {
        return cachedBalance;
      }
      rethrow;
    }
  }

  Future<double> getSolBalance(
    String address, {
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final double? cachedBalance =
            await _secureStorageService.getCachedSolBalance();
        final DateTime? cacheTime =
            await _secureStorageService.getSolBalanceTimestamp();

        if (cachedBalance != null && cacheTime != null) {
          final bool isCacheFresh =
              DateTime.now().difference(cacheTime) < _cacheExpiry;
          if (isCacheFresh) {
            return cachedBalance;
          }
        }
      }

      if (_walletRepository == null) {
        throw Exception('WalletRepository not available for balance fetching');
      }

      final double freshBalance =
          await _walletRepository.getSolBalance(address);

      await _secureStorageService.saveSolBalance(freshBalance);

      return freshBalance;
    } catch (e) {
      final double? cachedBalance =
          await _secureStorageService.getCachedSolBalance();
      if (cachedBalance != null) {
        return cachedBalance;
      }
      rethrow;
    }
  }

  Future<({double zarpBalance, double solBalance})> getBothBalances({
    required String zarpAddress,
    required String solAddress,
    bool forceRefresh = false,
  }) async {
    final List<double> balances = await Future.wait(<Future<double>>[
      getZarpBalance(zarpAddress, forceRefresh: forceRefresh),
      getSolBalance(solAddress, forceRefresh: forceRefresh),
    ]);

    return (zarpBalance: balances[0], solBalance: balances[1]);
  }

  Future<({double zarpBalance, double solBalance})> refreshBalances({
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

    final double zarpBalance = balances[0];
    final double solBalance = balances[1];

    await _secureStorageService.saveBalances(
      zarpBalance: zarpBalance,
      solBalance: solBalance,
    );

    return (zarpBalance: zarpBalance, solBalance: solBalance);
  }

  Future<void> clearCache() async {
    await _secureStorageService.clearCachedBalances();
  }

  /// Check if cached balances are fresh
  Future<bool> areCachedBalancesFresh() async {
    final DateTime? zarpTime =
        await _secureStorageService.getZarpBalanceTimestamp();
    final DateTime? solTime =
        await _secureStorageService.getSolBalanceTimestamp();

    if (zarpTime == null || solTime == null) return false;

    final DateTime now = DateTime.now();
    final bool zarpFresh = now.difference(zarpTime) < _cacheExpiry;
    final bool solFresh = now.difference(solTime) < _cacheExpiry;

    return zarpFresh && solFresh;
  }

  /// Get cache age for debugging purposes
  Future<String> getCacheAgeInfo() async {
    final DateTime? zarpTime =
        await _secureStorageService.getZarpBalanceTimestamp();
    final DateTime? solTime =
        await _secureStorageService.getSolBalanceTimestamp();

    if (zarpTime == null || solTime == null) {
      return 'No cached balances';
    }

    final DateTime now = DateTime.now();
    final Duration zarpAge = now.difference(zarpTime);
    final Duration solAge = now.difference(solTime);

    return 'ZARP: ${zarpAge.inMinutes}m ago, SOL: ${solAge.inMinutes}m ago';
  }

  Future<void> updateZarpBalance(double newBalance) async {
    await _secureStorageService.saveZarpBalance(newBalance);
  }
}
