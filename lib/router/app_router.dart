import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../provider/wallet_provider.dart';
import '../screens/onboarding/access_wallet_screen.dart';
import '../screens/onboarding/backup_wallet.dart';
import '../screens/onboarding/create_password_screen.dart';
import '../screens/onboarding/new_wallet_screen.dart';
import '../screens/onboarding/restore_wallet_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/pay/pay_request_screen.dart';
import '../screens/pay/payment_amount_screen.dart';
import '../screens/pay/payment_details_screen.dart';
import '../screens/request/request_amount_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/wallet/wallet_screen.dart';

GoRouter createRouter(WalletProvider walletProvider) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return ListenableBuilder(
            listenable: walletProvider,
            builder: (BuildContext context, _) => child,
          );
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/welcome',
            builder: (BuildContext context, GoRouterState state) =>
                const WelcomeScreen(),
          ),
          GoRoute(
            path: '/new_wallet',
            builder: (BuildContext context, GoRouterState state) =>
                const NewWalletScreen(),
          ),
          GoRoute(
            path: '/backup_wallet',
            builder: (BuildContext context, GoRouterState state) =>
                const BackupWalletScreen(),
          ),
          GoRoute(
            path: '/restore_wallet',
            builder: (BuildContext context, GoRouterState state) =>
                const RestoreWalletScreen(),
          ),
          GoRoute(
            path: '/wallet',
            builder: (BuildContext context, GoRouterState state) =>
                const WalletScreen(),
          ),
          GoRoute(
            path: '/pay-request',
            builder: (BuildContext context, GoRouterState state) =>
                const PayRequest(),
          ),
          GoRoute(
            path: '/payment-details',
            builder: (BuildContext context, GoRouterState state) =>
                const PaymentDetails(),
          ),
          GoRoute(
            path: '/payment-amount',
            builder: (BuildContext context, GoRouterState state) =>
                const PaymentAmountScreen(),
          ),
          GoRoute(
            path: '/request-amount',
            builder: (BuildContext context, GoRouterState state) =>
                const RequestAmountScreen(),
          ),
          GoRoute(
            path: '/create_password',
            builder: (BuildContext context, GoRouterState state) =>
                const CreatePasswordScreen(),
          ),
          GoRoute(
            path: '/access_wallet',
            builder: (BuildContext context, GoRouterState state) =>
                const AccessWalletScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) {
      return Scaffold(
        body: Center(
          child: Text('Page not found: ${state.uri.toString()}'),
        ),
      );
    },
  );
}
