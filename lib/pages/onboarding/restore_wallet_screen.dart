import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RestoreWalletScreen extends StatefulWidget {
  const RestoreWalletScreen({super.key});

  @override
  State<RestoreWalletScreen> createState() => _RestoreWalletScreenState();
}

class _RestoreWalletScreenState extends State<RestoreWalletScreen> {
  final TextEditingController _phraseController = TextEditingController();
  bool _isFormValid = false;

  @override
  void initState() {
    super.initState();
    _phraseController.addListener(_updateFormValidity);
  }

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  void _updateFormValidity() {
    setState(() {
      // Basic validation - can be enhanced to check for valid BIP39 phrase
      _isFormValid = _phraseController.text.trim().isNotEmpty;
    });
  }

  Future<void> _restoreWallet() async {
    // TODO: Implement wallet restoration logic
    if (mounted) {
      context.go('/wallet');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
          child: InkWell(
            onTap: () => context.go('/getting_started'),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Restore Wallet',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your recovery phrase to restore your wallet',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _phraseController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Recovery Phrase',
                hintText: 'Enter your 12 or 24 word recovery phrase',
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isFormValid ? _restoreWallet : null,
                child: const Text('Restore Wallet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
