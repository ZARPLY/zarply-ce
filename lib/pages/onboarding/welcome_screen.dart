import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Logo
            const SizedBox(
              width: 120,
              height: 120,
              child: Image(
                image: AssetImage('images/zarply_logo.png'),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 48),
            // Welcome Text
            Text(
              'Welcome to ZARPLY',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // App Description
            Text(
              'Your gateway to seamless digital payments. Send and receive money instantly using blockchain technology.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/getting_started'),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
