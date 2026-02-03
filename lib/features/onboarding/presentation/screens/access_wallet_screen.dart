import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/provider/auth_provider.dart';
import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/widgets/loading_button.dart';
import '../widgets/progress_steps.dart';

class AccessWalletScreen extends StatefulWidget {
  const AccessWalletScreen({super.key});

  @override
  State<AccessWalletScreen> createState() => _AccessWalletScreenState();
}

class _AccessWalletScreenState extends State<AccessWalletScreen> {
  bool _isAgreementChecked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentState();
  }

  Future<void> _checkCurrentState() async {
    try {
      // Check if terms were already accepted
      final bool termsAccepted = await SecureStorageService().hasAcceptedTerms();
      if (termsAccepted) {
        setState(() {
          _isAgreementChecked = true;
        });
      }
    } catch (e) {
      // Ignore errors, user will need to check manually
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch URL')),
      );
    }
  }

  Future<void> _handleContinue() async {
    if (!_isAgreementChecked) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // CRITICAL: Check if password exists before proceeding
      // If no password, redirect to create password screen
      try {
        final String pin = await SecureStorageService().getPin();
        if (pin.isEmpty) {
          // No password set - redirect to create password
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please create a password before accessing your wallet'),
              backgroundColor: Colors.orange,
            ),
          );
          if (!mounted) return;
          context.go('/create_password');
          return;
        }
      } catch (e) {
        // Password doesn't exist - redirect to create password
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please create a password before accessing your wallet'),
            backgroundColor: Colors.orange,
          ),
        );
        if (!mounted) return;
        context.go('/create_password');
        return;
      }

      // Get providers for wallet and auth setup
      if (!mounted) return;
      final WalletProvider walletProvider = Provider.of<WalletProvider>(context, listen: false);
      final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Initialize wallet directly here instead of going to splash
      final bool initialized = await walletProvider.initialize();
      if (!initialized) {
        if (mounted) {
          context.go('/welcome');
        }
        return;
      }

      // Accept terms and conditions (only if not already accepted)
      if (!_isAgreementChecked) {
        await SecureStorageService().setTermsAccepted();
      }

      // Login the user
      await authProvider.login();

      // Wait for wallet data to load before proceeding
      await walletProvider.refreshTransactions();
      await walletProvider.fetchAndCacheBalances();

      // Mark onboarding as completed
      await SecureStorageService().setOnboardingCompleted();

      // Mark boot as done
      walletProvider.markBootDone();

      // Navigate to wallet
      if (mounted) {
        context.go('/wallet');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
          child: InkWell(
            onTap: () => context.push('/create_password'),
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
        title: const Padding(
          padding: EdgeInsets.only(right: 24),
          child: ProgressSteps(
            currentStep: 4,
            totalSteps: 4,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Access Your Wallet',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'This layer of security helps your wallet using your default phones security',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Baseline(
                  baseline: 35,
                  baselineType: TextBaseline.alphabetic,
                  child: Checkbox(
                    value: _isAgreementChecked,
                    activeColor: Colors.blue,
                    checkColor: Colors.white,
                    fillColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.blue;
                        }
                        return Colors.white;
                      },
                    ),
                    onChanged: (bool? value) {
                      setState(() {
                        _isAgreementChecked = value ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isAgreementChecked = !_isAgreementChecked;
                      });
                    },
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: <TextSpan>[
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'terms',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _launchUrl(
                                'https://zarply.co.za/terms-conditions',
                              ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'privacy policy',
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => _launchUrl(
                                'https://zarply.co.za/privacy-policy',
                              ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: LoadingButton(
                isLoading: _isLoading,
                type: LoadingButtonType.elevated,
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _isAgreementChecked ? _handleContinue : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
