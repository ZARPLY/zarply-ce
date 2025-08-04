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
  bool _isPasswordVisible = false;

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
            backgroundColor: Colors.white,
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 10),
                    // Welcome back title
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 16),
                    // Instructional text
                    const Text(
                      'Enter your ZARPLY wallet password below',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 40),
                    // Password input field
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: viewModel.passwordController,
                        focusNode: _passwordFocus,
                        obscureText: !_isPasswordVisible,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _performLogin(),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          border: InputBorder.none,
                          hintText: 'Password',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                          errorText: viewModel.errorMessage.isNotEmpty
                              ? viewModel.errorMessage
                              : null,
                          filled: false,
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // View/Hide password button
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0),
                                  child: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                ),
                              ),
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
                        style: const TextStyle(fontSize: 16),
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
                    // Remember this device option
                    GestureDetector(
                      onTap: () => viewModel.setRememberPassword(
                          value: !viewModel.rememberPassword),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: viewModel.rememberPassword
                                  ? const Color(0xFF1F75DC)
                                  : Colors.transparent,
                              border: Border.all(
                                color: const Color(0xFF1F75DC),
                                width: 2,
                              ),
                            ),
                            child: viewModel.rememberPassword
                                ? const Center(
                                    child: Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Remember this device',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Continue button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: LoadingButton(
                              isLoading: viewModel.isLoading,
                              onPressed: _performLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 216, 227, 250),
                                foregroundColor: Colors.grey.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Continue'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Forgot Password link
                          GestureDetector(
                            onTap: () {
                              /* TODO: Implement forgot password logic */
                            },
                            child: const Text(
                              'Forgot Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
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
