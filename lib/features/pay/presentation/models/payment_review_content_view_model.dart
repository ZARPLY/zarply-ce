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
      if (recipientAddress.isNotEmpty) {
        final String txSignature = await _repository.makeTransaction(
          wallet: wallet,
          recipientAddress: recipientAddress,
          amount: double.parse(amount),
        );

        await Future<void>.delayed(const Duration(seconds: 2));
        final TransactionDetails? txDetails =
            await _repository.getTransactionDetails(txSignature);

        if (txDetails != null) {
          await _repository.storeTransactionDetails(txDetails);

          // Refresh transactions in the wallet provider
          final walletProvider =
              Provider.of<WalletProvider>(context, listen: false);
          await walletProvider.refreshTransactions();
        }

        _hasPaymentBeenMade = true;
        notifyListeners();
      } else {
        _hasPaymentBeenMade = false;
        notifyListeners();
        throw Exception('Wallet or recipient address not found');
      }
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
