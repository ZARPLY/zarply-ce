import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Your Password?'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'For you to reset you password we recommend to click on the restore button below.',
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Restore Wallet'),
            ),
          ],
        ),
      ),
    );
  }
}
