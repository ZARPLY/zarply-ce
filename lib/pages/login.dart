import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _pinFieldController = TextEditingController();

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
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _pinFieldController,
                decoration: const InputDecoration(labelText: 'Pin Code'),
                keyboardType: TextInputType.phone,
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a 5 digit pin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
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
