import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/secure_storage_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPhrase();
  }

  Future<void> _loadPhrase() async {
    final String? stored = await _storage.getRecoveryPhrase();
    setState(() {
      _phrase = stored;
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
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F8F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SingleChildScrollView(
                                child: ImageFiltered(
                                  imageFilter: _obscure
                                    ? ImageFilter.blur(sigmaX: 4, sigmaY: 4)
                                    : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                                  child: Text(
                                    _phrase!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.4,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: -4,
                              right: -4,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                iconSize: 24,
                                icon: Icon(
                                  _obscure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ],
                        ),
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
                    onPressed: () => context.go('/wallet'),
                    child: const Text('Close'),
            ),
          ),
        );
      }
    }
