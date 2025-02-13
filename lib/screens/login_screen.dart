import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/secure_storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final SecureStorageService _secureStorage = SecureStorageService();
  String _errorMessage = '';

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
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your password to continue',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(
                fontSize: 14,
              ),
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.red,
                  ),
                ),
                errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
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
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
