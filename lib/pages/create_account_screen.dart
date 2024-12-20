import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/secure_storage_service.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _pinFieldController = TextEditingController();

  final SecureStorageService _secureStorageService = SecureStorageService();

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
        title: const Text('Create Account'),
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
                    return 'Please enter a pin code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      _saveForm();
                      _secureStorageService.savePin(_pinCode);
                      context.go('/login');
                    },
                    child: const Text('Create Account'),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      context.go('/login');
                    },
                    child: const Text('Back'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
