import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/widgets/loading_button.dart';
import '../models/welcome_view_model.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late WelcomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = WelcomeViewModel();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WelcomeViewModel>(
      create: (_) => _viewModel,
      child: Consumer<WelcomeViewModel>(
        builder: (BuildContext context, WelcomeViewModel viewModel, _) {
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
                        color: const Color(0xFF4169E1).withValues(alpha: 0.3),
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
                        child: LoadingButton(
                          isLoading: viewModel.isLoading,
                          onPressed: () async {
                            final WalletProvider walletProvider =
                                Provider.of<WalletProvider>(
                              context,
                              listen: false,
                            );
                            final bool success = await viewModel
                                .createAndStoreWallet(walletProvider);
                            if (!context.mounted) return;

                            if (success) {
                              context.go('/backup_wallet');
                            } else if (viewModel.errorMessage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(viewModel.errorMessage!),
                                  backgroundColor: Colors.red.shade700,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 5),
                                  action: SnackBarAction(
                                    label: 'Dismiss',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                      viewModel.clearError();
                                    },
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4169E1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
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
        },
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
