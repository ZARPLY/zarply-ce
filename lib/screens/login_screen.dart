import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:go_router/go_router.dart';
import '../services/secure_storage_service.dart';
import 'onboarding/welcome_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late StreamSubscription<bool> keyboardSubscription;
  final TextEditingController _passwordController = TextEditingController();
  final SecureStorageService _secureStorage = SecureStorageService();
  String _errorMessage = '';
  bool _showSplash = true;
  bool isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    final KeyboardVisibilityController keyboardVisibilityController =
        KeyboardVisibilityController();
    keyboardSubscription =
        keyboardVisibilityController.onChange.listen((bool visible) {
      setState(() {
        isKeyboardVisible = visible;
      });
    });
    _startSplashTimer();
  }

  void _startSplashTimer() {
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  Future<void> _validatePassword() async {
    try {
      final String storedPin = await _secureStorage.getPin();
      if (_passwordController.text == storedPin) {
        setState(() {
          _errorMessage = '';
        });
        if (mounted) {
          context.go('/wallet');
        }
      } else {
        setState(() {
          _errorMessage = 'Incorrect password';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error validating password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Stack(
            children: <Widget>[
              ClipPath(
                clipper: SteeperCurvedBottomClipper(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.43,
                  color: const Color(0xFF4169E1).withOpacity(0.3),
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
                  opacity: _showSplash ? 0.0 : 1.0,
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
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Enter your password',
                          border: const OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.red,
                            ),
                          ),
                          errorText:
                              _errorMessage.isNotEmpty ? _errorMessage : null,
                        ),
                      ),
                    ],
                  ),
                ),
                // Splash RichText
                AnimatedOpacity(
                  opacity: _showSplash ? 1.0 : 0.0,
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
          if (!isKeyboardVisible)
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 48),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showSplash
                      ? null
                      : () async {
                          await _validatePassword();
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
  }

  @override
  void dispose() {
    _passwordController.dispose();
    keyboardSubscription.cancel();
    super.dispose();
  }
}
