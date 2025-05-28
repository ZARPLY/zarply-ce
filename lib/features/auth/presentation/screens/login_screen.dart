import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/provider/auth_provider.dart';
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
  void dispose(){
    keyboardSubscription.cancel();
    _passwordFocus.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _performLogin() async {
    final bool success = await _viewModel.validatePassword();
    if (success && mounted) {
      context.go('/wallet');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginViewModel>.value(
      value: _viewModel,
      child: Consumer<LoginViewModel>(
        builder: (BuildContext context, LoginViewModel viewModel, _) {
          return Scaffold(
            body: Column(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    ClipPath(
                      clipper: SteeperCurvedBottomClipper(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.43,
                        color: const Color(0xFF4169E1).withValues(alpha: 0.3),
                      ),
                    ),
                    ClipPath(
                      clipper: CurvedBottomClipper(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.40,
                        color: const Color(0xFF4169E1),
                        child: const Center(
                          child: SizedBox(
                            width: 300,
                            height: 300,
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
                              style: Theme.of(context).textTheme.headlineLarge,
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
                              onSubmitted: (_) =>  _performLogin(),
                            ),
                          ],
                        ),
                      ),
                      // Splash RichText
                      AnimatedOpacity(
                        opacity: viewModel.showSplash ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 500),
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
                    ],
                  ),
                ),
                const Spacer(),
                if (!viewModel.isKeyboardVisible)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: viewModel.showSplash
                            ? null
                            : () async {
                                final bool success =
                                    await viewModel.validatePassword();
                                if (success && mounted) {
                                  await Provider.of<AuthProvider>(context, listen: false).login();
                                  context.go('/wallet');
                                }
                              },
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
          );
        },
      ),
    );
  }
}
