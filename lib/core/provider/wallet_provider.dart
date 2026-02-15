import 'package:flutter/material.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/data/services/wallet_solana_service.dart';
import '../../features/wallet/data/services/wallet_storage_service.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../models/wallet_balances.dart';
import '../services/balance_cache_service.dart';
import '../services/transaction_parser_service.dart';

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

  final WalletStorageService _walletStorageService = WalletStorageService();
  WalletSolanaService? _walletSolanaService;
  final WalletRepository _walletRepository = WalletRepositoryImpl();
  late final BalanceCacheService _balanceCacheService;

  Future<WalletSolanaService> get _service async {
    _walletSolanaService ??= await WalletSolanaService.create();
    return _walletSolanaService!;
  }

  /// Builds a [ProgramAccount] from the stored ATA pubkey when the on-chain ATA is unavailable (e.g. mainnet derive-only).
  Future<ProgramAccount?> _programAccountFromStoredAta() async {
    final String? storedAtaPubkey = await _walletStorageService.retrieveAssociatedTokenAccountPublicKey();
    if (storedAtaPubkey == null || storedAtaPubkey.isEmpty) return null;
    return ProgramAccount(
      pubkey: storedAtaPubkey,
      account: Account(
        lamports: 0,
        owner: '',
        data: null,
        executable: false,
        rentEpoch: BigInt.zero,
      ),
    );
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
    _wallet = await _walletStorageService.retrieveWallet();

    if (_wallet == null) {
      _userTokenAccount = null;
      _zarpBalance = 0.0;
      _solBalance = 0.0;
      _isReady = true;
      notifyListeners();
      return false;
    }

    try {
      final WalletSolanaService service = await _service;
      _userTokenAccount = await service.getAssociatedTokenAccount(_wallet!.address);

      // Mainnet: ATA may only be derived (not created on-chain). Use stored ATA pubkey if present.
      _userTokenAccount ??= await _programAccountFromStoredAta();

      if (_userTokenAccount == null) {
        _zarpBalance = 0.0;
      } else {
        try {
          _zarpBalance = await service.getZarpBalance(_userTokenAccount!.pubkey);
        } catch (_) {
          _zarpBalance = 0.0;
        }
      }

      try {
        _solBalance = await service.getSolBalance(_wallet!.address);
      } catch (_) {
        _solBalance = 0.0;
      }

      _isReady = true;
      notifyListeners();
      return true;
    } catch (e) {
      // Wallet exists in storage; don't clear it. Use safe defaults so user can resume onboarding.
      _zarpBalance = 0.0;
      _solBalance = 0.0;
      _userTokenAccount ??= await _programAccountFromStoredAta();
      _isReady = true;
      notifyListeners();
      return true;
    }
  }

  Future<void> refreshTransactions() async {
    if (_wallet == null || _userTokenAccount == null) return;

    (_walletRepository as WalletRepositoryImpl).resetCancellation();

    final String? lastSignature = await _walletRepository.getLastTransactionSignature(
      walletAddress: _userTokenAccount!.pubkey,
    );

    await _walletRepository.getNewerTransactions(
      walletAddress: _userTokenAccount!.pubkey,
      lastKnownSignature: lastSignature,
      onBatchLoaded: (List<TransactionDetails?> batch) async {
        if (batch.isEmpty) {
          return Future<void>.value();
        }

        await _processAndStoreTransactions(batch);
      },
    );
  }

  Future<void> _processAndStoreTransactions(
    List<TransactionDetails?> batch,
  ) async {
    await _walletRepository.mergeAndStoreTransactions(
      batch,
      walletAddress: _userTokenAccount!.pubkey,
    );

    if (batch.isNotEmpty && batch.first != null) {
      final String? signature = TransactionDetailsParser.getFirstSignature(batch.first!);
      if (signature != null) {
        await _walletRepository.storeLastTransactionSignature(
          signature,
          walletAddress: _userTokenAccount!.pubkey,
        );
      }
    }
  }

  Future<void> fetchAndCacheBalances() async {
    if (_wallet == null || _userTokenAccount == null) return;

    try {
      final WalletBalances balances = await _balanceCacheService.getBothBalances(
        zarpAddress: _userTokenAccount!.pubkey,
        solAddress: _wallet!.address,
        forceRefresh: true,
      );
      _zarpBalance = balances.zarpBalance;
      _solBalance = balances.solBalance;
      notifyListeners();
    } catch (_) {
      // Account may not exist yet (e.g. unfunded mainnet wallet). Use 0 so login still succeeds.
      _zarpBalance = 0.0;
      _solBalance = 0.0;
      notifyListeners();
    }
  }

  Future<void> storeWallet(Wallet wallet) async {
    try {
      await _walletStorageService.saveWalletPrivateKey(wallet);
      await _walletStorageService.saveWalletPublicKey(wallet);
      _wallet = wallet;
      notifyListeners();
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> storeAssociatedTokenAccount(ProgramAccount tokenAccount) async {
    await _walletStorageService.saveAssociatedTokenAccountPublicKey(tokenAccount);
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
      final WalletBalances balances = await _balanceCacheService.getBothBalances(
        zarpAddress: _userTokenAccount!.pubkey,
        solAddress: _wallet!.address,
        forceRefresh: true,
      );
      _zarpBalance = balances.zarpBalance;
      _solBalance = balances.solBalance;
      notifyListeners();
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
