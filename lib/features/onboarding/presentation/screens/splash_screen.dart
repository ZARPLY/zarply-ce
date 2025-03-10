import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/provider/wallet_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _initializeAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeAndNavigate() async {
    try {
      final WalletProvider walletProvider =
          Provider.of<WalletProvider>(context, listen: false);

      _playAnimation();

      final bool haveWalletAndTokenAccount = await walletProvider.initialize();
      final bool hasPassword = await walletProvider.hasPassword();
      await Future<void>.delayed(const Duration(seconds: 4));

      if (!mounted) return;

      if (!haveWalletAndTokenAccount) {
        context.go('/welcome');
      } else if (!hasPassword) {
        context.go('/create_password');
      } else {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        context.go('/welcome');
      }
    }
  }

  void _playAnimation() {
    const Duration stepDelay = Duration(milliseconds: 500);

    _controller
        .animateTo(0.25)
        .then((_) => Future<void>.delayed(stepDelay))
        .then((_) => _controller.animateTo(0.5))
        .then((_) => Future<void>.delayed(stepDelay))
        .then((_) => _controller.animateTo(0.75))
        .then((_) => Future<void>.delayed(stepDelay))
        .then((_) => _controller.animateTo(1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[700],
      body: Center(
        child: RotationTransition(
          turns: _controller,
          child: const Image(
            image: AssetImage('images/splash.png'),
          ),
        ),
      ),
    );
  }
}
