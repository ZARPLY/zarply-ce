import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/onboarding/getting_started_screen.dart';
import '../pages/onboarding/new_wallet_screen.dart';
import '../pages/onboarding/restore_wallet_screen.dart';
import '../pages/onboarding/welcome_screen.dart';
import '../pages/pay/pay_request.dart';
import '../pages/pay/payment_amount.dart';
import '../pages/pay/payment_details.dart';
import '../pages/request/request_amount_screen.dart';
import '../pages/splash_screen.dart';
import '../pages/wallet/wallet.dart';
import '../provider/wallet_provider.dart';

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
            path: '/getting_started',
            builder: (BuildContext context, GoRouterState state) =>
                const GettingStartedScreen(),
          ),
          GoRoute(
            path: '/new_wallet',
            builder: (BuildContext context, GoRouterState state) =>
                const NewWalletScreen(),
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
