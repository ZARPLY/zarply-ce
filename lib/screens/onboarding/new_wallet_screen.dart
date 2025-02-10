import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../services/wallet_storage_service.dart';

class NewWalletScreen extends StatefulWidget {
  const NewWalletScreen({super.key});

  @override
  State<NewWalletScreen> createState() => _NewWalletScreenState();
}

class _NewWalletScreenState extends State<NewWalletScreen> {
  final WalletStorageService _storageService = WalletStorageService();
  String? _walletAddress;
  String? _tokenAccountAddress;

  @override
  void initState() {
    super.initState();
    getWalletAddresses();
  }

  Future<void> getWalletAddresses() async {
    _walletAddress = await _storageService.retrieveWalletPublicKey();
    _tokenAccountAddress =
        await _storageService.retrieveAssociatedTokenAccountPublicKey();
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address copied to clipboard')),
      );
    }
  }

  Widget _buildAddressContainer(String label, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _copyToClipboard(address),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD3D9DF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    address,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.copy, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

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
              'Your New Wallet',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Here is your new wallet address. Keep it safe!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            if (_walletAddress != null && _tokenAccountAddress != null)
              Column(
                children: <Widget>[
                  _buildAddressContainer(
                    'Wallet Address:',
                    _walletAddress!,
                  ),
                  const SizedBox(height: 16),
                  _buildAddressContainer(
                    'Token Account:',
                    _tokenAccountAddress!,
                  ),
                ],
              )
            else
              const Center(child: CircularProgressIndicator()),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    _walletAddress != null ? () => context.go('/wallet') : null,
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Go to Wallet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
