import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/create_account_screen.dart';
import '../pages/login.dart';
import '../pages/pay_request.dart';
import '../pages/wallet.dart';
import '../provider/auth_provider.dart';
import '../shared/auth_layout.dart';

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/wallet',
    refreshListenable: authProvider,
    routes: <RouteBase>[
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
          GoRoute(
            path: '/pay-request',
            builder: (BuildContext context, GoRouterState state) =>
                PayRequest(),
          ),
        ],
        redirect: (BuildContext context, GoRouterState state) {
          final bool isAuthenticated = authProvider.isAuthenticated;
          return isAuthenticated ? null : '/login';
        },
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
