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
    _viewModel = SplashViewModel(walletProvider);
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

  Future<void> _navigateToNextScreen() async {
    final String route = await _viewModel.initializeAndGetRoute();
    if (!mounted || _navigated) return;
    _navigated = true;
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
