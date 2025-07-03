import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/widgets/password_input.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({
    Key? key,
    required this.title,
    required this.nextRoute,
    }) : super(key: key);

    final String title;
    final String nextRoute;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final SecureStorageService _secureStorage = SecureStorageService();

  String? _errorText;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onContinue(String nextRoute) async {
    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      final String storedPin = await _secureStorage.getPin();
      if (_passwordController.text == storedPin) {
        if (mounted) context.go(nextRoute);
      } else {
        setState(() {
          _errorText = 'Incorrect password';
        });
      }
    } on Exception {
      setState(() {
        _errorText = 'Error checking password';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.title;
    final String nextRoute = widget.nextRoute;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Enter your password to continue',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            PasswordInput(
              controller: _passwordController,
              labelText: 'Password',
              errorText: _errorText,
              onSubmitted: (_) => _onContinue(nextRoute),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () => _onContinue(nextRoute),
               style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
               ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
