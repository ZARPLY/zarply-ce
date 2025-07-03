import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/provider/wallet_provider.dart';

class ViewTokenAccountScreen extends StatefulWidget {
  const ViewTokenAccountScreen({Key? key}) : super(key: key);

  @override
  State<ViewTokenAccountScreen> createState() => _ViewTokenAccountScreenState();
}

  class _ViewTokenAccountScreenState extends State<ViewTokenAccountScreen> {
    String? _tokenKey;

    @override
    void didChangeDependencies() {
    super.didChangeDependencies();
    _tokenKey = Provider.of<WalletProvider>(context, listen: false)
            .userTokenAccount
            ?.pubkey ??
        '— not set —';
  }

  Future<void> _copyToClipboard() async{
    if (_tokenKey != null) {
      await Clipboard.setData(ClipboardData(text: _tokenKey!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token account key copied')),
      );
    }
  }

  @override 
  Widget build(BuildContext context){ 
    return Scaffold(
      appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/more'),
      ),
      title: const Text('Your Token Account Key'),
    ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Token Account Key',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Copy this public key whenever you need to receive SPL tokens.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _tokenKey!,
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