import 'package:flutter/material.dart';
import 'package:solana/dto.dart';

import '../../../../core/services/transaction_parser_service.dart';
import '../../../wallet/data/repositories/wallet_repository_impl.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';

class PaymentAmountViewModel extends ChangeNotifier {
  PaymentAmountViewModel({
    required this.recipientAddress,
    this.initialAmount,
    required this.currentWalletAddress, // Add this parameter
  }) {
    if (initialAmount != null) {
      paymentAmountController.text = initialAmount!;
      isFormValid = true;
    }
    paymentAmountController.addListener(_updateFormValidity);
  }

  final WalletRepository _walletRepository = WalletRepositoryImpl();
  final TextEditingController paymentAmountController = TextEditingController();
  bool isFormValid = false;
  final String recipientAddress;
  final String? initialAmount;
  final String currentWalletAddress; // Store wallet address here

  TransactionTransferInfo? lastTransaction;
  DateTime? lastTransactionDate;

  Future<TransactionTransferInfo?> getPreviousTransaction() async {
    lastTransaction = null;
    lastTransactionDate = null;

    final Map<String, List<TransactionDetails?>> transactions =
        await _walletRepository.getStoredTransactions();

    for (final List<TransactionDetails?> monthTransactions
        in transactions.values) {
      for (final TransactionDetails? tx in monthTransactions) {
        if (tx == null) continue;

        // Use the injected wallet address
        final transferInfo = TransactionDetailsParser.parseTransferDetails(
          tx,
          currentWalletAddress, // Now using the properly provided address
        );

        if (transferInfo != null &&
            transferInfo.amount < 0 &&
            transferInfo.recipient == recipientAddress) {
          if (lastTransactionDate == null ||
              (transferInfo.timestamp?.isAfter(lastTransactionDate!) ??
                  false)) {
            lastTransaction = transferInfo;
            lastTransactionDate = transferInfo.timestamp;
          }
        }
      }
    }

    return lastTransaction;
  }

  void _updateFormValidity() {
    final double amount = double.tryParse(paymentAmountController.text) ?? 0;
    isFormValid = paymentAmountController.text.isNotEmpty && amount >= 500;
    notifyListeners();
  }

  @override
  void dispose() {
    paymentAmountController.dispose();
    super.dispose();
  }
}
