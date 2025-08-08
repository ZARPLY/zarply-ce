import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../models/splash_view_model.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late SplashViewModel _viewModel;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    final WalletProvider walletProvider =
        Provider.of<WalletProvider>(context, listen: false);
    _viewModel = SplashViewModel(walletProvider, context);
    _viewModel.initAnimationController(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.playAnimation();
    });
    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _viewModel.disposeAnimationController();
    super.dispose();
  }

  @override
  void deactivate() {
    // Cancel any ongoing animations when the widget is deactivated
    _viewModel.cancelAnimation();
    super.deactivate();
  }

  Future<void> _navigateToNextScreen() async {
    // Minimum splash duration of 2 seconds
    const Duration minSplashDuration = Duration(seconds: 2);

    // Start both the initialization and minimum duration timer
    final Future<String> routeFuture = _viewModel.initializeAndGetRoute();
    final Future<void> minDurationFuture =
        Future<void>.delayed(minSplashDuration);

    // Wait for both to complete
    await Future.wait([routeFuture, minDurationFuture]);

    if (!mounted || _navigated) {
      return;
    }

    _navigated = true;
    final String route = await routeFuture;
    _viewModel.stopAnimation();
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[700],
      body: Center(
        child: RotationTransition(
          turns: _viewModel.animationController,
          child: const Image(
            image: AssetImage('images/splash.png'),
          ),
        ),
      ),
    );
  }
}
