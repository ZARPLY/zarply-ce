import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solana/solana.dart';

import '../../../../core/models/wallet_balances.dart';
import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../wallet/presentation/models/wallet_view_model.dart';
import '../models/payment_review_content_view_model.dart';
import 'payment_success.dart';

class PaymentReviewContent extends StatefulWidget {
  const PaymentReviewContent({
    required this.amount,
    required this.recipientAddress,
    required this.walletBalance,
    required this.onCancel,
    super.key,
  });

  final String amount;
  final String recipientAddress;
  final double walletBalance;
  final VoidCallback onCancel;

  @override
  State<PaymentReviewContent> createState() => _PaymentReviewContentState();
}

class _PaymentReviewContentState extends State<PaymentReviewContent> {
  late final PaymentReviewContentViewModel _viewModel;
  bool _transactionFailed = false;

  @override
  void initState() {
    super.initState();
    _viewModel = PaymentReviewContentViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _makeTransaction() async {
    // Reset error state on each attempt
    setState(() {
      _transactionFailed = false;
    });

    final Wallet? wallet = Provider.of<WalletProvider>(context, listen: false).wallet;
    final WalletViewModel walletViewModel = Provider.of<WalletViewModel>(context, listen: false);

    if (wallet == null) {
      setState(() {
        _transactionFailed = true;
      });
      await _showErrorDialog('Wallet not found. Please try again.');
      return;
    }

    // Run balance checks at confirm time so the user always gets a clear, human-readable reason.
    final double zarpAmount = Formatters.centsToRands(widget.amount);
    if (zarpAmount > widget.walletBalance) {
      await _showErrorDialog(
        'Insufficient ZARP balance ${Formatters.formatBalanceLabel(widget.walletBalance)}. '
        'Please top up your ZARP before trying again.',
      );
      setState(() {
        _transactionFailed = true;
      });
      return;
    }

    const double minSolNeeded = WalletBalances.minSolForFees;
    final double solBalance = walletViewModel.solBalance;
    if (solBalance < minSolNeeded) {
      await _showErrorDialog(
        'Insufficient SOL for network fees.\n\n'
        'You need at least ${minSolNeeded.toStringAsFixed(3)} SOL but currently have '
        '${solBalance.toStringAsPrecision(3)} SOL.\n\n'
        'Please fund your wallet with a small amount of SOL and try again.',
      );
      setState(() {
        _transactionFailed = true;
      });
      return;
    }

    try {
      await _viewModel.makeTransaction(
        wallet: wallet,
        recipientAddress: widget.recipientAddress,
        amount: widget.amount,
        context: context,
      );
      // PaymentSuccess is now shown inside the sheet via ListenableBuilder
      // and handles its own navigation via the Done button.
    } catch (e, _) {
      if (!mounted) return;

      // Map low-level errors to friendly, human-readable messages.
      String errorMessage = 'Payment failed. Please try again.';
      final String errorString = e.toString().toLowerCase();

      if (errorString.contains('insufficient funds') ||
          errorString.contains('insufficient') ||
          errorString.contains('custom program error: 0x1')) {
        errorMessage = 'Insufficient funds. Please check your ZARP balance and try again.';
      } else if (errorString.contains('recipient does not have a token account')) {
        errorMessage = 'Recipient does not have a ZARP token account. They need to receive ZARP first.';
      } else if (errorString.contains('wallet not found')) {
        errorMessage = 'Wallet not found. Please try again.';
      } else if (errorString.contains('transaction not confirmed')) {
        errorMessage = 'Transaction was sent but not confirmed. Please check your wallet history.';
      } else if (errorString.contains('failed host lookup') ||
          errorString.contains('network is unreachable') ||
          errorString.contains('connection refused') ||
          errorString.contains('socketexception') ||
          errorString.contains('network')) {
        errorMessage =
            'Network connection is not available right now.\n\nPlease check your internet connection and try again.';
      }

      setState(() {
        _transactionFailed = true;
      });

      if (mounted) {
        await _showErrorDialog(errorMessage);
      }
    }
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Payment Failed'),
        content: Text(message),
        actions: <Widget>[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double zarpAmount = Formatters.centsToRands(widget.amount);
    final bool insufficientTokens = zarpAmount > widget.walletBalance;

    const double minSolNeeded = WalletBalances.minSolForFees;
    // Use live SOL balance from the wallet view model so connectivity changes
    // and manual refreshes are reflected immediately.
    final WalletViewModel walletViewModel = Provider.of<WalletViewModel>(context);
    final double solBalance = walletViewModel.solBalance;
    final bool insufficientSol = solBalance < minSolNeeded;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (BuildContext context, _) {
        if (_viewModel.hasPaymentBeenMade) {
          return PaymentSuccess(
            amount: widget.amount,
            recipientAddress: widget.recipientAddress,
          );
        }

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Payment Review',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: _viewModel.isLoading ? null : widget.onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF9BA1AC),
                ),
                child: const Icon(
                  Icons.call_made,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48),
              Text(
                Formatters.formatAmount(zarpAmount),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7F8),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Text(
                  Formatters.shortenAddress(widget.recipientAddress),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const Spacer(),
              Text(
                'Review the details before making a payment. Once complete, this payment cannot be reversed. Confirm to proceed.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (insufficientTokens) ...<Widget>[
                Text(
                  'Insufficient ZARP balance ${Formatters.formatBalanceLabel(widget.walletBalance)}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
              if (insufficientSol) ...<Widget>[
                Text(
                  'Insufficient SOL for fees. '
                  'Need ≥ ${minSolNeeded.toStringAsFixed(3)} SOL '
                  'but have ${solBalance.toStringAsPrecision(3)} SOL.',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: LoadingButton(
                  isLoading: _viewModel.isLoading,
                  // Always run checks on confirm; the button itself stays enabled
                  // unless a transaction is currently in progress.
                  onPressed: _viewModel.isLoading ? null : _makeTransaction,
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(_transactionFailed ? 'Retry' : 'Confirm Payment'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
