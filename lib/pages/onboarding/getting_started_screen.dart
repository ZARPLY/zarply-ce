import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GettingStartedScreen extends StatefulWidget {
  const GettingStartedScreen({super.key});

  @override
  State<GettingStartedScreen> createState() => _GettingStartedScreenState();
}

class _GettingStartedScreenState extends State<GettingStartedScreen> {
  String? _selectedOption;

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
              'Getting Started',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to get started with ZARPLY',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            InkWell(
              onTap: () => setState(() => _selectedOption = 'new'),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _selectedOption == 'new'
                      ? Colors.blue.withOpacity(0.1)
                      : const Color(0xFFF8F8F9),
                  borderRadius: BorderRadius.circular(10),
                  border: _selectedOption == 'new'
                      ? Border.all(color: Colors.blue)
                      : null,
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9BA1AC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Create New Wallet',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Create a new wallet to start using ZARPLY',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => setState(() => _selectedOption = 'restore'),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _selectedOption == 'restore'
                      ? Colors.blue.withOpacity(0.1)
                      : const Color(0xFFF8F8F9),
                  borderRadius: BorderRadius.circular(10),
                  border: _selectedOption == 'restore'
                      ? Border.all(color: Colors.blue)
                      : null,
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9BA1AC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.restore,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Restore Wallet',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Import your existing wallet using recovery phrase',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedOption != null
                    ? () => context.go(
                          _selectedOption == 'new'
                              ? '/new_wallet'
                              : '/restore_wallet',
                        )
                    : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
