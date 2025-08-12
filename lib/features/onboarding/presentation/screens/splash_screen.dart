import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/provider/auth_provider.dart';
import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/services/secure_storage_service.dart';
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

    // Check if we should skip splash and go directly to destination
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    final WalletProvider walletProvider =
        Provider.of<WalletProvider>(context, listen: false);

    if (walletProvider.hasWallet) {
      // Check if onboarding is completed
      final bool onboardingCompleted =
          await SecureStorageService().isOnboardingCompleted();

      if (onboardingCompleted) {
        // User has completed onboarding, check if they're authenticated
        final AuthProvider authProvider =
            Provider.of<AuthProvider>(context, listen: false);

        if (authProvider.isAuthenticated) {
          // User is authenticated, go to wallet immediately
          if (mounted) {
            context.go('/wallet');
          }
          return;
        } else {
          // User has completed onboarding but not authenticated, go to login immediately
          if (mounted) {
            context.go('/login');
          }
          return;
        }
      } else {
        // User has wallet but onboarding is not completed
        // Check if they have a password - if yes, they've completed setup and should go to login
        try {
          final String? pin = await SecureStorageService().getPin();
          if (pin != null && pin.isNotEmpty) {
            // User has password - they've completed the setup
            // If they're not authenticated, they should go to login, not continue onboarding
            if (mounted) {
              context.go('/login');
            }
            return;
          } else {
            // User has wallet but no password, go to create password
            if (mounted) {
              context.go('/create_password');
            }
            return;
          }
        } catch (e) {
          // Error checking password, assume user needs to create password
          if (mounted) {
            context.go('/create_password');
          }
          return;
        }
      }
    }

    // If we get here, user has no wallet - this is first time app launch
    // Show splash screen and continue with normal flow
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
    // This method is only called for first-time app launch
    // Minimum splash duration of 2 seconds
    const Duration minSplashDuration = Duration(seconds: 2);

    // First time setup - start both the initialization and minimum duration timer
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
