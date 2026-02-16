import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/provider/payment_provider.dart';
import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/services/transaction_parser_service.dart';
import '../../../../core/services/transaction_storage_service.dart';
import '../../../../core/utils/formatters.dart';
import '../../../wallet/data/services/wallet_solana_service.dart';
import '../../data/repositories/payment_review_content_repository_impl.dart';
import '../../domain/repositories/payment_review_content_repository.dart';

class PaymentReviewContentViewModel extends ChangeNotifier {
  PaymentReviewContentViewModel({
    PaymentReviewContentRepository? repository,
  }) : _repository = repository ?? PaymentReviewContentRepositoryImpl();
  final PaymentReviewContentRepository _repository;
  final TransactionStorageService _transactionStorageService = TransactionStorageService();

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

      final WalletProvider walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final PaymentProvider paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

      // Ensure recipient address is set in provider
      if (paymentProvider.recipientAddress != recipientAddress) {
        await paymentProvider.setRecipientAddress(recipientAddress);
      }

      // Get recipient token account from provider
      ProgramAccount? recipientTokenAccount = paymentProvider.recipientTokenAccount;

      if (recipientTokenAccount == null) {
        // Wait for token account to load if it's currently loading
        if (paymentProvider.isLoadingTokenAccount) {
          // Wait up to 10 seconds for token account to load
          int waitCount = 0;
          while (paymentProvider.isLoadingTokenAccount && waitCount < 20) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            waitCount++;
          }
          recipientTokenAccount = paymentProvider.recipientTokenAccount;
        }

        // Try to fetch the token account if it's still not set
        if (recipientTokenAccount == null) {
          await paymentProvider.setRecipientAddress(recipientAddress);
          recipientTokenAccount = paymentProvider.recipientTokenAccount;
        }

        if (recipientTokenAccount == null) {
          throw Exception(
            'Recipient does not have a token account for this token. ${paymentProvider.tokenAccountError ?? "Please ensure the recipient has a token account."}',
          );
        }
      }

      final double zarpAmount = Formatters.centsToRands(amount);
      // Check actual balance from blockchain before sending
      // At this point, both sender and recipient token accounts are guaranteed non-null

      // Check raw token balance directly to avoid rounding issues with UI amount
      final WalletSolanaService service = await WalletSolanaService.create();
      final TokenAmountResult tokenBalanceResult = await service.getTokenAccountBalanceRaw(
        walletProvider.userTokenAccount!.pubkey,
      );

      final BigInt rawTokenBalance = BigInt.parse(tokenBalanceResult.value.amount);
      final int decimals = tokenBalanceResult.value.decimals;
      final double factor = math.pow(10, decimals).toDouble();
      final int requiredRawTokens = (zarpAmount * factor).round();
      final double actualBalance = rawTokenBalance.toDouble() / factor;

      if (rawTokenBalance < BigInt.from(requiredRawTokens)) {
        throw Exception(
          'Insufficient ZARP balance. You have ${actualBalance.toStringAsFixed(2)} ZARP but need ${zarpAmount.toStringAsFixed(2)} ZARP.',
        );
      }

      final String transactionSignature = await _repository.makeTransaction(
        wallet: wallet,
        senderTokenAccount: walletProvider.userTokenAccount,
        recipientTokenAccount: recipientTokenAccount,
        amount: zarpAmount,
      );

      final TransactionDetails? transactionDetails = await _repository.getTransactionDetails(transactionSignature);

      if (transactionDetails == null) {
        throw Exception('Transaction not confirmed after multiple attempts');
      }

      await _repository.storeTransactionDetails(
        transactionDetails,
        walletAddress: walletProvider.userTokenAccount!.pubkey,
      );

      final String firstSignature =
          TransactionDetailsParser.getFirstSignature(transactionDetails) ??
          (throw StateError('Transaction has no signature'));
      await _transactionStorageService.storeLastTransactionSignature(
        firstSignature,
        walletAddress: walletProvider.userTokenAccount!.pubkey,
      );

      final double currentBalance = await _repository.getZarpBalance(
        walletProvider.userTokenAccount!.pubkey,
      );
      final double newBalance = currentBalance - Formatters.centsToRands(amount);
      await _repository.updateZarpBalance(newBalance);
      await walletProvider.onPaymentCompleted();

      _hasPaymentBeenMade = true;
      notifyListeners();
    } catch (e, _) {
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
