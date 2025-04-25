import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/create_password_view_model.dart';
import '../widgets/progress_steps.dart';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  late CreatePasswordViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CreatePasswordViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    final bool success = await _viewModel.createPassword();
    if (success && mounted) {
      context.go('/access_wallet');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creating password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CreatePasswordViewModel>(
      create: (_) => _viewModel,
      child: Consumer<CreatePasswordViewModel>(
        builder: (BuildContext context, CreatePasswordViewModel viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              leading: Padding(
                padding:
                    const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
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
                    controller: viewModel.passwordController,
                    obscureText: true,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                      errorText: viewModel.passwordErrorText,
                      errorMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: viewModel.confirmPasswordController,
                    obscureText: true,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: const OutlineInputBorder(),
                      errorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2),
                      ),
                      errorText: viewModel.confirmErrorText,
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: <Widget>[
                      Radio<bool>(
                        value: true,
                        groupValue: viewModel.isChecked,
                        activeColor: Color(0xFF4169E1),
                        onChanged: (bool? value) {
                          viewModel.setChecked(value: value ?? false);
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
                      onPressed: viewModel.isFormValid ? _handleContinue : null,
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
        },
      ),
    );
  }
}
