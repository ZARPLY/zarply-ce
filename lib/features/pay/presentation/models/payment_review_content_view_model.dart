import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/services/transaction_storage_service.dart';
import '../../../wallet/data/services/wallet_solana_service.dart';

class PaymentReviewContentViewModel extends ChangeNotifier {
  final WalletSolanaService walletSolanaService = WalletSolanaService(
    rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
    websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
  );
  final TransactionStorageService transactionStorageService =
      TransactionStorageService();

  bool _hasPaymentBeenMade = false;
  bool get hasPaymentBeenMade => _hasPaymentBeenMade;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> makeTransaction({
    required Wallet wallet,
    required String recipientAddress,
    required String amount,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (recipientAddress.isNotEmpty) {
        final String txSignature = await walletSolanaService.sendTransaction(
          senderWallet: wallet,
          recipientAddress: recipientAddress,
          zarpAmount: double.parse(amount) / 100,
        );

        await Future<void>.delayed(const Duration(seconds: 2));
        final TransactionDetails? txDetails =
            await walletSolanaService.getTransactionDetails(txSignature);

        if (txDetails != null) {
          final Map<String, List<TransactionDetails?>> stored =
              await transactionStorageService.getStoredTransactions();

          final DateTime txDate = DateTime.fromMillisecondsSinceEpoch(
            txDetails.blockTime! * 1000,
          );
          final String monthKey =
              '${txDate.year}-${txDate.month.toString().padLeft(2, '0')}';

          if (!stored.containsKey(monthKey)) {
            stored[monthKey] = <TransactionDetails?>[];
          }
          stored[monthKey]!.insert(0, txDetails);

          await transactionStorageService.storeTransactions(stored);
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
