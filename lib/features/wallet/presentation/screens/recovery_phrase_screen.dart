import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/widgets/shared/recovery_phrase_box.dart';

class RecoveryPhraseScreen extends StatefulWidget {
  const RecoveryPhraseScreen({Key? key}) : super(key: key);

  @override
  State<RecoveryPhraseScreen> createState() =>
      _RecoveryPhraseScreenState();
}

class _RecoveryPhraseScreenState
    extends State<RecoveryPhraseScreen> {
  final SecureStorageService _storage = SecureStorageService();
  String? _phrase;
  bool _isLoading = true;
  bool _obscure = true;
  List<String> _words = const [];

  @override
  void initState() {
    super.initState();
    _loadPhrase();
  }

  Future<void> _loadPhrase() async {
    final String? stored = await _storage.getRecoveryPhrase();
    setState(() {
      _phrase = stored;
      _words = stored?.split(' ') ?? [];
      _isLoading = false;
    });
  }

  void _copyToClipboard() {
    if (_phrase == null) return;
    Clipboard.setData(ClipboardData(text: _phrase!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recovery phrase copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/more')),
        title: const Text('Recovery Phrase'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _phrase == null
              ? const Center(
                  child: Text('No recovery phrase found'),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your BIP-39 Recovery Phrase',
                        style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Keep this phrase safe. It is one way to recover your wallet.',
                         style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      RecoveryPhraseBox(
                        words: _words, 
                        obscure: _obscure, 
                        onToggleVisibility: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                         child: TextButton.icon(
                          onPressed: _copyToClipboard,
                          icon: const Icon(Icons.copy, color: Colors.blue),
                          label: const Text(
                            'Copy Phrase',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottomNavigationBar: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: () => context.go('/more'),
                    child: const Text('Close'),
            ),
          ),
        );
      }
    }
