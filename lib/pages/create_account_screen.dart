import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zarply/services/secure_storage_service.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  // TODO: get rid of useless comments
  // instantiate keys
  final _formKey = GlobalKey<FormState>();

  // instantiate form controllers
  final TextEditingController _pinFieldController = TextEditingController();

  // instantiate services
  final SecureStorageService _secureStorageService = SecureStorageService();

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
          title: const Text('Create Account'),
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
                        return 'Please enter a pin code';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    children: [
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
              )),
        ));
  }
}
