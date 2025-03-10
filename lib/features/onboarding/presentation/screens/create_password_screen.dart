import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/secure_storage_service.dart';
import '../widgets/progress_steps.dart';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final SecureStorageService _secureStorage = SecureStorageService();
  bool _isChecked = false;
  bool _isFormValid = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      if (_passwordController.text.isEmpty ||
          _confirmPasswordController.text.isEmpty) {
        _errorText = null;
        _isFormValid = false;
      } else if (_passwordController.text != _confirmPasswordController.text) {
        _errorText = 'Passwords do not match';
        _isFormValid = false;
      } else {
        _errorText = null;
        _isFormValid = _isChecked;
      }
    });
  }

  Future<void> _createPassword() async {
    if (!_isFormValid) return;

    try {
      await _secureStorage.savePin(_passwordController.text);

      if (mounted) {
        context.go('/access_wallet');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating password: $e')),
        );
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
            onTap: () => context.go('/welcome'),
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
            currentStep: 1,
            totalSteps: 3,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Create Password',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Please set a password for your wallet backup and save it somewhere secure. We can\'t reset the password for you.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              style: const TextStyle(
                fontSize: 14,
              ),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: const OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.red,
                  ),
                ),
                errorText: _errorText,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Radio<bool>(
                  value: true,
                  groupValue: _isChecked,
                  onChanged: (bool? value) {
                    setState(() {
                      _isChecked = value ?? false;
                      _validateForm();
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    'I understand that if I lose my password, I will not be able to access my recovery phrase, resulting in the loss of all the funds in my wallet.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isFormValid ? _createPassword : null,
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
    );
  }
}
