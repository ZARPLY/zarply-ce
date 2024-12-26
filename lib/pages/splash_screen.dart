import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';

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
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Chain four 25% rotations with pauses
    _controller
        .animateTo(0.25)
        .then(
          (_) => Future<void>.delayed(const Duration(milliseconds: 500)),
        ) // pause
        .then((_) => _controller.animateTo(0.5))
        .then(
          (_) => Future<void>.delayed(const Duration(milliseconds: 500)),
        ) // pause
        .then((_) => _controller.animateTo(0.75))
        .then(
          (_) => Future<void>.delayed(const Duration(milliseconds: 500)),
        ) // pause
        .then((_) => _controller.animateTo(1));

    _navigateToNextScreen();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNextScreen() async {
    await Future<void>.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    final AuthProvider authProvider =
        Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      context.go('/wallet');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[700],
      body: Center(
        child: RotationTransition(
          turns: _controller,
          child: const Image(
            image: AssetImage('images/zarply_splash.png'),
          ),
        ),
      ),
    );
  }
}
