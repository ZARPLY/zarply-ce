import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/password_input.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({
    required this.nextRoute,
    required this.title,
    super.key,
    this.extra = const <String, dynamic>{},
  });

  final String nextRoute;
  final String title;
  final Map<String, dynamic> extra;

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final TextEditingController _pinController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final String storedPin = await SecureStorageService().getPin();
      if (_pinController.text == storedPin) {
        if (!mounted) return;
        context.go(
          widget.nextRoute,
          extra: widget.extra,
        );
      } else {
        setState(() {
          _errorText = 'Incorrect password';
        });
      }
    } catch (e) {
      setState(() {
        _errorText = 'Error verifying password';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: <Widget>[
            PasswordInput(
              controller: _pinController,
              labelText: 'Enter your password',
              errorText: _errorText,
            ),
            const SizedBox(height: 24),
            LoadingButton(
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _handleContinue,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
