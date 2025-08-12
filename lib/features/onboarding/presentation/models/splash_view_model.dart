import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/provider/auth_provider.dart';
import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/services/secure_storage_service.dart';

class SplashViewModel extends ChangeNotifier {
  SplashViewModel(this._walletProvider, this._context);
  final WalletProvider _walletProvider;
  final BuildContext _context;
  late AnimationController animationController;
  bool _isDisposed = false;

  AnimationController initAnimationController(TickerProvider vsync) {
    animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: vsync,
    );
    return animationController; // Return the animation controller
  }

  void disposeAnimationController() {
    _isDisposed = true;
    animationController.dispose();
  }

  void cancelAnimation() {
    _isDisposed = true;
    if (animationController.isAnimating) {
      animationController.stop();
    }
  }

  Future<void> playAnimation() async {
    if (!_isDisposed) {
      // Start continuous spinning animation
      animationController.repeat();
    }
  }

  void stopAnimation() {
    if (animationController.isAnimating) {
      animationController.stop();
    }
  }

  Future<String> initializeAndGetRoute() async {
    String route = '/wallet';

    try {
      // Accept terms and conditions
      await SecureStorageService().setTermsAccepted();

      // Initialize wallet
      final bool initialized = await _walletProvider.initialize();
      if (!initialized) {
        return '/welcome';
      }

      // Login the user
      final AuthProvider authProvider =
          Provider.of<AuthProvider>(_context, listen: false);
      await authProvider.login();

      route = '/wallet';
    } catch (e) {
      route = '/welcome';
    } finally {
      _walletProvider.markBootDone();
    }
    return route;
  }
}
