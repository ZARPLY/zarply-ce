import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:solana/solana.dart';
import '../../../../core/provider/wallet_provider.dart';
import '../models/payment_details_view_model.dart';

class PaymentDetails extends StatefulWidget {
  const PaymentDetails({super.key});

  @override
  State<PaymentDetails> createState() => _PaymentDetailsState();
}

class _PaymentDetailsState extends State<PaymentDetails> {
  late PaymentDetailsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final Ed25519HDKeyPair? wallet = Provider.of<WalletProvider>(context, listen: false).wallet;
    final String ownPubKey = wallet?.address ?? '';
    _viewModel = PaymentDetailsViewModel(ownPublicKey: ownPubKey);
  }

  @override
  void dispose() {
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
          } else if (viewModel.accountExists == true) {
            borderColor = Theme.of(context).primaryColor;
          } else {
            borderColor = Colors.red;
          }
          return Scaffold(
            appBar: AppBar(
              leading: Padding(
                padding:
                    const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
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
                      controller: viewModel.publicKeyController,
                      decoration: InputDecoration(
                        labelText: 'Public Key',
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: borderColor
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: borderColor,
                          ),
                        ),
                        errorText: viewModel.publicKeyError,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (viewModel.accountExists == false) ...[
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
                      controller: viewModel.descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: viewModel.canContinue
                        ? () => context.go(
                              '/payment_amount',
                              extra: <String, String>{
                                'recipientAddress':
                                    viewModel.publicKeyController.text,
                                'source': '/payment_details',
                              },
                            )
                        : null,
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
}
