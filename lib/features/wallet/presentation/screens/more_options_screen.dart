import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/provider/wallet_provider.dart';

class MoreOptionsScreen extends StatelessWidget {
  const MoreOptionsScreen({super.key});

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Public key copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final WalletProvider walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final String publicKey = walletProvider.wallet?.address ?? '— not set —';

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        leading: BackButton(onPressed: () => context.go('/wallet'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wallet Public Key',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
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
                      publicKey,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.blue),
                    onPressed: () => _copyToClipboard(context, publicKey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            ListTile(
              leading: const Icon(Icons.phonelink_lock),
              title: const Text('BIP39 Recovery Phrase'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(
                '/unlock',
                extra: <String, String>{
                  'nextRoute': '/recovery_phrase',
                  'title': 'Unlock Your Wallet',
                },
              ),
            ),

            ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text('View Private Keys'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(
                '/unlock',
                extra: <String, dynamic>{
                  'nextRoute': '/private_keys',
                  'title': 'Unlock Your Wallet',
                  'hideProgress': true,
                },
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
      // Close button at bottom
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
