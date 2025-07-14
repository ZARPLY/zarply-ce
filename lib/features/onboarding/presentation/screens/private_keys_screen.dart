import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/private_keys_view_model.dart';
import '../widgets/progress_steps.dart';

class PrivateKeysScreen extends StatelessWidget {
  const PrivateKeysScreen({super.key, this.hideProgress = false});
  final bool hideProgress;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PrivateKeysViewModel>(
      create: (_) => PrivateKeysViewModel(),
      child: Consumer<PrivateKeysViewModel>(
        builder: (BuildContext context, PrivateKeysViewModel viewModel, _) {
          return PrivateKeysView(
            viewModel: viewModel,
            hideProgress: hideProgress,
          );
        },
      ),
    );
  }
}

class PrivateKeysView extends StatelessWidget {
  const PrivateKeysView({
    required this.viewModel,
    required this.hideProgress,
    super.key,
  });

  final PrivateKeysViewModel viewModel;
  final bool hideProgress;

  @override
  Widget build(BuildContext context) {
    if (viewModel.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(viewModel.errorMessage!)),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
          child: InkWell(
            onTap: () => context.go(hideProgress ? '/more' : '/backup_wallet'),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.arrow_back),
            ),
          ),
        ),
        title: hideProgress
            ? const SizedBox.shrink()
            : const ProgressSteps(currentStep: 1, totalSteps: 3),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Wallet Private Keys',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 24),
            viewModel.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue,
                    ),
                  )
                : _buildKeysContent(context, viewModel),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    context.go(hideProgress ? '/more' : '/backup_wallet'),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeysContent(
    BuildContext context,
    PrivateKeysViewModel viewModel,
  ) {
    return Column(
      children: <Widget>[
        Column(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: <Widget>[
                  const Image(
                    image: AssetImage('images/zarp.png'),
                    fit: BoxFit.contain,
                    width: 30,
                    height: 30,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      viewModel.walletAddress ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: <Widget>[
                  const Image(
                    image: AssetImage('images/solana.png'),
                    fit: BoxFit.contain,
                    width: 30,
                    height: 30,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      viewModel.tokenAccountAddress ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Important Security Notice',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[900],
                              ),
                            ),
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange[700],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your private keys are the most critical component for accessing and managing your ZARP wallet.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton.icon(
                  onPressed: () => viewModel.copyKeysToClipboard(context),
                  icon: const Icon(Icons.copy, color: Colors.blue),
                  iconAlignment: IconAlignment.end,
                  label: const Text(
                    'Copy keys',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
