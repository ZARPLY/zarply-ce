import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';

import '../../../../core/provider/auth_provider.dart';
import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/password_input.dart';
import '../../../onboarding/presentation/screens/welcome_screen.dart';
import '../models/login_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late StreamSubscription<bool> keyboardSubscription;
  late LoginViewModel _viewModel;

  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel();
    final KeyboardVisibilityController keyboardVisibilityController =
        KeyboardVisibilityController();
    keyboardSubscription =
        keyboardVisibilityController.onChange.listen((bool visible) {
      _viewModel.setKeyboardVisibility(visible: visible);
    });
  }

  @override
  void dispose() {
    keyboardSubscription.cancel();
    _passwordFocus.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _performLogin() async {
    _viewModel.setIsLoading(value: true);
    final bool success = await _viewModel.validatePassword();
    try {
      if (success && mounted) {
        final WalletProvider walletProvider = Provider.of<WalletProvider>(
          context,
          listen: false,
        );

        if (!walletProvider.hasWallet) {
          await walletProvider.initialize();
        }

        // Add timeout to prevent infinite loading
        await Future.wait([
          walletProvider.refreshTransactions().timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Transaction refresh timed out');
            },
          ),
          walletProvider.fetchAndCacheBalances().timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Balance fetch timed out');
            },
          ),
        ]);

        // routing happens in app_router.dart based on isAuthenticated
        await Provider.of<AuthProvider>(
          context,
          listen: false,
        ).login();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging in: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        _viewModel.setIsLoading(value: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginViewModel>.value(
      value: _viewModel,
      child: Consumer<LoginViewModel>(
        builder: (BuildContext context, LoginViewModel viewModel, _) {
          return Scaffold(
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Stack(
                      children: <Widget>[
                        ClipPath(
                          clipper: SteeperCurvedBottomClipper(),
                          child: Container(
                            height: 180, // Fixed height
                            color:
                                const Color(0xFF4169E1).withValues(alpha: 0.3),
                          ),
                        ),
                        ClipPath(
                          clipper: CurvedBottomClipper(),
                          child: Container(
                            height: 160, // Slightly less than above
                            color: const Color(0xFF4169E1),
                            child: const Center(
                              child: SizedBox(
                                width: 180,
                                height: 180,
                                child: Image(
                                  image: AssetImage('images/splash.png'),
                                  fit: BoxFit.contain,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
                      child: Stack(
                        children: <Widget>[
                          // Login Form
                          AnimatedOpacity(
                            opacity: viewModel.showSplash ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 500),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Welcome Back!',
                                  style:
                                      Theme.of(context).textTheme.headlineLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 40),
                                PasswordInput(
                                  controller: viewModel.passwordController,
                                  labelText: 'Enter your password',
                                  errorText: viewModel.errorMessage.isNotEmpty
                                      ? viewModel.errorMessage
                                      : null,
                                  focusNode: _passwordFocus,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _performLogin(),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: <Widget>[
                                    Checkbox(
                                      value: viewModel.rememberPassword,
                                      activeColor: const Color(0xFF4169E1),
                                      onChanged: (bool? value) {
                                        if (value != null) {
                                          viewModel.setRememberPassword(
                                            value: value,
                                          );
                                        }
                                      },
                                    ),
                                    const Text('Remember Password'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Splash RichText
                          AnimatedOpacity(
                            opacity: viewModel.showSplash ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 500),
                            child: IgnorePointer(
                              ignoring: viewModel.showSplash,
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    height: 1.2,
                                  ),
                                  children: <InlineSpan>[
                                    TextSpan(text: 'ZARPLY the '),
                                    TextSpan(
                                      text: 'Rand\nstable-coin\nwallet',
                                      style: TextStyle(
                                        color: Color(0xFF1F75DC),
                                      ),
                                    ),
                                    TextSpan(text: ' on Solana.'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!viewModel.isKeyboardVisible)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                        child: SizedBox(
                          width: double.infinity,
                          child: LoadingButton(
                            isLoading: viewModel.isLoading,
                            onPressed:
                                viewModel.showSplash ? null : _performLogin,
                            style: ElevatedButton.styleFrom(
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Login'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
