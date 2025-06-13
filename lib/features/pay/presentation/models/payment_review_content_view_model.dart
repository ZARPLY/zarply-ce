import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../../data/repositories/payment_review_content_repository_impl.dart';
import '../../domain/repositories/payment_review_content_repository.dart';

class PaymentReviewContentViewModel extends ChangeNotifier {
  PaymentReviewContentViewModel({
    PaymentReviewContentRepository? repository,
  }) : _repository = repository ?? PaymentReviewContentRepositoryImpl();
  final PaymentReviewContentRepository _repository;

  bool _hasPaymentBeenMade = false;
  bool get hasPaymentBeenMade => _hasPaymentBeenMade;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> makeTransaction({
    required Wallet wallet,
    required String recipientAddress,
    required String amount,
    required BuildContext context,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (recipientAddress.isEmpty) {
        throw Exception('Recipient address not found');
      }

      final String txSignature = await _repository.makeTransaction(
        wallet: wallet,
        recipientAddress: recipientAddress,
        amount: double.parse(amount) / 100,
      );

      // Wait for transaction confirmation
      TransactionDetails? txDetails;
      int retryCount = 0;
      const int maxRetries = 10;
      const Duration retryDelay = Duration(seconds: 2);

      while (retryCount < maxRetries) {
        txDetails = await _repository.getTransactionDetails(txSignature);
        if (txDetails != null) {
          break;
        }
        await Future<void>.delayed(retryDelay);
        retryCount++;
      }

      if (txDetails == null) {
        throw Exception('Transaction not confirmed after multiple attempts');
      }

      await _repository.storeTransactionDetails(txDetails);

      // Refresh transactions and balances in the wallet provider
      final WalletProvider walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      await walletProvider.refreshTransactions();

      // Refresh balances after payment completion
      await walletProvider.onPaymentCompleted();

      _hasPaymentBeenMade = true;
      notifyListeners();
    } catch (e) {
      _hasPaymentBeenMade = false;
      notifyListeners();
      rethrow; // Re-throw the error to be handled by the UI
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _hasPaymentBeenMade = false;
    _isLoading = false;
    notifyListeners();
  }
}
