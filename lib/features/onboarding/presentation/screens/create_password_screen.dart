import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/password_input_with_tooltip_strength.dart';
import '../models/create_password_view_model.dart';
import '../widgets/progress_steps.dart';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key, this.extra});

  final Object? extra;

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  late CreatePasswordViewModel _viewModel;
  String? _from;

  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();
  final FocusNode _checkboxFocus = FocusNode();
  final FocusNode _rememberPasswordFocus = FocusNode();

  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _viewModel = CreatePasswordViewModel();
    if (widget.extra is Map<String, dynamic> &&
        (widget.extra as Map<String, dynamic>).containsKey('from')) {
      _from = (widget.extra as Map<String, dynamic>)['from'] as String?;
    }

    _viewModel.passwordController.addListener(_validatePasswords);
    _viewModel.confirmPasswordController.addListener(_validatePasswords);
  }

  void _validatePasswords() {
    setState(() {
      final String pwd = _viewModel.passwordController.text;
      final String confirm = _viewModel.confirmPasswordController.text;
      _confirmPasswordError = confirm.isNotEmpty && pwd != confirm
          ? 'Passwords do not match'
          : null;
    });
  }

  @override
  void dispose() {
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _checkboxFocus.dispose();
    _rememberPasswordFocus.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final bool success = await _viewModel.createPassword();
    if (success && mounted) {
      context.go('/access_wallet');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creating password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CreatePasswordViewModel>.value(
      value: _viewModel,
      child: Consumer<CreatePasswordViewModel>(
        builder: (BuildContext context, CreatePasswordViewModel viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              leading: Padding(
                padding:
                    const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
                child: InkWell(
                  onTap: () => context.go(
                    _from == 'restore' ? '/restore_wallet' : '/backup_wallet',
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBECEF),
                      borderRadius: BorderRadius.circular(80),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.arrow_back_ios, size: 18),
                    ),
                  ),
                ),
              ),
              title: const Padding(
                padding: EdgeInsets.only(right: 24),
                child: ProgressSteps(
                  currentStep: 3,
                  totalSteps: 4,
                ),
              ),
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Create Password',
                                style:
                                    Theme.of(context).textTheme.headlineLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please set a password for your wallet backup and save it somewhere secure. We can\'t reset the password for you.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 24),
                              PasswordInputWithTooltipStrength(
                                controller: viewModel.passwordController,
                                labelText: 'Password',
                                errorText: viewModel.passwordErrorText,
                                focusNode: _passwordFocus,
                                textInputAction: TextInputAction.next,
                                onSubmitted: (_) =>
                                    _confirmFocus.requestFocus(),
                              ),
                              const SizedBox(height: 8),
                              PasswordInputWithTooltipStrength(
                                controller: viewModel.confirmPasswordController,
                                labelText: 'Confirm Password',
                                errorText: viewModel.confirmErrorText,
                                focusNode: _confirmFocus,
                                textInputAction: TextInputAction.done,
                                enableStrengthFeedback: false,
                                onSubmitted: (_) {
                                  FocusScope.of(context).unfocus();
                                  _checkboxFocus.requestFocus();
                                },
                              ),
                              if (_confirmPasswordError != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _confirmPasswordError!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Focus(
                                focusNode: _rememberPasswordFocus,
                                child: Row(
                                  children: <Widget>[
                                    Checkbox(
                                      value: viewModel.rememberPassword,
                                      activeColor: const Color(0xFF4169E1),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      onChanged: (bool? value) {
                                        if (value != null) {
                                          viewModel.setRememberPassword(
                                            value: value,
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Remember Password',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Focus(
                                focusNode: _checkboxFocus,
                                child: Builder(
                                  builder: (BuildContext context) {
                                    final bool hasFocus =
                                        Focus.of(context).hasFocus;
                                    return DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: hasFocus
                                              ? Colors.blue
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Checkbox(
                                            value: viewModel.isChecked,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                            activeColor:
                                                const Color(0xFF4169E1),
                                            onChanged: (bool? value) {
                                              viewModel.setChecked(
                                                value: value ?? false,
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              'I understand that if I lose my password, I will not be able to access my recovery phrase, resulting in the loss of all the funds in my wallet.',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 32),
                              _ImportedWalletInfoBox(),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: LoadingButton(
                                  isLoading: viewModel.isLoading,
                                  onPressed: viewModel.isFormValid
                                      ? _handleContinue
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: const Text('Continue'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ImportedWalletInfoBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final WalletProvider walletProvider =
        Provider.of<WalletProvider>(context, listen: false);
    final String address = walletProvider.wallet?.address ?? '';
    final bool isValid = _isValidSolanaAddress(address);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Imported Wallet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isValid ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isValid ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address.isNotEmpty ? address : 'No wallet address found',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              GestureDetector(
                onTap: () async {
                  const FlutterSecureStorage storage = FlutterSecureStorage();
                  await storage.deleteAll();
                  if (context.mounted) {
                    context.go('/restore_wallet');
                  }
                },
                child: const Text(
                  'Import different wallet',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper for Solana address validation (simple base58 length check)
bool _isValidSolanaAddress(String address) {
  // Solana addresses are base58 and usually 32-44 chars
  final RegExp base58 = RegExp(r'^[1-9A-HJ-NP-Za-km-z]{32,44} ?$');
  return address.isNotEmpty && base58.hasMatch(address);
}
