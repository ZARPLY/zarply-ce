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

  Future<void> playAnimation() {
    const Duration stepDelay = Duration(milliseconds: 500);

    return animationController
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

      final bool haveWalletAndTokenAccount = await _walletProvider.initialize();
      final bool hasPassword = await _walletProvider.hasPassword();


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
