import 'package:solana/base58.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

class WalletSolanaServiceException implements Exception {
  final String message;
  WalletSolanaServiceException(this.message);

  @override
  String toString() => 'SolanaConnectionException: $message';
}

class WalletSolanaService {
  final SolanaClient _client;

  WalletSolanaService({
    required String rpcUrl,
    required String websocketUrl,
  }) : _client = SolanaClient(
          rpcUrl: Uri.parse(rpcUrl),
          websocketUrl: Uri.parse(websocketUrl),
        );

  Future<Wallet> createWallet() async {
    final wallet = await Wallet.random();
    return wallet;
  }

  Future<String> requestAirdrop(String address, int lamports) async {
    try {
      final signature = await _client.requestAirdrop(
          address: Ed25519HDPublicKey(base58decode(address)),
          lamports: lamports);
      return signature;
    } catch (e) {
      throw WalletSolanaServiceException('Airdrop failed: $e');
    }
  }

  Future<String> sendTransaction({
    required Wallet senderWallet,
    required String recipientAddress,
    required int lamports,
  }) async {
    try {
      final transaction = await _client.transferLamports(
          source: senderWallet,
          destination: Ed25519HDPublicKey(base58decode(recipientAddress)),
          lamports: lamports);

      return transaction;
    } catch (e) {
      throw WalletSolanaServiceException('Transaction failed: $e');
    }
  }

  Future<double> getAccountBalance(String publicKey) async {
    try {
      final balance = await _client.rpcClient.getBalance(publicKey);
      return balance.value.toDouble();
    } catch (e) {
      throw WalletSolanaServiceException(
          'Could not retrieve account balance from Solana:: $e');
    }
  }

  Future<Iterable<TransactionDetails>> getAccountTransactions(
      String publicKey) async {
    try {
      final transactions = await _client.rpcClient.getTransactionsList(
          Ed25519HDPublicKey(base58decode(publicKey)),
          limit: 10);
      return transactions;
    } catch (e) {
      throw WalletSolanaServiceException(
          'Could not retrieve account transactions from Solana:: $e');
    }
  }
}
