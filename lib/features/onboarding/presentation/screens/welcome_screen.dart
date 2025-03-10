import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../../../wallet/data/services/wallet_solana_service.dart';
import '../../../wallet/data/services/wallet_storage_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final WalletSolanaService _walletService = WalletSolanaService(
    rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
    websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
  );
  final WalletStorageService _storageService = WalletStorageService();
  bool _isLoading = false;

  Future<void> _createAndStoreWallet(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String recoveryPhrase = bip39.generateMnemonic();

      Provider.of<WalletProvider>(context, listen: false)
          .setRecoveryPhrase(recoveryPhrase);

      final Wallet wallet =
          await _walletService.createWalletFromMnemonic(recoveryPhrase);
      await Future<void>.delayed(const Duration(seconds: 2));
      final ProgramAccount tokenAccount =
          await _walletService.createAssociatedTokenAccount(wallet);

      await _storageService.saveWalletPrivateKey(wallet);
      await _storageService.saveWalletPublicKey(wallet);
      await _storageService.saveAssociatedTokenAccountPublicKey(tokenAccount);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          Stack(
            children: <Widget>[
              ClipPath(
                clipper: SteeperCurvedBottomClipper(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.43,
                  color: const Color(0xFF4169E1).withOpacity(0.3),
                ),
              ),
              ClipPath(
                clipper: CurvedBottomClipper(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.40,
                  color: const Color(0xFF4169E1),
                  child: const Center(
                    child: SizedBox(
                      width: 300,
                      height: 300,
                      child: Image(
                        image: AssetImage('images/splash.png'),
                        fit: BoxFit.contain,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 20, 32, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.2,
                    ),
                    children: <InlineSpan>[
                      TextSpan(text: 'ZARPLY the '),
                      TextSpan(
                        text: 'Rand\nstable-coin\nwallet',
                        style: TextStyle(
                          color: Color(0xFF1F75DC), // Purple color
                        ),
                      ),
                      TextSpan(text: ' on Solana.'),
                    ],
                  ),
                ),
                const SizedBox(height: 64),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            await _createAndStoreWallet(context);
                            if (!context.mounted) return;
                            context.go('/backup_wallet');
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4169E1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create new wallet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      context.go('/restore_wallet');
                    },
                    child: const Text(
                      'I already have a wallet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF181C1F),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0, size.height * 0.90);

    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 1.1,
      size.width,
      size.height * 0.85,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class SteeperCurvedBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0, size.height * 0.90);

    path.quadraticBezierTo(
      size.width * 0.45,
      size.height * 1.08,
      size.width,
      size.height * 0.90,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
