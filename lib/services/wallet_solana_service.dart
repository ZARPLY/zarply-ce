import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/base58.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import 'transaction_storage_service.dart';

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
  }) async {
    try {
      final List<TransactionSignatureInformation> signatures =
          await _client.rpcClient.getSignaturesForAddress(
        walletAddress,
        limit: limit,
        until: afterSignature,
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

      final List<TransactionDetails?> transactions = await Future.wait(
        signatures.map((TransactionSignatureInformation sig) async {
          return await _client.rpcClient.getTransaction(
            sig.signature,
            commitment: Commitment.confirmed,
          );
        }),
      );

      final Map<String, List<TransactionDetails?>> groupedTransactions =
          <String, List<TransactionDetails?>>{};

      for (final TransactionDetails? transaction in transactions) {
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

  Future<TransactionDetails?> getTransactionDetails(String signature) async {
    try {
      return await _client.rpcClient.getTransaction(signature);
    } catch (e) {
      throw WalletSolanaServiceException(
        'Error fetching transaction details: $e',
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
