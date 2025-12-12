import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:solana/solana.dart';
import '../../../../core/provider/payment_provider.dart';
import '../../../../core/widgets/clear_icon_button.dart';
import '../../../../core/widgets/initializer/app_initializer.dart';
import '../models/payment_details_view_model.dart';

class PaymentDetails extends StatefulWidget {
  const PaymentDetails({super.key});

  @override
  State<PaymentDetails> createState() => _PaymentDetailsState();
}

class _PaymentDetailsState extends State<PaymentDetails> {
  late PaymentDetailsViewModel _viewModel;
  bool _didInitViewModel = false;

  final FocusNode _publicKeyFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitViewModel) return;

    final Wallet wallet = AppInitializer.of(context).wallet;
    _viewModel = PaymentDetailsViewModel(ownPublicKey: wallet.address);
    _didInitViewModel = true;
  }

  @override
  void dispose() {
    _publicKeyFocus.dispose();
    _descriptionFocus.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PaymentDetailsViewModel>.value(
      value: _viewModel,
      child: Consumer<PaymentDetailsViewModel>(
        builder: (BuildContext context, PaymentDetailsViewModel viewModel, _) {
          Color borderColor;
          if (viewModel.accountExists == null) {
            borderColor = Colors.grey;
          } else if (viewModel.accountExists!) {
            borderColor = Theme.of(context).primaryColor;
          } else {
            borderColor = Colors.red;
          }

          return Scaffold(
            appBar: AppBar(
              leading: Padding(
                padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
                child: InkWell(
                  onTap: () => context.go('/pay_request'),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBECEF),
                      borderRadius: BorderRadius.circular(80),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
              title: const Text('Pay'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Column(
                      children: <Widget>[
                        Text(
                          'Paste recipients public key',
                          style: Theme.of(context).textTheme.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Initiating a payment',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 250,
                    child: TextField(
                      focusNode: _publicKeyFocus,
                      controller: viewModel.publicKeyController,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _descriptionFocus.requestFocus(),
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Public Key',
                        suffixIcon: ClearIconButton(
                          controller: viewModel.publicKeyController,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: borderColor, width: 2),
                        ),
                        errorText: viewModel.publicKeyError,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (viewModel.accountExists == false) ...<Widget>[
                    const Text(
                      'Account not found on Solana',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: 250,
                    child: TextField(
                      focusNode: _descriptionFocus,
                      controller: viewModel.descriptionController,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _onContinue(viewModel, context),
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: viewModel.canContinue ? () => _onContinue(viewModel, context) : null,
                    style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onContinue(
    PaymentDetailsViewModel viewModel,
    BuildContext context,
  ) async {
    final PaymentProvider paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    await paymentProvider.setRecipientAddress(viewModel.publicKeyController.text);

    if (!context.mounted) return;
    context.go(
      '/payment_amount',
      extra: <String, String>{
        'recipientAddress': viewModel.publicKeyController.text,
        'source': '/payment_details',
      },
    );
  }
}
