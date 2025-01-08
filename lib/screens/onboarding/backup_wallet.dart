import 'dart:ui';

import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../provider/wallet_provider.dart';
import '../../widgets/onboarding/progress_steps.dart';

class BackupWalletScreen extends StatefulWidget {
  const BackupWalletScreen({super.key});

  @override
  State<BackupWalletScreen> createState() => _BackupWalletScreenState();
}

class _BackupWalletScreenState extends State<BackupWalletScreen> {
  bool _isRecoveryPhraseVisible = false;
  late final String _recoveryPhrase;

  @override
  void initState() {
    super.initState();
    _recoveryPhrase = bip39.generateMnemonic();
  }

  void confirmBackupAndProceed() {
    Provider.of<WalletProvider>(context, listen: false)
        .setRecoveryPhrase(_recoveryPhrase);
    context.go('/create_password');
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
        title: const Padding(
          padding: EdgeInsets.only(right: 24),
          child: ProgressSteps(
            currentStep: 0,
            totalSteps: 3,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Back up your wallet',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Your secret recovery phrase is used to recover your wallet if you lose your phone or switch to a different wallet.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Save these 12-14 words in a secure location such as a password manager and never share them with anyone.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD3D9DF)),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: ImageFiltered(
                            imageFilter: _isRecoveryPhraseVisible
                                ? ImageFilter.blur()
                                : ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _recoveryPhrase
                                    .split(' ')
                                    .asMap()
                                    .entries
                                    .map((MapEntry<int, String> entry) {
                                  return Text(
                                    entry.value,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: const BoxDecoration(
                            color: Color(0xFFD3D9DF),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          child: Center(
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  _isRecoveryPhraseVisible =
                                      !_isRecoveryPhraseVisible;
                                });
                              },
                              icon: Icon(
                                _isRecoveryPhraseVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: _recoveryPhrase),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Recovery phrase copied to clipboard',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text(
                    'Copy to clipboard',
                    style: TextStyle(
                      color: Color(0xFF636E80),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: confirmBackupAndProceed,
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('I have backed up my wallet'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
