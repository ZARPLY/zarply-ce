import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

abstract class PaymentReviewContentRepository {
  Future<String> makeTransaction({
    required Wallet wallet,
    required String recipientAddress,
    required double amount,
  });

  Future<TransactionDetails?> getTransactionDetails(String txSignature);

  Future<void> storeTransactionDetails(TransactionDetails txDetails);
}
