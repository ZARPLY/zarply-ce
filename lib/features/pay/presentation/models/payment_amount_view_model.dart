import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solana/dto.dart';

import '../../../../core/provider/payment_provider.dart';
import '../../../../core/services/transaction_parser_service.dart';
import '../../../wallet/data/repositories/wallet_repository_impl.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';

class PaymentAmountViewModel extends ChangeNotifier {
  PaymentAmountViewModel({
    required this.recipientAddress,
    required this.initialAmount,
    required this.currentWalletAddress,
    required this.context,
  }) {
    if (initialAmount != null) {
      paymentAmountController.text = initialAmount!;
      isFormValid = true;
    }
    paymentAmountController.addListener(_updateFormValidity);
  }

  final WalletRepository _walletRepository = WalletRepositoryImpl();
  final TextEditingController paymentAmountController = TextEditingController();
  final BuildContext context;
  bool isFormValid = false;
  final String recipientAddress;
  final String? initialAmount;
  final String currentWalletAddress;

  TransactionTransferInfo? _cachedLastTransaction;
  bool _hasLoadedTransaction = false;

  Future<TransactionTransferInfo?> getPreviousTransaction() async {
    // Return cached result if already loaded
    if (_hasLoadedTransaction) {
      return _cachedLastTransaction;
    }

    try {
      // Get recipient token account from provider
      final PaymentProvider paymentProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      final ProgramAccount? recipientTokenAccountProgram =
          paymentProvider.recipientTokenAccount;

      if (recipientTokenAccountProgram == null) {
        _cachedLastTransaction = null;
        _hasLoadedTransaction = true;
        return null;
      }

      final String recipientTokenAccount = recipientTokenAccountProgram.pubkey;

      final Map<String, List<TransactionDetails?>> transactions =
          await _walletRepository.getStoredTransactions();

      TransactionTransferInfo? lastTransaction;
      DateTime? lastTransactionDate;

      // Iterate through transactions to find the most recent payment to this recipient
      for (final List<TransactionDetails?> monthTransactions
          in transactions.values) {
        for (final TransactionDetails? tx in monthTransactions) {
          if (tx == null) continue;

          final TransactionTransferInfo? transferInfo =
              TransactionDetailsParser.parseTransferDetails(
            tx,
            currentWalletAddress,
          );

          if (transferInfo != null) {
            // Check if this is an outgoing transaction to the recipient's token account
            final bool isOutgoingToRecipient =
                transferInfo.amount < 0 && // Outgoing transaction
                    transferInfo.recipient != 'myself' &&
                    transferInfo.recipient ==
                        recipientTokenAccount; // Match token account address

            if (isOutgoingToRecipient) {
              if (lastTransactionDate == null ||
                  (transferInfo.timestamp?.isAfter(lastTransactionDate) ??
                      false)) {
                lastTransaction = transferInfo;
                lastTransactionDate = transferInfo.timestamp;
              }
            }
          }
        }
      }

      // Cache the result
      _cachedLastTransaction = lastTransaction;
      _hasLoadedTransaction = true;

      return lastTransaction;
    } catch (e) {
      throw Exception('Error fetching previous transaction: $e');
    }
  }

  void _updateFormValidity() {
    final double amount = double.tryParse(paymentAmountController.text) ?? 0;
    isFormValid = paymentAmountController.text.isNotEmpty && amount >= 500;
    notifyListeners();
  }

  /// Invalidate cached previous transaction data to force a fresh lookup
  void invalidateCache() {
    _cachedLastTransaction = null;
    _hasLoadedTransaction = false;
  }

  @override
  void dispose() {
    paymentAmountController.dispose();
    super.dispose();
  }
}
