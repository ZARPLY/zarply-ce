import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

abstract class PaymentReviewContentRepository {
  Future<String> makeTransaction({
    required Wallet wallet,
    required ProgramAccount? senderTokenAccount,
    required ProgramAccount? recipientTokenAccount,
    required double amount,
  });

  Future<TransactionDetails?> getTransactionDetails(String transactionSignature);

  Future<void> storeTransactionDetails(
    TransactionDetails transactionDetails, {
    required String walletAddress,
  });

  Future<double> getZarpBalance(String publicKey);

  Future<void> updateZarpBalance(double newBalance);
}
