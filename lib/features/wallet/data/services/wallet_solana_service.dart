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

import '../../../../core/services/balance_cache_service.dart';
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

    return WalletSolanaService._(
      rpcUrl: config.rpcUrl,
      websocketUrl: config.websocketUrl,
    );
  }

  final SolanaClient _client;
  final BalanceCacheService _balanceCacheService = BalanceCacheService();
  final TransactionStorageService _transactionStorageService = TransactionStorageService();
  static final String zarpMint = dotenv.env['ZARP_MINT_ADDRESS'] ?? '';
  static final String legacyZarpMint = dotenv.env['ZARP_MINT_ADDRESS_LEGACY'] ?? '';
  static final String migrationWallet = dotenv.env['ZARP_MIGRATION_WALLET_ADDRESS'] ?? '';
  static const int zarpDecimalFactor = 1000000000;

  static bool get _isFaucetEnabled {
    final String? rpcUrl = dotenv.env['solana_wallet_rpc_url'];

    // Disable faucet-based auto funding when we are pointing at mainnet (PROD).
    // QA and other non-prod environments use devnet/testnet URLs and will keep auto funding enabled.
    if (rpcUrl == null) {
      return true;
    }

    return !rpcUrl.contains('mainnet');
  }

  /// True when RPC is mainnet (no faucet, no on-chain ATA creation at wallet creation).
  bool get isMainnet => !_isFaucetEnabled;

  /// Derives the ZARP Associated Token Account address for [wallet] (PDA). Does not create the account on-chain.
  /// Use on mainnet where we do not fund the wallet or create the ATA at creation time.
  Future<ProgramAccount> deriveAssociatedTokenAddress(Wallet wallet) async {
    final Ed25519HDPublicKey ataKey = await findAssociatedTokenAddress(
      owner: wallet.publicKey,
      mint: Ed25519HDPublicKey.fromBase58(zarpMint),
      tokenProgramType: TokenProgramType.token2022Program,
    );
    return ProgramAccount(
      pubkey: ataKey.toBase58(),
      account: Account(
        lamports: 0,
        owner: '',
        data: null,
        executable: false,
        rentEpoch: BigInt.zero,
      ),
    );
  }

  Future<Wallet> createWallet() async {
    try {
      final Ed25519HDKeyPair wallet = await Wallet.random();

      if (zarpMint.isEmpty) {
        throw WalletSolanaServiceException(
          'ZARP_MINT_ADDRESS is not configured in .env file',
        );
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
      throw WalletSolanaServiceException(
        'ZARP_MINT_ADDRESS is not configured in .env file',
      );
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

  Future<ProgramAccount> createAssociatedTokenAccount(
    Wallet wallet,
  ) async {
    return await _client.createAssociatedTokenAccount(
      owner: wallet.publicKey,
      mint: Ed25519HDPublicKey.fromBase58(zarpMint),
      funder: wallet,
      tokenProgramType: TokenProgramType.token2022Program,
      commitment: Commitment.confirmed,
    );
  }

  Future<ProgramAccount?> getAssociatedTokenAccount(
    String walletAddress,
  ) async {
    try {
      final ProgramAccount? tokenAccount = await _client.getAssociatedTokenAccount(
        owner: Ed25519HDPublicKey.fromBase58(walletAddress),
        mint: Ed25519HDPublicKey.fromBase58(zarpMint),
        commitment: Commitment.confirmed,
      );

      return tokenAccount;
    } catch (e) {
      throw WalletSolanaServiceException(
        'Could not get associated token account for address: $e',
      );
    }
  }

  Future<Wallet> restoreWalletFromMnemonic(String mnemonic) async {
    try {
      if (!isValidMnemonic(mnemonic)) {
        throw WalletSolanaServiceException('Invalid mnemonic phrase');
      }

      final Ed25519HDKeyPair wallet = await Ed25519HDKeyPair.fromMnemonic(mnemonic);
      return wallet;
    } catch (e) {
      throw WalletSolanaServiceException('Failed to restore wallet: $e');
    }
  }

  Future<Wallet> restoreWalletFromPrivateKey(String privateKey) async {
    try {
      if (privateKey.isEmpty) {
        throw WalletSolanaServiceException('Private key is empty');
      }

      final Ed25519HDKeyPair wallet = await Ed25519HDKeyPair.fromPrivateKeyBytes(
        privateKey: base58decode(privateKey),
      );

      return wallet;
    } catch (e) {
      throw WalletSolanaServiceException('Failed to restore wallet: $e');
    }
  }

  Future<double> getSolBalance(String publicKey) async {
    try {
      final BalanceResult lamports = await _client.rpcClient.getBalance(publicKey, commitment: Commitment.confirmed);
      return lamports.value.toDouble() / lamportsPerSol;
    } catch (e) {
      throw WalletSolanaServiceException('Could not retrieve SOL balance: $e');
    }
  }

  Future<String> sendTransaction({
    required Wallet senderWallet,
    required ProgramAccount? senderTokenAccount,
    required ProgramAccount? recipientTokenAccount,
    required double zarpAmount,
  }) async {
    try {
      final double solBalance = await _balanceCacheService.getSolBalance(senderWallet.address);
      if (solBalance < 0.001) {
        throw WalletSolanaServiceException(
          'Insufficient SOL balance for transaction fees. Need at least 0.001 SOL',
        );
      }

      if (senderTokenAccount == null || recipientTokenAccount == null) {
        throw WalletSolanaServiceException(
          'RecipientTokenAccount or SenderTokenAccount is null',
        );
      }

      // Derive the correct decimal factor from the mint's configured decimals
      final TokenAmountResult senderTokenBalance = await _client.rpcClient.getTokenAccountBalance(
        senderTokenAccount.pubkey,
        commitment: Commitment.confirmed,
      );
      final int decimals = senderTokenBalance.value.decimals;
      final double factor = math.pow(10, decimals).toDouble();
      final int tokenAmount = (zarpAmount * factor).round();

      // Optional safety check: ensure the sender has enough raw tokens
      final int currentRaw = int.parse(senderTokenBalance.value.amount);
      if (currentRaw < tokenAmount) {
        final double currentUi = currentRaw / factor;
        throw WalletSolanaServiceException(
          'Insufficient ZARP balance. You have ${currentUi.toStringAsFixed(6)} ZARP but need ${zarpAmount.toStringAsFixed(2)} ZARP.',
        );
      }

      final TokenInstruction instruction = TokenInstruction.transfer(
        source: Ed25519HDPublicKey.fromBase58(senderTokenAccount.pubkey),
        destination: Ed25519HDPublicKey.fromBase58(recipientTokenAccount.pubkey),
        owner: senderWallet.publicKey,
        amount: tokenAmount,
        tokenProgram: TokenProgramType.token2022Program,
      );

      final Message message = Message(
        instructions: <TokenInstruction>[
          instruction,
        ],
      );

      final LatestBlockhash bh = await _client.rpcClient.getLatestBlockhash(commitment: Commitment.confirmed).value;

      final SignedTx signedTransaction = await signTransaction(
        bh,
        message,
        <Ed25519HDKeyPair>[senderWallet],
      );

      final String transaction = await _client.rpcClient.sendTransaction(
        signedTransaction.encode(),
        preflightCommitment: Commitment.confirmed,
      );

      return transaction;
    } catch (e) {
      throw WalletSolanaServiceException('ZARP transaction failed: $e');
    }
  }

  Future<double> getZarpBalance(String publicKey) async {
    try {
      final TokenAmountResult balance = await _client.rpcClient.getTokenAccountBalance(
        publicKey,
        commitment: Commitment.confirmed,
      );

      final String? uiAmountString = balance.value.uiAmountString;
      if (uiAmountString != null) {
        return double.parse(uiAmountString);
      }
      // Fallback to legacy calculation using the fixed decimal factor.
      return double.parse(balance.value.amount) / zarpDecimalFactor;
    } catch (e) {
      // ATA not created on-chain yet (e.g. mainnet new wallet) — treat as 0.
      return 0.0;
    }
  }

  /// Get raw token account balance result (for precise balance checks)
  Future<TokenAmountResult> getTokenAccountBalanceRaw(String publicKey) async {
    return await _client.rpcClient.getTokenAccountBalance(
      publicKey,
      commitment: Commitment.confirmed,
    );
  }

  Future<Map<String, List<TransactionDetails?>>> getAccountTransactions({
    required String walletAddress,
    int limit = 25,
    String? until,
    String? before,
    Future<void> Function(List<TransactionDetails?>)? onBatchLoaded,
    bool Function()? isCancelled,
    bool isLegacy = false,
  }) async {
    try {
      final List<TransactionSignatureInformation> signatures = await _client.rpcClient.getSignaturesForAddress(
        walletAddress,
        limit: limit,
        until: until,
        before: before,
        commitment: Commitment.confirmed,
      );

      if (signatures.isEmpty) {
        return <String, List<TransactionDetails?>>{};
      }

      if (before == null) {
        await _transactionStorageService.storeLastTransactionSignature(
          signatures.first.signature,
          walletAddress: walletAddress,
          isLegacy: isLegacy,
        );
      }

      if (isCancelled != null && isCancelled()) {
        return <String, List<TransactionDetails?>>{};
      }

      // RPC can return duplicate signatures (e.g. with before/until). Dedupe to avoid fetching same transaction twice.
      final List<String> uniqueSignatures = <String>[];
      final Set<String> seen = <String>{};
      for (final TransactionSignatureInformation signatureInfo in signatures) {
        if (seen.add(signatureInfo.signature)) uniqueSignatures.add(signatureInfo.signature);
      }

      final StreamController<List<TransactionDetails?>> transactionStreamController =
          StreamController<List<TransactionDetails?>>();
      final List<TransactionDetails?> allTransactions = <TransactionDetails?>[];
      late final Future<void> streamProcessing;

      try {
        streamProcessing = transactionStreamController.stream.listen(
          (List<TransactionDetails?> batch) {
            if (isCancelled != null && isCancelled()) {
              return;
            }
            allTransactions.addAll(batch);
          },
        ).asFuture<void>();

        await _fetchTransactionsWithCircuitBreaker(
          uniqueSignatures,
          onBatchLoaded: (List<TransactionDetails?> batch) async {
            if (isCancelled != null && isCancelled()) {
              return;
            }

            transactionStreamController.add(batch);
            if (onBatchLoaded != null) {
              await onBatchLoaded(batch);
            }
          },
          isCancelled: isCancelled,
        );

        await transactionStreamController.close();

        await streamProcessing;
      } catch (e) {
        rethrow;
      } finally {
        await transactionStreamController.close();
      }

      if (isCancelled != null && isCancelled()) {
        return <String, List<TransactionDetails?>>{};
      }

      final Map<String, List<TransactionDetails?>> groupedTransactions = <String, List<TransactionDetails?>>{};

      for (final TransactionDetails? transaction in allTransactions) {
        if (transaction == null) continue;

        final DateTime transactionDate = transaction.blockTime != null
            ? DateTime.fromMillisecondsSinceEpoch(transaction.blockTime! * 1000)
            : DateTime.now();

        final String monthKey = Formatters.monthKeyFromDate(transactionDate);

        if (!groupedTransactions.containsKey(monthKey)) {
          groupedTransactions[monthKey] = <TransactionDetails?>[];
        }
        groupedTransactions[monthKey]!.add(transaction);
      }

      return groupedTransactions;
    } catch (e) {
      throw WalletSolanaServiceException(
        'Error fetching transactions by signatures: $e',
      );
    }
  }

  Future<String> requestZARP(Wallet wallet) async {
    if (!_isFaucetEnabled) {
      throw WalletSolanaServiceException(
        'Faucet is not available in production environment',
      );
    }

    // call ZARPLY faucet
    final http.Response response = await http.post(
      Uri.parse('https://faucet.zarply.co.za/api/faucet'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, Object?>{
        'pubkey': wallet.address,
      }),
    );

    if (response.statusCode != 200) {
      throw WalletSolanaServiceException(
        'Faucet request failed: ${response.body}',
      );
    }

    return response.body;
  }

  Future<TransactionDetails?> getTransactionDetails(String signature) async {
    try {
      return await _client.rpcClient.getTransaction(signature, commitment: Commitment.confirmed);
    } catch (e) {
      throw WalletSolanaServiceException(
        'Error fetching transaction details: $e',
      );
    }
  }

  Future<int> getTransactionCount(String address) async {
    try {
      final List<TransactionSignatureInformation> signatures = await _client.rpcClient.getSignaturesForAddress(
        address,
        commitment: Commitment.confirmed,
      );
      return signatures.length;
    } catch (e) {
      throw WalletSolanaServiceException(
        'Error fetching transaction count: $e',
      );
    }
  }

  bool isValidMnemonic(String mnemonic) {
    return bip39.validateMnemonic(mnemonic);
  }

  bool isValidPrivateKey(String privateKey) {
    return privateKey.length == 64;
  }

  Future<void> _fetchTransactionsWithCircuitBreaker(
    List<String> signatures, {
    required Future<void> Function(List<TransactionDetails?>) onBatchLoaded,
    bool Function()? isCancelled,
  }) async {
    try {
      const int maxRetries = 3;
      const Duration throttleDelay = Duration(milliseconds: 200);
      const Duration rateLimitWaitTime = Duration(seconds: 11);
      const Duration initialWaitTime = Duration(seconds: 2);
      const Duration maxWaitTime = Duration(seconds: 60);

      final List<TransactionDetails?> currentBatch = <TransactionDetails?>[];

      for (int i = 0; i < signatures.length; i++) {
        if (isCancelled != null && isCancelled()) return;

        // Throttle between calls to avoid RPC rate limits
        if (i > 0) await Future<void>.delayed(throttleDelay);

        final String signature = signatures[i];
        TransactionDetails? transactionDetails;
        int retryCount = 0;

        while (retryCount < maxRetries && transactionDetails == null) {
          if (isCancelled != null && isCancelled()) break;

          try {
            transactionDetails = await _client.rpcClient.getTransaction(
              signature,
              commitment: Commitment.confirmed,
            );
          } catch (e) {
            retryCount++;
            final bool isRateLimited = e.toString().contains('Too many requests');
            final Duration delay = isRateLimited
                ? rateLimitWaitTime
                : (retryCount < maxRetries
                      ? Duration(seconds: initialWaitTime.inSeconds * (1 << (retryCount - 1)))
                      : maxWaitTime);

            if (retryCount < maxRetries) {
              await Future<void>.delayed(delay > maxWaitTime ? maxWaitTime : delay);
            }
          }
        }

        currentBatch.add(transactionDetails);

        if (currentBatch.length == 10 || i == signatures.length - 1) {
          if (isCancelled != null && isCancelled()) return;
          await onBatchLoaded(List<TransactionDetails?>.from(currentBatch));
          currentBatch.clear();
        }
      }
    } catch (e) {
      throw WalletSolanaServiceException('Error in transaction processing: $e');
    }
  }

  Future<String> _requestSOL(Wallet wallet) async {
    if (!_isFaucetEnabled) {
      throw WalletSolanaServiceException(
        'Faucet is not available in production environment',
      );
    }

    // call ZARPLY faucet
    final http.Response response = await http.post(
      Uri.parse('https://faucet.zarply.co.za/api/faucet'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, Object?>{
        'pubkey': wallet.address,
        'sol_only': true,
      }),
    );

    if (response.statusCode != 200) {
      throw WalletSolanaServiceException(
        'Faucet request failed: ${response.body}',
      );
    }

    return response.body;
  }

  /// Get legacy token account for a wallet address
  Future<ProgramAccount?> getLegacyAssociatedTokenAccount(String walletAddress) async {
    try {
      if (legacyZarpMint.isEmpty) return null;

      return await _client.getAssociatedTokenAccount(
        owner: Ed25519HDPublicKey.fromBase58(walletAddress),
        mint: Ed25519HDPublicKey.fromBase58(legacyZarpMint),
        commitment: Commitment.confirmed,
      );
    } catch (e) {
      return null; // Account doesn't exist
    }
  }

  /// Check if wallet has legacy account and migrate if needed
  Future<
    ({
      bool hasLegacyAccount,
      bool needsMigration,
      bool migrationComplete,
      String? migrationSignature,
      int? migrationTimestamp,
    })
  >
  checkAndMigrateLegacyIfNeeded(Wallet wallet) async {
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

      // Check balance
      final TokenAmountResult balance = await _client.rpcClient.getTokenAccountBalance(
        legacyAccount.pubkey,
        commitment: Commitment.confirmed,
      );

      final int amount = int.parse(balance.value.amount);

      if (amount == 0) {
        // Balance is 0 - no migration needed
        return (
          hasLegacyAccount: true,
          needsMigration: false,
          migrationComplete: true,
          migrationSignature: null,
          migrationTimestamp: null,
        );
      }

      // Balance > 0 - drain it
      final String drainSignature = await drainLegacyAccount(
        wallet: wallet,
        legacyTokenAccount: legacyAccount,
      );

      if (drainSignature.isEmpty) {
        // Drain failed (likely transient) - try again later
        return (
          hasLegacyAccount: true,
          needsMigration: true,
          migrationComplete: false,
          migrationSignature: null,
          migrationTimestamp: null,
        );
      }

      // Get transaction timestamp
      int? drainTimestamp;
      try {
        final TransactionDetails? drainTransaction = await getTransactionDetails(drainSignature);
        drainTimestamp = drainTransaction?.blockTime;
      } catch (e) {
        // Ignore if we can't get timestamp
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

  /// Drain legacy account by sending all tokens to migration wallet
  Future<String> drainLegacyAccount({
    required Wallet wallet,
    required ProgramAccount legacyTokenAccount,
  }) async {
    try {
      if (migrationWallet.isEmpty) {
        throw WalletSolanaServiceException('Migration wallet not configured');
      }

      // Get balance
      final TokenAmountResult balance = await _client.rpcClient.getTokenAccountBalance(
        legacyTokenAccount.pubkey,
        commitment: Commitment.confirmed,
      );

      final int amount = int.parse(balance.value.amount);
      if (amount == 0) return '';

      // Get destination token account
      final ProgramAccount? destTokenAccount = await _client.getAssociatedTokenAccount(
        owner: Ed25519HDPublicKey.fromBase58(migrationWallet),
        mint: Ed25519HDPublicKey.fromBase58(legacyZarpMint),
        commitment: Commitment.confirmed,
      );

      if (destTokenAccount == null) {
        throw WalletSolanaServiceException('Migration wallet token account not found');
      }

      // Create transfer instruction
      final TokenInstruction transferInstruction = TokenInstruction.transfer(
        source: Ed25519HDPublicKey.fromBase58(legacyTokenAccount.pubkey),
        destination: Ed25519HDPublicKey.fromBase58(destTokenAccount.pubkey),
        owner: wallet.publicKey,
        amount: amount,
        tokenProgram: TokenProgramType.token2022Program,
      );

      // Build message with transfer instruction only
      final Message message = Message(
        instructions: <Instruction>[transferInstruction],
      );

      // Get blockhash
      final LatestBlockhash bh = await _client.rpcClient
          .getLatestBlockhash(
            commitment: Commitment.confirmed,
          )
          .value;

      // Sign transaction
      final SignedTx signedTransaction = await signTransaction(
        bh,
        message,
        <Ed25519HDKeyPair>[wallet],
      );

      // Send transaction
      final String signature = await _client.rpcClient.sendTransaction(
        signedTransaction.encode(),
        preflightCommitment: Commitment.confirmed,
      );

      return signature;
    } catch (e) {
      if (_isInsufficientFundsError(e)) {
        return '';
      }
      throw WalletSolanaServiceException('Failed to drain legacy account: $e');
    }
  }

  bool _isInsufficientFundsError(Object e) {
    final String message = e.toString().toLowerCase();
    return message.contains('insufficient funds') ||
        message.contains('custom program error: 0x1') ||
        message.contains('instruction error');
  }
}
