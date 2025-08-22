import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/provider/payment_provider.dart';
import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/services/transaction_storage_service.dart';
import '../../data/repositories/payment_review_content_repository_impl.dart';
import '../../domain/repositories/payment_review_content_repository.dart';

class PaymentReviewContentViewModel extends ChangeNotifier {
  PaymentReviewContentViewModel({
    PaymentReviewContentRepository? repository,
  }) : _repository = repository ?? PaymentReviewContentRepositoryImpl();
  final PaymentReviewContentRepository _repository;
  final TransactionStorageService _transactionStorageService =
      TransactionStorageService();

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

      final WalletProvider walletProvider =
          Provider.of<WalletProvider>(context, listen: false);
      final PaymentProvider paymentProvider =
          Provider.of<PaymentProvider>(context, listen: false);

      // Get recipient token account from provider
      final ProgramAccount? recipientTokenAccount =
          paymentProvider.recipientTokenAccount;

      if (recipientTokenAccount == null) {
        throw Exception(
          'Recipient does not have a token account for this token',
        );
      }

      final String txSignature = await _repository.makeTransaction(
        wallet: wallet,
        senderTokenAccount: walletProvider.userTokenAccount,
        recipientTokenAccount: recipientTokenAccount,
        amount: double.parse(amount) / 100,
      );

      final TransactionDetails? txDetails =
          await _repository.getTransactionDetails(txSignature);

      if (txDetails == null) {
        throw Exception('Transaction not confirmed after multiple attempts');
      }

      await _repository.storeTransactionDetails(txDetails);

      await _transactionStorageService.storeLastTransactionSignature(
        txDetails.transaction.toJson()['signatures'][0],
      );

      final double currentBalance = await _repository.getZarpBalance(
        walletProvider.userTokenAccount!.pubkey,
      );
      final double newBalance = currentBalance - (double.parse(amount) / 100);
      await _repository.updateZarpBalance(newBalance);

      unawaited(walletProvider.onPaymentCompleted());

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
