import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zarply/pages/about.dart';
import 'package:zarply/pages/beneficiaries.dart';
import 'package:zarply/pages/create_account_screen.dart';
import 'package:zarply/pages/login.dart';
import 'package:zarply/pages/settings.dart';
import 'package:zarply/pages/wallet.dart';
import 'package:zarply/provider/auth_provider.dart';
import 'package:zarply/shared/auth_layout.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/wallet',
    refreshListenable: authProvider,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/createAccount',
        builder: (context, state) => const CreateAccountScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AuthLayout(body: child);
        },
        routes: [
          GoRoute(
            path: '/wallet',
            builder: (context, state) => const WalletScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/beneficiaries',
            builder: (context, state) => const BeneficiariesScreen(),
          ),
          GoRoute(
            path: '/about',
            builder: (context, state) => const AboutScreen(),
          ),
        ],
        redirect: (context, state) {
          final isAuthenticated = authProvider.isAuthenticated;
          return isAuthenticated ? null : '/login';
        },
      ),
    ],
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Text('Page not found: ${state.uri.toString()}'),
        ),
      );
    },
  );
}
