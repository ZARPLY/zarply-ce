import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:solana/base58.dart';
import 'package:solana/dto.dart' hide Instruction;
import 'package:solana/encoder.dart';
import 'package:solana/solana.dart';

import '../../../../core/models/wallet_balances.dart';
import '../../../../core/services/rpc_rate_limiter.dart';
import '../../../../core/services/rpc_service.dart';
import '../../../../core/services/transaction_storage_service.dart';
import '../../../../core/utils/formatters.dart';

class WalletSolanaServiceException implements Exception {
  WalletSolanaServiceException(this.message);
  final String message;

  @override
  String toString() => 'SolanaConnectionException: $message';
}

class WalletSolanaService {
  // Keep the old constructor for backward compatibility in tests
  WalletSolanaService({
    required String rpcUrl,
    required String websocketUrl,
  }) : _client = SolanaClient(
         rpcUrl: Uri.parse(rpcUrl),
         websocketUrl: Uri.parse(websocketUrl),
       );

  WalletSolanaService._({
    required String rpcUrl,
    required String websocketUrl,
  }) : _client = SolanaClient(
         rpcUrl: Uri.parse(rpcUrl),
         websocketUrl: Uri.parse(websocketUrl),
       );

  static Future<WalletSolanaService> create() async {
    final RpcService rpcService = RpcService();
    final ({String rpcUrl, String websocketUrl}) config = await rpcService.getRpcConfiguration();
    return WalletSolanaService._(rpcUrl: config.rpcUrl, websocketUrl: config.websocketUrl);
  }

  final SolanaClient _client;
  final TransactionStorageService _transactionStorageService = TransactionStorageService();

  static final String zarpMint = dotenv.env['ZARP_MINT_ADDRESS'] ?? '';
  static final String legacyZarpMint = dotenv.env['ZARP_MINT_ADDRESS_LEGACY'] ?? '';
  static final String migrationWallet = dotenv.env['ZARP_MIGRATION_WALLET_ADDRESS'] ?? '';
  static const int zarpDecimalFactor = 1000000000;

  // ── Balance cache ─────────────────────────────────────────────────────────
  static const Duration _balanceCacheTtl = Duration(seconds: 30);
  final Map<String, ({double balance, DateTime fetchedAt})> _solBalanceCache =
      <String, ({double balance, DateTime fetchedAt})>{};
  final Map<String, ({double balance, DateTime fetchedAt})> _zarpBalanceCache =
      <String, ({double balance, DateTime fetchedAt})>{};

  /// Invalidate cached balances for [publicKey] — call after sending a transaction.
  void invalidateBalanceCache(String publicKey) {
    _solBalanceCache.remove(publicKey);
    _zarpBalanceCache.remove(publicKey);
  }

  // ── Mainnet / faucet detection ────────────────────────────────────────────

  static bool get _isFaucetEnabled {
    final String? rpcUrl = dotenv.env['solana_wallet_rpc_url'];
    if (rpcUrl == null) return true;
    return !rpcUrl.contains('mainnet');
  }

  /// True when RPC is mainnet (no faucet, no on-chain ATA creation at wallet creation).
  bool get isMainnet => !_isFaucetEnabled;

  // ── Core RPC wrapper ──────────────────────────────────────────────────────

  /// Wraps RPC calls with rate limiting, per-method tracking, and error handling.
  /// [method] must match the Solana RPC method name for accurate per-method throttling.
  Future<T> _wrapRpcCall<T>(
    String operation,
    Future<T> Function() call, {
    String method = 'unknown',
  }) async {
    try {
      return await RpcRateLimiter.instance.run(call, method: method);
    } on RpcRateLimitException {
      rethrow;
    } catch (e) {
      throw WalletSolanaServiceException('$operation: $e');
    }
  }

  // ── Transaction fetch helpers ─────────────────────────────────────────────

  /// Fetches a single transaction with retry. Returns null if all retries fail.
  Future<TransactionDetails?> _fetchWithRetry(
    String signature, {
    required int maxRetries,
    required Duration delay,
    bool Function()? isCancelled,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      if (isCancelled?.call() ?? false) return null;
      try {
        return await RpcRateLimiter.instance.run(
          () => _client.rpcClient.getTransaction(signature, commitment: Commitment.confirmed),
          method: 'getTransaction',
        );
      } catch (e) {
        if (attempt < maxRetries) {
          await Future<void>.delayed(delay);
        }
      }
    }
    return null;
  }

  /// Fetches transactions sequentially in chunks to avoid RPC burst.
  /// Sequential (not parallel) so the rate limiter spaces each call correctly.
  Future<void> _fetchTransactionsWithCircuitBreaker(
    List<String> signatures, {
    required Future<void> Function(List<TransactionDetails?>) onBatchLoaded,
    bool Function()? isCancelled,
  }) async {
    const int chunkSize = 5;
    const int maxRetries = 2;
    const Duration retryDelay = Duration(milliseconds: 500);

    try {
      for (int i = 0; i < signatures.length; i += chunkSize) {
        if (isCancelled?.call() ?? false) return;

        final List<String> chunk = signatures.sublist(i, math.min(i + chunkSize, signatures.length));

        // Sequential fetch — avoids bursting multiple parallel requests per chunk
        final List<TransactionDetails?> results = <TransactionDetails?>[];
        for (final String sig in chunk) {
          if (isCancelled?.call() ?? false) return;
          results.add(await _fetchWithRetry(sig, maxRetries: maxRetries, delay: retryDelay, isCancelled: isCancelled));
        }

        if (isCancelled?.call() ?? false) return;
        await onBatchLoaded(results);
      }
    } catch (e) {
      throw WalletSolanaServiceException('Error in transaction processing: $e');
    }
  }

  // ── Token instruction helper ──────────────────────────────────────────────

  Future<String> _sendTokenInstruction({
    required Wallet wallet,
    required String sourcePubkey,
    required String destPubkey,
    required int amount,
    required TokenProgramType tokenProgram,
  }) async {
    final TokenInstruction instruction = TokenInstruction.transfer(
      source: Ed25519HDPublicKey.fromBase58(sourcePubkey),
      destination: Ed25519HDPublicKey.fromBase58(destPubkey),
      owner: wallet.publicKey,
      amount: amount,
      tokenProgram: tokenProgram,
    );

    final Message message = Message(instructions: <Instruction>[instruction]);

    final LatestBlockhash bh = await RpcRateLimiter.instance.run(
      () => _client.rpcClient.getLatestBlockhash(commitment: Commitment.confirmed).value,
      method: 'getLatestBlockhash',
    );

    final SignedTx signedTx = await signTransaction(bh, message, <Ed25519HDKeyPair>[wallet]);

    return RpcRateLimiter.instance.run(
      () => _client.rpcClient.sendTransaction(signedTx.encode(), preflightCommitment: Commitment.confirmed),
      method: 'sendTransaction',
    );
  }

  // ── Wallet creation / restore ─────────────────────────────────────────────

  /// Derives the ZARP ATA address (PDA) without creating it on-chain.
  /// Used on mainnet where the wallet starts unfunded.
  Future<ProgramAccount> deriveAssociatedTokenAddress(Wallet wallet) async {
    final Ed25519HDPublicKey ataKey = await findAssociatedTokenAddress(
      owner: wallet.publicKey,
      mint: Ed25519HDPublicKey.fromBase58(zarpMint),
      tokenProgramType: TokenProgramType.token2022Program,
    );
    return ProgramAccount(
      pubkey: ataKey.toBase58(),
      account: Account(lamports: 0, owner: '', data: null, executable: false, rentEpoch: BigInt.zero),
    );
  }

  Future<Wallet> createWallet() async {
    try {
      final Ed25519HDKeyPair wallet = await Wallet.random();
      if (zarpMint.isEmpty) {
        throw WalletSolanaServiceException('ZARP_MINT_ADDRESS is not configured in .env file');
      }
      if (_isFaucetEnabled) {
        await _requestSOL(wallet);
      }
      return wallet;
    } catch (e) {
      throw WalletSolanaServiceException('Failed to create wallet: $e');
    }
  }

  Future<Wallet> createWalletFromMnemonic(String mnemonic) async {
    final Ed25519HDKeyPair wallet = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
    if (zarpMint.isEmpty) {
      throw WalletSolanaServiceException('ZARP_MINT_ADDRESS is not configured in .env file');
    }
    if (_isFaucetEnabled) {
      try {
        await _requestSOL(wallet);
      } catch (e) {
        // SOL faucet request failed; continue without SOL
      }
    }
    return wallet;
  }

  Future<ProgramAccount> createAssociatedTokenAccount(Wallet wallet) async {
    return RpcRateLimiter.instance.run(
      () => _client.createAssociatedTokenAccount(
        owner: wallet.publicKey,
        mint: Ed25519HDPublicKey.fromBase58(zarpMint),
        funder: wallet,
        tokenProgramType: TokenProgramType.token2022Program,
        commitment: Commitment.confirmed,
      ),
      method: 'sendTransaction',
    );
  }

  Future<ProgramAccount?> getAssociatedTokenAccount(String walletAddress) => _wrapRpcCall(
    'Could not get associated token account for address',
    () => _client.getAssociatedTokenAccount(
      owner: Ed25519HDPublicKey.fromBase58(walletAddress),
      mint: Ed25519HDPublicKey.fromBase58(zarpMint),
      commitment: Commitment.confirmed,
    ),
    method: 'getTokenAccountsByOwner',
  );

  Future<Wallet> restoreWalletFromMnemonic(String mnemonic) async {
    try {
      if (!isValidMnemonic(mnemonic)) {
        throw WalletSolanaServiceException('Invalid mnemonic phrase');
      }
      return await Ed25519HDKeyPair.fromMnemonic(mnemonic);
    } catch (e) {
      throw WalletSolanaServiceException('Failed to restore wallet: $e');
    }
  }

  Future<Wallet> restoreWalletFromPrivateKey(String privateKey) async {
    try {
      if (privateKey.isEmpty) {
        throw WalletSolanaServiceException('Private key is empty');
      }
      return await Ed25519HDKeyPair.fromPrivateKeyBytes(privateKey: base58decode(privateKey));
    } catch (e) {
      throw WalletSolanaServiceException('Failed to restore wallet: $e');
    }
  }

  // ── Balance ───────────────────────────────────────────────────────────────

  Future<double> getSolBalance(String publicKey, {bool forceRefresh = false}) async {
    final DateTime now = DateTime.now();
    final ({double balance, DateTime fetchedAt})? cached = _solBalanceCache[publicKey];

    if (!forceRefresh && cached != null && now.difference(cached.fetchedAt) < _balanceCacheTtl) {
      return cached.balance;
    }

    final double balance = await _wrapRpcCall(
      'Could not retrieve SOL balance',
      () async {
        final BalanceResult lamports = await _client.rpcClient.getBalance(publicKey, commitment: Commitment.confirmed);
        return lamports.value.toDouble() / lamportsPerSol;
      },
      method: 'getBalance',
    );

    _solBalanceCache[publicKey] = (balance: balance, fetchedAt: now);
    return balance;
  }

  Future<double> getZarpBalance(String publicKey, {bool forceRefresh = false}) async {
    final DateTime now = DateTime.now();
    final ({double balance, DateTime fetchedAt})? cached = _zarpBalanceCache[publicKey];

    if (!forceRefresh && cached != null && now.difference(cached.fetchedAt) < _balanceCacheTtl) {
      return cached.balance;
    }

    try {
      final double balance = await _wrapRpcCall(
        'Could not retrieve ZARP balance',
        () async {
          final TokenAmountResult result = await _client.rpcClient.getTokenAccountBalance(
            publicKey,
            commitment: Commitment.confirmed,
          );
          final String? uiAmountString = result.value.uiAmountString;
          if (uiAmountString != null) return double.parse(uiAmountString);
          return double.parse(result.value.amount) / zarpDecimalFactor;
        },
        method: 'getTokenAccountBalance',
      );

      _zarpBalanceCache[publicKey] = (balance: balance, fetchedAt: now);
      return balance;
    } on WalletSolanaServiceException {
      // ATA not created on-chain yet (e.g. mainnet new wallet) — treat as 0.
      _zarpBalanceCache[publicKey] = (balance: 0.0, fetchedAt: now);
      return 0.0;
    }
  }

  /// Raw balance result for precise checks (e.g. before sending).
  /// Bypasses cache intentionally — always fresh for transaction validation.
  Future<TokenAmountResult> getTokenAccountBalanceRaw(String publicKey) => _wrapRpcCall(
    'Could not retrieve raw token account balance',
    () => _client.rpcClient.getTokenAccountBalance(publicKey, commitment: Commitment.confirmed),
    method: 'getTokenAccountBalance',
  );

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<String> sendTransaction({
    required Wallet senderWallet,
    required ProgramAccount? senderTokenAccount,
    required ProgramAccount? recipientTokenAccount,
    required double zarpAmount,
  }) async {
    try {
      final double solBalance = await getSolBalance(senderWallet.address, forceRefresh: true);
      if (solBalance < WalletBalances.minSolForFees) {
        throw WalletSolanaServiceException(
          'Insufficient SOL balance for transaction fees. Need at least ${WalletBalances.minSolForFees} SOL',
        );
      }

      if (senderTokenAccount == null || recipientTokenAccount == null) {
        throw WalletSolanaServiceException('RecipientTokenAccount or SenderTokenAccount is null');
      }

      final TokenAmountResult tokenBalance = await getTokenAccountBalanceRaw(senderTokenAccount.pubkey);
      final int decimals = tokenBalance.value.decimals;
      final double factor = math.pow(10, decimals).toDouble();
      final int tokenAmount = (zarpAmount * factor).round();

      final int currentRaw = int.parse(tokenBalance.value.amount);
      if (currentRaw < tokenAmount) {
        final double currentUi = currentRaw / factor;
        throw WalletSolanaServiceException(
          'Insufficient ZARP balance. You have ${currentUi.toStringAsFixed(6)} ZARP but need ${zarpAmount.toStringAsFixed(2)} ZARP.',
        );
      }

      final String signature = await _sendTokenInstruction(
        wallet: senderWallet,
        sourcePubkey: senderTokenAccount.pubkey,
        destPubkey: recipientTokenAccount.pubkey,
        amount: tokenAmount,
        tokenProgram: TokenProgramType.token2022Program,
      );

      // Invalidate so next balance fetch is fresh
      invalidateBalanceCache(senderWallet.address);

      return signature;
    } catch (e) {
      throw WalletSolanaServiceException('ZARP transaction failed: $e');
    }
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  Future<TransactionDetails?> getTransactionDetails(String signature) => _wrapRpcCall(
    'Error fetching transaction details',
    () => _client.rpcClient.getTransaction(signature, commitment: Commitment.confirmed),
    method: 'getTransaction',
  );

  Future<int> getTransactionCount(String address) => _wrapRpcCall(
    'Error fetching transaction count',
    () async {
      final List<TransactionSignatureInformation> signatures = await _client.rpcClient.getSignaturesForAddress(
        address,
        limit: 1,
        commitment: Commitment.confirmed,
      );
      return signatures.length;
    },
    method: 'getSignaturesForAddress',
  );

  Future<Map<String, List<TransactionDetails?>>> getAccountTransactions({
    required String walletAddress,
    int limit = 10,
    String? until,
    String? before,
    Future<void> Function(List<TransactionDetails?>)? onBatchLoaded,
    bool Function()? isCancelled,
    bool isLegacy = false,
  }) async {
    try {
      final List<TransactionSignatureInformation> signatures = await RpcRateLimiter.instance.run(
        () => _client.rpcClient.getSignaturesForAddress(
          walletAddress,
          limit: limit,
          until: until,
          before: before,
          commitment: Commitment.confirmed,
        ),
        method: 'getSignaturesForAddress',
      );

      if (signatures.isEmpty) return <String, List<TransactionDetails?>>{};

      if (before == null) {
        await _transactionStorageService.storeLastTransactionSignature(
          signatures.first.signature,
          walletAddress: walletAddress,
          isLegacy: isLegacy,
        );
      }

      if (isCancelled?.call() ?? false) return <String, List<TransactionDetails?>>{};

      final List<String> uniqueSignatures =
          signatures.map((TransactionSignatureInformation s) => s.signature).toSet().toList();

      final List<TransactionDetails?> allTransactions = <TransactionDetails?>[];

      await _fetchTransactionsWithCircuitBreaker(
        uniqueSignatures,
        onBatchLoaded: (List<TransactionDetails?> batch) async {
          if (isCancelled?.call() ?? false) return;
          allTransactions.addAll(batch);
          await onBatchLoaded?.call(batch);
        },
        isCancelled: isCancelled,
      );

      if (isCancelled?.call() ?? false) return <String, List<TransactionDetails?>>{};

      // Group by month
      final Map<String, List<TransactionDetails?>> grouped = <String, List<TransactionDetails?>>{};
      for (final TransactionDetails? tx in allTransactions) {
        if (tx == null) continue;
        final DateTime date = tx.blockTime != null
            ? DateTime.fromMillisecondsSinceEpoch(tx.blockTime! * 1000)
            : DateTime.now();
        final String key = Formatters.monthKeyFromDate(date);
        (grouped[key] ??= <TransactionDetails?>[]).add(tx);
      }

      return grouped;
    } catch (e) {
      throw WalletSolanaServiceException('Error fetching transactions by signatures: $e');
    }
  }

  // ── Faucet (devnet / QA only) ─────────────────────────────────────────────

  Future<String> requestZARP(Wallet wallet) async {
    if (!_isFaucetEnabled) {
      throw WalletSolanaServiceException('Faucet is not available in production environment');
    }

    final http.Response response = await http.post(
      Uri.parse('https://faucet.zarply.co.za/api/faucet'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{'pubkey': wallet.address}),
    );

    if (response.statusCode != 200) {
      throw WalletSolanaServiceException('Faucet request failed: ${response.body}');
    }
    return response.body;
  }

  Future<String> _requestSOL(Wallet wallet) async {
    if (!_isFaucetEnabled) {
      throw WalletSolanaServiceException('Faucet is not available in production environment');
    }

    final http.Response response = await http.post(
      Uri.parse('https://faucet.zarply.co.za/api/faucet'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{'pubkey': wallet.address, 'sol_only': true}),
    );

    if (response.statusCode != 200) {
      throw WalletSolanaServiceException('Faucet request failed: ${response.body}');
    }
    return response.body;
  }

  // ── Legacy migration ──────────────────────────────────────────────────────

  Future<ProgramAccount?> getLegacyAssociatedTokenAccount(String walletAddress) async {
    try {
      if (legacyZarpMint.isEmpty) return null;
      return await RpcRateLimiter.instance.run(
        () => _client.getAssociatedTokenAccount(
          owner: Ed25519HDPublicKey.fromBase58(walletAddress),
          mint: Ed25519HDPublicKey.fromBase58(legacyZarpMint),
          commitment: Commitment.confirmed,
        ),
        method: 'getTokenAccountsByOwner',
      );
    } catch (e) {
      return null;
    }
  }

  Future<
    ({
      bool hasLegacyAccount,
      bool needsMigration,
      bool migrationComplete,
      String? migrationSignature,
      int? migrationTimestamp,
    })
  > checkAndMigrateLegacyIfNeeded(Wallet wallet) async {
    try {
      final ProgramAccount? legacyAccount = await getLegacyAssociatedTokenAccount(wallet.address);

      if (legacyAccount == null) {
        return (
          hasLegacyAccount: false,
          needsMigration: false,
          migrationComplete: false,
          migrationSignature: null,
          migrationTimestamp: null,
        );
      }

      final TokenAmountResult balance = await RpcRateLimiter.instance.run(
        () => _client.rpcClient.getTokenAccountBalance(legacyAccount.pubkey, commitment: Commitment.confirmed),
        method: 'getTokenAccountBalance',
      );

      final int amount = int.parse(balance.value.amount);

      if (amount == 0) {
        return (
          hasLegacyAccount: true,
          needsMigration: false,
          migrationComplete: true,
          migrationSignature: null,
          migrationTimestamp: null,
        );
      }

      final String drainSignature = await drainLegacyAccount(wallet: wallet, legacyTokenAccount: legacyAccount);

      if (drainSignature.isEmpty) {
        return (
          hasLegacyAccount: true,
          needsMigration: true,
          migrationComplete: false,
          migrationSignature: null,
          migrationTimestamp: null,
        );
      }

      int? drainTimestamp;
      try {
        final TransactionDetails? drainTx = await getTransactionDetails(drainSignature);
        drainTimestamp = drainTx?.blockTime;
      } catch (e) {
        // Timestamp is best-effort — ignore failures
      }

      return (
        hasLegacyAccount: true,
        needsMigration: true,
        migrationComplete: true,
        migrationSignature: drainSignature,
        migrationTimestamp: drainTimestamp,
      );
    } catch (e) {
      throw WalletSolanaServiceException('Legacy migration check failed: $e');
    }
  }

  Future<String> drainLegacyAccount({
    required Wallet wallet,
    required ProgramAccount legacyTokenAccount,
  }) async {
    try {
      if (migrationWallet.isEmpty) {
        throw WalletSolanaServiceException('Migration wallet not configured');
      }

      final TokenAmountResult balance = await getTokenAccountBalanceRaw(legacyTokenAccount.pubkey);
      final int amount = int.parse(balance.value.amount);
      if (amount == 0) return '';

      final ProgramAccount? destTokenAccount = await RpcRateLimiter.instance.run(
        () => _client.getAssociatedTokenAccount(
          owner: Ed25519HDPublicKey.fromBase58(migrationWallet),
          mint: Ed25519HDPublicKey.fromBase58(legacyZarpMint),
          commitment: Commitment.confirmed,
        ),
        method: 'getTokenAccountsByOwner',
      );

      if (destTokenAccount == null) {
        throw WalletSolanaServiceException('Migration wallet token account not found');
      }

      return await _sendTokenInstruction(
        wallet: wallet,
        sourcePubkey: legacyTokenAccount.pubkey,
        destPubkey: destTokenAccount.pubkey,
        amount: amount,
        tokenProgram: TokenProgramType.tokenProgram,
      );
    } catch (e) {
      if (e is WalletSolanaServiceException) rethrow;
      throw WalletSolanaServiceException('Failed to drain legacy account: $e');
    }
  }

  // ── Validation ────────────────────────────────────────────────────────────

  bool isValidMnemonic(String mnemonic) => bip39.validateMnemonic(mnemonic);

  bool isValidPrivateKey(String privateKey) => privateKey.length == 64;
}
