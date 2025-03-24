import 'package:flutter/material.dart';
import '../../../../core/provider/wallet_provider.dart';

class SplashViewModel extends ChangeNotifier {
  SplashViewModel(this._walletProvider);
  final WalletProvider _walletProvider;
  late AnimationController animationController;

  void initAnimationController(TickerProvider vsync) {
    animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: vsync,
    );
  }

  void disposeAnimationController() {
    animationController.dispose();
  }

  void playAnimation() {
    const Duration stepDelay = Duration(milliseconds: 500);

    animationController
        .animateTo(0.25)
        .then((_) => Future<void>.delayed(stepDelay))
        .then((_) => animationController.animateTo(0.5))
        .then((_) => Future<void>.delayed(stepDelay))
        .then((_) => animationController.animateTo(0.75))
        .then((_) => Future<void>.delayed(stepDelay))
        .then((_) => animationController.animateTo(1));
  }

  Future<String> initializeAndGetRoute() async {
    try {
      playAnimation();

      final bool haveWalletAndTokenAccount = await _walletProvider.initialize();
      final bool hasPassword = await _walletProvider.hasPassword();
      await Future<void>.delayed(const Duration(seconds: 4));

      if (!haveWalletAndTokenAccount) {
        return '/welcome';
      } else if (!hasPassword) {
        return '/create_password';
      } else {
        return '/login';
      }
    } catch (e) {
      return '/welcome';
    }
  }
}
