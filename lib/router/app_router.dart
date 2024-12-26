import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../pages/auth/create_account_screen.dart';
import '../pages/auth/login.dart';
import '../pages/pay/pay_request.dart';
import '../pages/pay/payment_amount.dart';
import '../pages/pay/payment_details.dart';
import '../pages/splash_screen.dart';
import '../pages/wallet.dart';
import '../provider/auth_provider.dart';
import '../shared/auth_layout.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: authProvider,
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: '/createAccount',
        builder: (BuildContext context, GoRouterState state) =>
            const CreateAccountScreen(),
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return AuthLayout(body: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/wallet',
            builder: (BuildContext context, GoRouterState state) =>
                const WalletScreen(),
          ),
        ],
        redirect: (BuildContext context, GoRouterState state) {
          final bool isAuthenticated = authProvider.isAuthenticated;
          return isAuthenticated ? null : '/login';
        },
      ),
      GoRoute(
        path: '/pay-request',
        builder: (BuildContext context, GoRouterState state) => PayRequest(),
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
