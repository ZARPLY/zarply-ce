import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../widgets/progress_steps.dart';

class BackupWalletScreen extends StatefulWidget {
  const BackupWalletScreen({super.key});

  @override
  State<BackupWalletScreen> createState() => _BackupWalletScreenState();
}

class _BackupWalletScreenState extends State<BackupWalletScreen> {
  final bool _isRecoveryPhraseVisible = false;
  late final String? _recoveryPhrase;

  @override
  void initState() {
    super.initState();
    _recoveryPhrase = Provider.of<WalletProvider>(context, listen: false).recoveryPhrase;
  }

  void _showRevealConfirmationDialog() {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: const Text('Reveal Private Keys'),
          content: const Text('Are you sure you want to reveal your private keys?'),
          actions: <Widget>[
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(context);
                context.go('/private_keys');
              },
              child: const Text('Reveal'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Reveal Private Keys'),
          content: const Text('Are you sure you want to reveal your private keys?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/private_keys');
              },
              child: const Text('Reveal'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_recoveryPhrase == null) {
      return const SizedBox.shrink();
    }

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
            currentStep: 2,
            totalSteps: 4,
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
              'Write these words down offline, and store them securely in order to be able to restore/recover your ZARP wallet.',
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
                                children: _recoveryPhrase.split(' ').asMap().entries.map((MapEntry<int, String> entry) {
                                  return Text(
                                    entry.value,
                                    style: Theme.of(context).textTheme.bodyMedium,
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
                              onPressed: _showRevealConfirmationDialog,
                              icon: Icon(
                                _isRecoveryPhraseVisible ? Icons.visibility_off : Icons.visibility,
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
                    if (context.mounted) {
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
                onPressed: () => context.go('/create_password'),
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
