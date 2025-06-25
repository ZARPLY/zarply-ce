import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/onboarding/presentation/screens/access_wallet_screen.dart';
import '../../features/onboarding/presentation/screens/backup_wallet.dart';
import '../../features/onboarding/presentation/screens/create_password_screen.dart';
import '../../features/onboarding/presentation/screens/private_keys_screen.dart';
import '../../features/onboarding/presentation/screens/restore_wallet_screen.dart';
import '../../features/onboarding/presentation/screens/rpc_configuration_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/welcome_screen.dart';
import '../../features/pay/presentation/screens/pay_request_screen.dart';
import '../../features/pay/presentation/screens/payment_amount_screen.dart';
import '../../features/pay/presentation/screens/payment_details_screen.dart';
import '../../features/request/presentation/screens/payment_request_details_screen.dart';
import '../../features/request/presentation/screens/request_amount_screen.dart';
import '../../features/wallet/presentation/screens/transaction_details.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../provider/auth_provider.dart';
import '../provider/wallet_provider.dart';
import '../widgets/scanner/qr_scanner.dart';

GoRouter createRouter(
  WalletProvider walletProvider,
  AuthProvider authProvider,
) {
  return GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      final AuthProvider authProvider = Provider.of<AuthProvider>(
        context,
        listen: false,
      );
      final String location = state.uri.toString();
      final bool isAuthenticated = authProvider.isAuthenticated;

      final List<String> protectedRoutes = <String>[
        '/wallet',
        '/pay_request',
        '/payment_amount',
        '/payment_details',
        '/transaction_details',
        '/request_amount',
        '/scan',
      ];

      final List<String> onboardingRoutes = <String>[
        '/welcome',
        '/rpc_configuration',
        '/create_password',
        '/access_wallet',
        '/new_wallet',
        '/backup_wallet',
        '/private_keys',
        '/restore_wallet',
      ];

      final bool isLoginRoute = location == '/login';
      final bool isRootRoute = location == '/';
      final bool isAccessWalletRoute = location == '/access_wallet';
      final bool isProtected = protectedRoutes.contains(location);
      final bool isFromOnboarding =
          onboardingRoutes.contains(state.extra?.toString());

      // If authenticated and trying to access root or login, go to wallet
      if (isAuthenticated &&
          (isLoginRoute || isRootRoute || isAccessWalletRoute)) {
        return '/wallet';
      }

      // If not authenticated and trying to access protected routes
      if (!isAuthenticated && isProtected && !isFromOnboarding) {
        return '/login';
      }

      return null;
    },
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
            path: '/rpc_configuration',
            builder: (BuildContext context, GoRouterState state) =>
                const RpcConfigurationScreen(),
          ),
          GoRoute(
            path: '/backup_wallet',
            builder: (BuildContext context, GoRouterState state) =>
                const BackupWalletScreen(),
          ),
          GoRoute(
            path: '/private_keys',
            builder: (BuildContext context, GoRouterState state) =>
                const PrivateKeysScreen(),
          ),
          GoRoute(
            path: '/restore_wallet',
            builder: (BuildContext context, GoRouterState state) =>
                const RestoreWalletScreen(),
          ),
          GoRoute(
            path: '/create_password',
            builder: (BuildContext context, GoRouterState state) =>
                const CreatePasswordScreen(),
          ),
          GoRoute(
            path: '/login',
            builder: (BuildContext context, GoRouterState state) =>
                const LoginScreen(),
          ),
          GoRoute(
            path: '/access_wallet',
            builder: (BuildContext context, GoRouterState state) =>
                const AccessWalletScreen(),
          ),
          GoRoute(
            path: '/wallet',
            builder: (BuildContext context, GoRouterState state) =>
                const WalletScreen(),
          ),
          GoRoute(
            path: '/transaction_details',
            builder: (BuildContext context, GoRouterState state) {
              final Map<String, String?> extra =
                  state.extra as Map<String, String?>;
              final String sender = extra['sender'] ?? '';
              final String receiver = extra['receiver'] ?? '';
              final String timestamp = extra['timestamp'] ?? '';
              final String amount = extra['amount'] ?? '';
              return TransactionDetailsScreen(
                sender: sender,
                receiver: receiver,
                timestamp: DateTime.parse(timestamp),
                amount: double.parse(amount),
              );
            },
          ),
          GoRoute(
            path: '/pay_request',
            builder: (BuildContext context, GoRouterState state) =>
                const PayRequest(),
          ),
          GoRoute(
            path: '/payment_details',
            builder: (BuildContext context, GoRouterState state) =>
                const PaymentDetails(),
          ),
          GoRoute(
            path: '/payment_amount',
            builder: (BuildContext context, GoRouterState state) {
              final Map<String, String> extra =
                  state.extra as Map<String, String>;
              final String publicKey = extra['recipientAddress'] ?? '';
              final String? amount = extra['amount'];
              final String source = extra['source'] ?? '/pay_request';
              return PaymentAmountScreen(
                recipientAddress: publicKey,
                initialAmount: amount,
                source: source,
              );
            },
          ),
          GoRoute(
            path: '/request_amount',
            builder: (BuildContext context, GoRouterState state) =>
                const RequestAmountScreen(),
          ),
          GoRoute(
            path: '/scan',
            builder: (BuildContext context, GoRouterState state) =>
                const QRScanner(),
          ),
          GoRoute(
            path: '/payment_request_details',
            builder: (BuildContext context, GoRouterState state) {
              final Map<String, dynamic> extra =
                  state.extra as Map<String, dynamic>;
              return PaymentRequestDetailsScreen(
                amount: extra['amount'] as String,
                recipientAddress: extra['recipientAddress'] as String,
              );
            },
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
