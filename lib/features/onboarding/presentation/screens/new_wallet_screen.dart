import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/new_wallet_view_model.dart';

class NewWalletScreen extends StatelessWidget {
  const NewWalletScreen({super.key});

  Widget _buildAddressContainer(
    BuildContext context,
    String label,
    String address,
    NewWalletViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => viewModel.copyToClipboard(address, context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD3D9DF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    address,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.copy, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NewWalletViewModel>(
      create: (_) => NewWalletViewModel(),
      child: Consumer<NewWalletViewModel>(
        builder: (BuildContext context, NewWalletViewModel viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              leading: Padding(
                padding:
                    const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
                child: InkWell(
                  onTap: () => context.go('/welcome'),
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
            ),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Your New Wallet',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Here is your new wallet address. Keep it safe!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  if (!viewModel.isLoading &&
                      viewModel.walletAddress != null &&
                      viewModel.tokenAccountAddress != null)
                    Column(
                      children: <Widget>[
                        _buildAddressContainer(
                          context,
                          'Wallet Address:',
                          viewModel.walletAddress!,
                          viewModel,
                        ),
                        const SizedBox(height: 16),
                        _buildAddressContainer(
                          context,
                          'Token Account:',
                          viewModel.tokenAccountAddress!,
                          viewModel,
                        ),
                      ],
                    )
                  else
                    const Center(child: CircularProgressIndicator()),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: viewModel.walletAddress != null
                          ? () => context.go('/wallet')
                          : null,
                      style: ElevatedButton.styleFrom(
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Go to Wallet'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
