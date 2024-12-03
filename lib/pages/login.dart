import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:zarply/provider/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // instantiate keys
  final _formKey = GlobalKey<FormState>();

  // instantiate form controllers
  final TextEditingController _pinFieldController = TextEditingController();

  // data storing variables
  String _pinCode = '';

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _pinCode = _pinFieldController.text;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form saved successfully!')),
      );
    }
  }

  @override
  void dispose() {
    _pinFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _pinFieldController,
                decoration: const InputDecoration(labelText: 'Pin Code'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a 5 digit pin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: () {
                  _saveForm();
                  Provider.of<AuthProvider>(context, listen: false)
                      .login(_pinCode);
                },
                child: const Text('Login'),
              ),
              TextButton(
                onPressed: () {
                  context.go('/createAccount');
                },
                child: const Text('Don\'t have an account?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
