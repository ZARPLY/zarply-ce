import 'package:flutter/material.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/data/services/wallet_solana_service.dart';
import '../../features/wallet/data/services/wallet_storage_service.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../services/balance_cache_service.dart';

class WalletProvider extends ChangeNotifier {
  WalletProvider() {
    _balanceCacheService = BalanceCacheService(
      walletRepository: _walletRepository,
    );
  }

  bool _isReady = false;
  bool get isReady => _isReady;

  bool _bootDone = false;
  bool get bootDone => _bootDone;

  void markBootDone() {
    if (_bootDone) return;
    _bootDone = true;
    notifyListeners();
  }

  void resetBootFlag() {
    if (!_bootDone) return;
    _bootDone = false;
    notifyListeners();
  }

  final WalletStorageService _walletStorageService = WalletStorageService();
  WalletSolanaService? _walletSolanaService;
  final WalletRepository _walletRepository = WalletRepositoryImpl();
  late final BalanceCacheService _balanceCacheService;

  Future<WalletSolanaService> get _service async {
    _walletSolanaService ??= await WalletSolanaService.create();
    return _walletSolanaService!;
  }

  Wallet? _wallet;
  ProgramAccount? _userTokenAccount;
  String? _recoveryPhrase;

  double _zarpBalance = 0;
  double _solBalance = 0;

  Wallet? get wallet => _wallet;

  ProgramAccount? get userTokenAccount => _userTokenAccount;

  bool get hasWallet => _wallet != null;

  String? get recoveryPhrase => _recoveryPhrase;

  bool get hasRecoveryPhrase => _recoveryPhrase != null;

  double get walletBalance => _zarpBalance;
  double get solBalance => _solBalance;

  void setRecoveryPhrase(String phrase) {
    _recoveryPhrase = phrase;
    notifyListeners();
  }

  void clearRecoveryPhrase() {
    _recoveryPhrase = null;
    notifyListeners();
  }

  Future<bool> initialize() async {
    print('DEBUG: WalletProvider.initialize() called');
    print('DEBUG: Current wallet in provider: ${_wallet?.address}');
    try {
      _wallet = await _walletStorageService.retrieveWallet();
      print('DEBUG: Retrieved wallet: ${_wallet?.address}');

      if (_wallet == null) {
        print('DEBUG: No wallet found, returning false');
        _userTokenAccount = null;
        _zarpBalance = 0.0;
        _solBalance = 0.0;
        _isReady = true;
        notifyListeners();
        return false;
      }

      final WalletSolanaService service = await _service;
      print('DEBUG: Got Solana service');
      
      _userTokenAccount =
          await service.getAssociatedTokenAccount(_wallet!.address);
      print('DEBUG: Associated token account: ${_userTokenAccount?.pubkey}');

      if (_userTokenAccount == null) {
        _zarpBalance = 0.0;
        print('DEBUG: No token account, setting balance to 0');
      } else {
        _zarpBalance = await service.getZarpBalance(_userTokenAccount!.pubkey);
        print('DEBUG: ZARP balance: $_zarpBalance');

        // Fetch limited transactions during initialization to pre-populate the list
        try {
          await fetchLimitedTransactions();
          print('DEBUG: Transactions fetched successfully');
        } catch (e) {
          print('DEBUG: Error fetching transactions: $e');
          // Don't fail initialization if transaction fetching fails
          // Transactions will be loaded when the wallet screen is opened
        }
      }
      _solBalance = await service.getSolBalance(_wallet!.address);
      print('DEBUG: SOL balance: $_solBalance');

      _isReady = true;
      print('DEBUG: Wallet initialization completed successfully');
      notifyListeners();
      return true;
    } catch (e) {
      print('DEBUG: Wallet initialization failed with error: $e');
      // Only reset if we don't have a wallet stored
      // This prevents clearing existing wallet data on network errors
      if (_wallet == null) {
        print('DEBUG: Resetting wallet provider');
        reset();
      } else {
        // If we have a wallet but initialization failed, just mark as ready
        // and keep existing data - the wallet screen can handle retrying
        print('DEBUG: Keeping existing wallet data, marking as ready');
        _isReady = true;
        notifyListeners();
      }
      return false;
    }
  }

  Future<void> fetchLimitedTransactions() async {
    if (_wallet == null || _userTokenAccount == null) {
      throw Exception(
        'WalletProvider: Cannot fetch transactions - wallet: ${_wallet != null}, tokenAccount: ${_userTokenAccount != null}',
      );
    }

    try {
      final String? lastSignature =
          await _walletRepository.getLastTransactionSignature();

      (_walletRepository as WalletRepositoryImpl).resetCancellation();
      final WalletSolanaService service = await _service;
      await service.getAccountTransactions(
        walletAddress: _userTokenAccount!.pubkey,
        until: lastSignature,
        limit: 10,
        onBatchLoaded: (List<TransactionDetails?> batch) {
          if (batch.isEmpty) {
            return;
          }

          _processAndStoreTransactions(batch);
        },
        isCancelled: () => _walletRepository.isCancelled,
      );
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> refreshTransactions() async {
    if (_wallet == null || _userTokenAccount == null) return;

    (_walletRepository as WalletRepositoryImpl).resetCancellation();

    try {
      final String? lastSignature =
          await _walletRepository.getLastTransactionSignature();

      await _walletRepository.getNewerTransactions(
        walletAddress: _userTokenAccount!.pubkey,
        lastKnownSignature: lastSignature,
        onBatchLoaded: (List<TransactionDetails?> batch) {
          if (batch.isEmpty) return;

          _processAndStoreTransactions(batch);
        },
      );
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> _processAndStoreTransactions(
    List<TransactionDetails?> batch,
  ) async {
    try {
      final Map<String, List<TransactionDetails?>> transactions =
          await _walletRepository.getStoredTransactions();

      for (final TransactionDetails? tx in batch) {
        if (tx == null) continue;

        final DateTime txDate = DateTime.fromMillisecondsSinceEpoch(
          tx.blockTime! * 1000,
        );
        final String monthKey =
            '${txDate.year}-${txDate.month.toString().padLeft(2, '0')}';

        if (!transactions.containsKey(monthKey)) {
          transactions[monthKey] = <TransactionDetails?>[];
        }
        transactions[monthKey]!.insert(0, tx);
      }

      await _walletRepository.storeTransactions(transactions);

      if (batch.isNotEmpty && batch.first != null) {
        final String signature =
            batch.first!.transaction.toJson()['signatures'][0];
        await _walletRepository.storeLastTransactionSignature(signature);
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> fetchAndCacheBalances() async {
    if (_wallet == null || _userTokenAccount == null) return;

    try {
      final ({double solBalance, double zarpBalance}) balances =
          await _balanceCacheService.getBothBalances(
        zarpAddress: _userTokenAccount!.pubkey,
        solAddress: _wallet!.address,
        forceRefresh: true,
      );
      _zarpBalance = balances.zarpBalance;
      _solBalance = balances.solBalance;
      notifyListeners();
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<void> storeWallet(Wallet wallet) async {
    print('DEBUG: storeWallet called with address: ${wallet.address}');
    try {
      await _walletStorageService.saveWalletPrivateKey(wallet);
      await _walletStorageService.saveWalletPublicKey(wallet);
      _wallet = wallet;
      print('DEBUG: Wallet stored in provider: ${_wallet?.address}');
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error storing wallet: $e');
      // Handle error
      rethrow;
    }
  }

  Future<void> storeAssociatedTokenAccount(ProgramAccount tokenAccount) async {
    await _walletStorageService
        .saveAssociatedTokenAccountPublicKey(tokenAccount);
    _userTokenAccount = tokenAccount;
    notifyListeners();
  }

  Future<void> deleteWallet() async {
    try {
      await _walletStorageService.deletePrivateKey();
      reset();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<bool> hasPassword() async {
    return _walletStorageService.hasPassword();
  }

  /// Refresh balances after a payment is completed
  Future<void> onPaymentCompleted() async {
    if (_wallet != null && _userTokenAccount != null) {
      try {
        final ({double solBalance, double zarpBalance}) balances =
            await _balanceCacheService.getBothBalances(
          zarpAddress: _userTokenAccount!.pubkey,
          solAddress: _wallet!.address,
          forceRefresh: true,
        );
        _zarpBalance = balances.zarpBalance;
        _solBalance = balances.solBalance;
        notifyListeners();
      } catch (e) {
        throw Exception(e);
      }
    }
  }

  void reset() {
    _wallet = null;
    _userTokenAccount = null;
    _recoveryPhrase = null;
    _zarpBalance = 0.0;
    _solBalance = 0.0;
    _isReady = false;
    _bootDone = false;
    notifyListeners();
  }
}
