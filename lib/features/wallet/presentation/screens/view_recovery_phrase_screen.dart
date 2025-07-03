import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/secure_storage_service.dart';

class ViewRecoveryPhraseScreen extends StatefulWidget {
  const ViewRecoveryPhraseScreen({Key? key}) : super(key: key);

  @override
  State<ViewRecoveryPhraseScreen> createState() =>
      _ViewRecoveryPhraseScreenState();
}

class _ViewRecoveryPhraseScreenState
    extends State<ViewRecoveryPhraseScreen> {
  late Future<String> _phraseFuture;
  String? _phrase;

  @override
  void initState() {
    super.initState();
    _phraseFuture = SecureStorageService()
        .getRecoveryPhrase()
        .then((value) {
          _phrase = value;
          return value;
        });
  }

  Future<void> _copyToClipboard() async {
    if (_phrase != null) {
      await Clipboard.setData(ClipboardData(text: _phrase!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recovery phrase copied')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/more'),
          ),
        title: const Text('Your Recovery Phrase'),
      ),
      body: FutureBuilder<String>(
        future: _phraseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading phrase:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          final phrase = snapshot.data!.trim().isNotEmpty
              ? snapshot.data!
              : '— no phrase found —';
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Recovery Phrase',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep this phrase safe. It is one way to recover your wallet.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          phrase,
                          style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Colors.blue),
                        onPressed: _copyToClipboard,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => context.go('/wallet'),
          child: const Text('Close'),
        ),
      ),
    );
  }
}