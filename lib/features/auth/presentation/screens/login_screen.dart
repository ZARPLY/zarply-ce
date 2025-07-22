import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:provider/provider.dart';

import '../../../../core/provider/auth_provider.dart';
import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/password_input.dart';
import '../../../../core/widgets/clear_icon_button.dart';
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

        await walletProvider.refreshTransactions();

        await walletProvider.fetchAndCacheBalances();

        // routing happens in app_router.dart based on isAuthenticated
        await Provider.of<AuthProvider>(
          context,
          listen: false,
        ).login();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging in: $e'),
        ),
      );
    } finally {
      _viewModel.setIsLoading(value: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginViewModel>.value(
      value: _viewModel,
      child: Consumer<LoginViewModel>(
        builder: (BuildContext context, LoginViewModel viewModel, _) {
          final bool isPasswordTyped =
              viewModel.passwordController.text.isNotEmpty;
          // Only show checkmark if the password matches the stored password (correct password)
          final bool isPasswordCorrect = viewModel.isPasswordCorrect;
          return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              backgroundColor: const Color(0xFF1F75DC),
              elevation: 0,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Close',
                      style: TextStyle(color: Color(0xFF1F75DC), fontSize: 18)),
                ),
              ],
              automaticallyImplyLeading: false,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 20),
                    const Text(
                      'Login',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Welcome back',
                      style:
                          TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Enter your ZARPLY wallet password below',
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 40),
                    Material(
                      elevation: 0,
                      borderRadius: BorderRadius.circular(16),
                      child: TextField(
                        controller: viewModel.passwordController,
                        focusNode: _passwordFocus,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _performLogin(),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          hintText: 'Password',
                          errorText: viewModel.errorMessage.isNotEmpty
                              ? viewModel.errorMessage
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClearIconButton(
                                  controller: viewModel.passwordController),
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: isPasswordCorrect
                                      ? Icon(Icons.check_circle,
                                          color: Colors.green,
                                          key: const ValueKey('valid'))
                                      : const SizedBox(
                                          width: 0,
                                          height: 0,
                                          key: ValueKey('empty')),
                                ),
                              ),
                            ],
                          ),
                        ),
                        style: const TextStyle(fontSize: 18),
                        onChanged: (_) async {
                          setState(() {});
                          // Validate password on change to update checkmark
                          final bool correct =
                              await viewModel.validatePassword();
                          viewModel.setIsPasswordCorrect(correct);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => viewModel.setRememberPassword(
                          value: !viewModel.rememberPassword),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF1F75DC), width: 3),
                            ),
                            child: viewModel.rememberPassword
                                ? Center(
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1F75DC),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          const Text('Remember this device',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: LoadingButton(
                              isLoading: viewModel.isLoading,
                              onPressed: _performLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1F75DC),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                elevation: 8,
                                textStyle: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.w600),
                              ),
                              child: const Text('Login'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: () {
                              /* TODO: Implement forgot password logic */
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 4,
                            width: 120,
                            margin: const EdgeInsets.only(top: 8),
                          ),
                        ],
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
