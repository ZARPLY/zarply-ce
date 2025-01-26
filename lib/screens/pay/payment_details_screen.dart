import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentDetails extends StatefulWidget {
  const PaymentDetails({super.key});

  @override
  State<PaymentDetails> createState() => _PaymentDetailsState();
}

class _PaymentDetailsState extends State<PaymentDetails> {
  final TextEditingController _publicKeyController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isFormValid = false;
  String? _publicKeyError;

  @override
  void initState() {
    super.initState();
    _publicKeyController.addListener(_updateFormValidity);
    _descriptionController.addListener(_updateFormValidity);
  }

  @override
  void dispose() {
    _publicKeyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateFormValidity() {
    final String publicKey = _publicKeyController.text;

    setState(() {
      if (publicKey.isEmpty) {
        _publicKeyError = 'Public key is required';
      } else if (publicKey.length < 32) {
        _publicKeyError = 'Invalid public key format';
      } else {
        _publicKeyError = null;
      }

      _isFormValid =
          _publicKeyError == null && _publicKeyController.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
          child: InkWell(
            onTap: () => context.go('/pay-request'),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEBECEF),
                borderRadius: BorderRadius.circular(80),
              ),
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        title: const Text('Pay'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Column(
                children: <Widget>[
                  Text(
                    'Paste recipients public key',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Initiating a payment',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 250,
              child: TextField(
                controller: _publicKeyController,
                style: const TextStyle(
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Public Key',
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.red,
                    ),
                  ),
                  errorText: _publicKeyError,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 250,
              child: TextField(
                controller: _descriptionController,
                style: const TextStyle(
                  fontSize: 16,
                ),
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isFormValid
                  ? () => context.go(
                        '/payment-amount',
                        extra: _publicKeyController.text,
                      )
                  : null,
              style: ElevatedButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  color: _isFormValid ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
