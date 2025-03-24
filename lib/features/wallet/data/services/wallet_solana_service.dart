import 'dart:async';

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/base58.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/services/transaction_storage_service.dart';

class WalletSolanaServiceException implements Exception {
  WalletSolanaServiceException(this.message);
  final String message;

  @override
  String toString() => 'SolanaConnectionException: $message';
}

class WalletSolanaService {
  WalletSolanaService({
    required String rpcUrl,
    required String websocketUrl,
  }) : _client = SolanaClient(
          rpcUrl: Uri.parse(rpcUrl),
          websocketUrl: Uri.parse(websocketUrl),
        );
  final SolanaClient _client;
  final TransactionStorageService _transactionStorageService =
      TransactionStorageService();
  static final String zarpMint = dotenv.env['ZARP_MINT_ADDRESS'] ?? '';
  static const int zarpDecimalFactor = 1000000000;

  Future<Wallet> createWallet() async {
    try {
      final Ed25519HDKeyPair wallet = await Wallet.random();

      if (zarpMint.isEmpty) {
        throw WalletSolanaServiceException(
          'ZARP_MINT_ADDRESS is not configured in .env file',
        );
      }

      await requestAirdrop(
        wallet.address,
        50000000, // SOL 0.05
      );

      return wallet;
    } catch (e) {
      throw WalletSolanaServiceException('Failed to create wallet: $e');
    }
  }

  Future<Wallet> createWalletFromMnemonic(String mnemonic) async {
    final Ed25519HDKeyPair wallet =
        await Ed25519HDKeyPair.fromMnemonic(mnemonic);

    if (zarpMint.isEmpty) {
      throw WalletSolanaServiceException(
        'ZARP_MINT_ADDRESS is not configured in .env file',
      );
    }

    await requestAirdrop(
      wallet.address,
      50000000, // SOL 0.05
    );

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
    );
  }

  Future<ProgramAccount?> getAssociatedTokenAccount(
    Wallet wallet,
  ) async {
    final ProgramAccount? tokenAccount =
        await _client.getAssociatedTokenAccount(
      owner: wallet.publicKey,
      mint: Ed25519HDPublicKey.fromBase58(zarpMint),
    );

    return tokenAccount;
  }

  Future<Wallet> restoreWalletFromMnemonic(String mnemonic) async {
    try {
      if (!isValidMnemonic(mnemonic)) {
        throw WalletSolanaServiceException('Invalid mnemonic phrase');
      }

      final Ed25519HDKeyPair wallet =
          await Ed25519HDKeyPair.fromMnemonic(mnemonic);
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

      final Ed25519HDKeyPair wallet =
          await Ed25519HDKeyPair.fromPrivateKeyBytes(
        privateKey: base58decode(privateKey),
      );

      return wallet;
    } catch (e) {
      throw WalletSolanaServiceException('Failed to restore wallet: $e');
    }
  }

  Future<String> requestAirdrop(String address, int lamports) async {
    try {
      final String signature = await _client.requestAirdrop(
        address: Ed25519HDPublicKey(base58decode(address)),
        lamports: lamports,
      );
      return signature;
    } catch (e) {
      throw WalletSolanaServiceException('Airdrop failed: $e');
    }
  }

  Future<double> getSolBalance(String publicKey) async {
    try {
      final BalanceResult lamports =
          await _client.rpcClient.getBalance(publicKey);
      return lamports.value.toDouble() / lamportsPerSol;
    } catch (e) {
      throw WalletSolanaServiceException('Could not retrieve SOL balance: $e');
    }
  }

  Future<String> sendTransaction({
    required Wallet senderWallet,
    required String recipientAddress,
    required double zarpAmount,
  }) async {
    try {
      final double solBalance = await getSolBalance(senderWallet.address);
      if (solBalance < 0.001) {
        throw WalletSolanaServiceException(
          'Insufficient SOL balance for transaction fees. Need at least 0.001 SOL',
        );
      }

      final int tokenAmount = (zarpAmount * zarpDecimalFactor).round();

      final TransactionId transaction = await _client.transferSplToken(
        owner: senderWallet,
        destination: Ed25519HDPublicKey(base58decode(recipientAddress)),
        amount: tokenAmount,
        mint: Ed25519HDPublicKey.fromBase58(zarpMint),
        tokenProgram: TokenProgramType.token2022Program,
      );

      return transaction;
    } catch (e) {
      throw WalletSolanaServiceException('ZARP transaction failed: $e');
    }
  }

  Future<double> getZarpBalance(String publicKey) async {
    try {
      final TokenAmountResult balance =
          await _client.rpcClient.getTokenAccountBalance(publicKey);
      return double.parse(balance.value.amount) / zarpDecimalFactor;
    } catch (e) {
      throw WalletSolanaServiceException(
        'Could not retrieve ZARP balance: $e',
      );
    }
  }

  Future<Map<String, List<TransactionDetails?>>> getAccountTransactions({
    required String walletAddress,
    int limit = 100,
    String? afterSignature,
    String? beforeSignature,
    Function(List<TransactionDetails?>)? onBatchLoaded,
    bool Function()? isCancelled,
  }) async {
    try {
      final List<TransactionSignatureInformation> signatures =
          await _client.rpcClient.getSignaturesForAddress(
        walletAddress,
        limit: limit,
        until: afterSignature,
        before: beforeSignature,
        commitment: Commitment.confirmed,
      );

      if (signatures.isEmpty) {
        return <String, List<TransactionDetails?>>{};
      }

      if (signatures.isNotEmpty && afterSignature == null) {
        await _transactionStorageService.storeLastTransactionSignature(
          signatures.first.signature,
        );
      }

      final StreamController<List<TransactionDetails?>>
          transactionStreamController =
          StreamController<List<TransactionDetails?>>();

      if (isCancelled != null && isCancelled()) {
        await transactionStreamController.close();
        return <String, List<TransactionDetails?>>{};
      }

      await _fetchTransactionsWithCircuitBreaker(
        signatures
            .map((TransactionSignatureInformation sig) => sig.signature)
            .toList(),
        onBatchLoaded: (List<TransactionDetails?> batch) {
          if (isCancelled != null && isCancelled()) {
            return;
          }

          transactionStreamController.add(batch);
          if (onBatchLoaded != null) {
            onBatchLoaded(batch);
          }
        },
        isCancelled: isCancelled,
      ).then((_) {
        transactionStreamController.close();
      }).catchError((Object e) {
        transactionStreamController.addError(e);
        transactionStreamController.close();
      });

      final List<TransactionDetails?> allTransactions = <TransactionDetails?>[];
      await for (final List<TransactionDetails?> batch
          in transactionStreamController.stream) {
        if (isCancelled != null && isCancelled()) {
          break;
        }
        allTransactions.addAll(batch);
      }

      if (isCancelled != null && isCancelled()) {
        return <String, List<TransactionDetails?>>{};
      }

      final Map<String, List<TransactionDetails?>> groupedTransactions =
          <String, List<TransactionDetails?>>{};

      for (final TransactionDetails? transaction in allTransactions) {
        if (transaction == null) continue;

        final DateTime transactionDate = transaction.blockTime != null
            ? DateTime.fromMillisecondsSinceEpoch(transaction.blockTime! * 1000)
            : DateTime.now();

        final String monthKey =
            '${transactionDate.year}-${transactionDate.month.toString().padLeft(2, '0')}';

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

  Future<void> _fetchTransactionsWithCircuitBreaker(
    List<String> signatures, {
    required Function(List<TransactionDetails?>) onBatchLoaded,
    bool Function()? isCancelled,
  }) async {
    try {
      const int maxRetries = 3;
      const Duration rateLimitWaitTime = Duration(seconds: 11);
      const Duration initialWaitTime = Duration(seconds: 2);
      const Duration maxWaitTime = Duration(seconds: 60);

      // Process transactions one by one to better handle rate limits
      final List<TransactionDetails?> currentBatch = <TransactionDetails?>[];

      for (int i = 0; i < signatures.length; i++) {
        if (isCancelled != null && isCancelled()) {
          return;
        }

        final String signature = signatures[i];
        TransactionDetails? transactionDetails;
        int retryCount = 0;
        bool isRateLimited = false;

        while (retryCount < maxRetries && transactionDetails == null) {
          if (isCancelled != null && isCancelled()) {
            break;
          }

          if (isRateLimited) {
            debugPrint(
              'Rate limit hit, waiting for $rateLimitWaitTime before retry...',
            );
            await Future<void>.delayed(rateLimitWaitTime);
            isRateLimited = false;
          }

          try {
            transactionDetails = await _client.rpcClient.getTransaction(
              signature,
              commitment: Commitment.confirmed,
            );
          } catch (e) {
            if (e
                .toString()
                .contains('Too many requests for a specific RPC call')) {
              isRateLimited = true;
              retryCount++;
            } else {
              debugPrint('Error fetching transaction $signature: $e');
              retryCount++;

              // For non-rate-limit errors, use exponential backoff
              if (retryCount < maxRetries) {
                final Duration retryDelay = Duration(
                  seconds: initialWaitTime.inSeconds * (1 << (retryCount - 1)),
                );
                await Future<void>.delayed(
                  retryDelay > maxWaitTime ? maxWaitTime : retryDelay,
                );
              }
            }
          }
        }

        currentBatch.add(transactionDetails);

        // When we have enough transactions or reached the end, deliver the batch
        if (currentBatch.length == 10 || i == signatures.length - 1) {
          if (isCancelled != null && isCancelled()) {
            return;
          }

          onBatchLoaded(List<TransactionDetails?>.from(currentBatch));
          currentBatch.clear();
        }
      }
    } catch (e) {
      throw WalletSolanaServiceException('Error in transaction processing: $e');
    }
  }

  Future<TransactionDetails?> getTransactionDetails(String signature) async {
    try {
      return await _client.rpcClient.getTransaction(signature);
    } catch (e) {
      throw WalletSolanaServiceException(
        'Error fetching transaction details: $e',
      );
    }
  }

  Future<int> getTransactionCount(String address) async {
    try {
      final List<TransactionSignatureInformation> signatures =
          await _client.rpcClient.getSignaturesForAddress(address);
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
}
