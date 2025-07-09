import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:solana/dto.dart'; 
import 'package:solana/solana.dart';
import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/initializer/app_initializer.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../pay/presentation/models/payment_review_content_view_model.dart';

class PaymentRequestDetailsScreen extends StatefulWidget {
  const PaymentRequestDetailsScreen({
    required this.amount,
    required this.recipientAddress,
    Key? key,
  }) : super(key: key);

  final String amount;
  final String recipientAddress;

  @override
  State<PaymentRequestDetailsScreen> createState() =>
      _PaymentRequestDetailsScreenState();
}

class _PaymentRequestDetailsScreenState
    extends State<PaymentRequestDetailsScreen> {
  bool _isProcessing = false;
  bool _showCheckmarkFrom = false;
  bool _showCheckmarkTo = false;
  late final PaymentReviewContentViewModel _viewModel;

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

  double get _amountInZarp => (double.tryParse(widget.amount) ?? 0) / 100;
  double get _walletZarpBalance => AppInitializer.of(context).walletBalance;
  double get _walletSolBalance  => AppInitializer.of(context).solBalance;

  bool get _insufficientTokens  => _amountInZarp > _walletZarpBalance;
  bool get _insufficientSol => _walletSolBalance < 0.001;

  bool get _payingSelf {
    final WalletProvider wp = Provider.of<WalletProvider>(context, listen: false);
    final Wallet? w = wp.wallet;
    final ProgramAccount? token  = wp.userTokenAccount;
    final String dest = widget.recipientAddress;
    return dest == w?.address || dest == token?.pubkey;
  }
  bool get _buttonDisabled => _isProcessing || _insufficientTokens || _insufficientSol || _payingSelf;

  Future<void> _handlePaymentConfirmation() async {
    if (_buttonDisabled) return;
    setState(() =>_isProcessing = true);

    final WalletProvider walletProvider =
        Provider.of<WalletProvider>(context, listen: false);
    final Wallet? wallet = walletProvider.wallet;

    if (wallet == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Wallet not found. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() =>_isProcessing = false);
      return;
    }

    try {
      await _viewModel.makeTransaction(
        wallet: wallet,
        recipientAddress: widget.recipientAddress,
        amount: widget.amount,
        context: context,
      );
      if (mounted) await _showSuccessBottomSheet();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
  
  Future<void> _showSuccessBottomSheet() {
    return showModalBottomSheet(
      context: context,
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Successful',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your payment has been processed successfully',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(
    BuildContext context,
    String text,
    bool isFrom,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied to clipboard')),
    );
    setState(() {
      if (isFrom) {
        _showCheckmarkFrom = true;
      } else {
        _showCheckmarkTo = true;
      }
    });
    await Future<void>.delayed(const Duration(seconds: 2)); 
      if (!mounted) return;
      setState(() {
        if (isFrom) {
          _showCheckmarkFrom = false;
        } else {
          _showCheckmarkTo = false;
        }
      });
    }
 
  Widget _buildCopyableAddress(String label, String address, bool isFrom) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _copyToClipboard(context, address, isFrom),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    address,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    softWrap: true,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: (isFrom ? _showCheckmarkFrom : _showCheckmarkTo)
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.grey.withValues(alpha: 0.8),
                          key: const ValueKey<String>('check'),
                        )
                      : Icon(
                          Icons.copy,
                          size: 14,
                          color: Colors.grey.withValues(alpha: 0.8),
                          key: const ValueKey<String>('copy'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double amountInRands = double.parse(widget.amount) / 100;
    final WalletProvider walletProvider =
        Provider.of<WalletProvider>(context, listen: false);
    final Wallet? wallet = walletProvider.wallet;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/wallet'),
        ),
        title: const Text('Payment Review'),
        actions: <Widget>[
          TextButton(
            onPressed: () => context.go('/wallet'),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.blue,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text("You're about to pay",
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          Formatters.formatAmount(amountInRands),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward, color: Colors.white),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Center(
                    child: _buildCopyableAddress(
                      'From account',
                      wallet?.address ?? '',
                      true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: _buildCopyableAddress(
                      'To account',
                      widget.recipientAddress,
                      false,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_payingSelf) ...[
                    const Text('You cannot pay yourself',
                        style: TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                  ],
                  if (_insufficientTokens) ...[
                    Text(
                      'Insufficient ZARP balance '
                      '(Balance: ${Formatters.formatAmount(_walletZarpBalance)})',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_insufficientSol) ...[
                    Text(
                      'Insufficient SOL for fees (need ≥ 0.001 SOL, '
                      'have ${_walletSolBalance.toStringAsPrecision(3)}).',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: LoadingButton(
                      isLoading: _isProcessing,
                      onPressed: _buttonDisabled ? null : _handlePaymentConfirmation,
                      child: const Text('Confirm Payment'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}