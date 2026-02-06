import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/onboarding/presentation/screens/access_wallet_screen.dart';
import '../../features/onboarding/presentation/screens/backup_wallet.dart';
import '../../features/onboarding/presentation/screens/create_password_screen.dart';
import '../../features/onboarding/presentation/screens/custom_rpc_configuration_screen.dart';
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
import '../../features/wallet/presentation/screens/more_options_screen.dart';
import '../../features/wallet/presentation/screens/recovery_phrase_screen.dart';
import '../../features/wallet/presentation/screens/transaction_details.dart';
import '../../features/wallet/presentation/screens/unlock_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../provider/auth_provider.dart';
import '../provider/wallet_provider.dart';
import '../services/secure_storage_service.dart';
import '../widgets/initializer/app_initializer.dart';
import '../widgets/scanner/qr_scanner.dart';

const List<String> _protectedRoutes = <String>[
  '/wallet',
  '/pay_request',
  '/payment_amount',
  '/payment_details',
  '/transaction_details',
  '/request_amount',
  '/scan',
  '/more',
  '/recovery_phrase',
  '/unlock',
];

String _getInitialLocation(
  AuthProvider authProvider,
  WalletProvider walletProvider,
) {
  // If user is authenticated and has wallet, go to wallet
  // Note: Password check happens in ShellRoute redirect to catch edge cases
  if (authProvider.isAuthenticated && walletProvider.hasWallet) {
    return '/wallet';
  }

  // If user has wallet but not authenticated, they need to complete setup or login
  // We'll let the splash screen determine the exact step since it's async
  if (walletProvider.hasWallet && !authProvider.isAuthenticated) {
    return '/splash';
  }

  // First time app launch - show splash screen
  return '/splash';
}

GoRouter createRouter(
  WalletProvider walletProvider,
  AuthProvider authProvider,
) {
  return GoRouter(
    initialLocation: _getInitialLocation(authProvider, walletProvider),
    refreshListenable: Listenable.merge(<Listenable>[walletProvider, authProvider]),
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
      ),
      ShellRoute(
        redirect: (BuildContext context, GoRouterState state) async {
          final String location = state.uri.toString();
          final bool isAuthenticated = authProvider.isAuthenticated;

          // NEVER redirect /login - this is the logout screen
          if (location == '/login') {
            return null;
          }

          // CRITICAL: Check if password exists before allowing access to protected wallet routes.
          // This prevents users from accessing wallet without completing password setup.
          if (walletProvider.hasWallet && _protectedRoutes.contains(location)) {
            try {
              final String pin = await SecureStorageService().getPin();
              if (pin.isEmpty) {
                // Wallet exists but no password - must create password first
                return '/create_password';
              }
            } catch (_) {
              // Any error reading the password should be treated as "no password set"
              return '/create_password';
            }
          }

          // SIMPLE LOGIC: Only redirect to login if trying to access protected routes while not authenticated
          if (!isAuthenticated && _protectedRoutes.contains(location)) {
            return '/login';
          }

          // For all other cases, stay where you are
          return null;
        },
        builder: (BuildContext context, GoRouterState state, Widget child) {
          final String loc = state.uri.toString();

          const Set<String> unauthorisedRoutes = <String>{
            '/login',
            '/welcome',
            '/create_password',
            '/access_wallet',
            '/restore_wallet',
            '/rpc_configuration',
            '/custom_rpc_configuration',
            '/backup_wallet',
            '/private_keys',
            '/new_wallet',
          };

          if (unauthorisedRoutes.contains(loc)) {
            return child;
          }

          return AppInitializer(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/welcome',
            builder: (BuildContext context, GoRouterState state) => const WelcomeScreen(),
          ),
          GoRoute(
            path: '/more',
            name: 'more',
            builder: (BuildContext context, GoRouterState state) => const MoreOptionsScreen(),
          ),
          GoRoute(
            path: '/unlock',
            builder: (BuildContext context, GoRouterState state) {
              final Map<String, dynamic> extraMap = (state.extra as Map<String, dynamic>?) ?? <String, dynamic>{};
              return UnlockScreen(
                nextRoute: extraMap['nextRoute'] as String? ?? '/wallet',
                title: extraMap['title'] as String? ?? 'Unlock',
                extra: extraMap,
              );
            },
          ),
          GoRoute(
            path: '/recovery_phrase',
            builder: (BuildContext context, GoRouterState state) => const RecoveryPhraseScreen(),
          ),
          GoRoute(
            path: '/rpc_configuration',
            builder: (BuildContext context, GoRouterState state) {
              final bool isRestoreFlow = state.uri.queryParameters['restore'] == 'true';
              return RpcConfigurationScreen(isRestoreFlow: isRestoreFlow);
            },
          ),
          GoRoute(
            path: '/custom_rpc_configuration',
            builder: (BuildContext context, GoRouterState state) {
              final bool isRestoreFlow = state.uri.queryParameters['restore'] == 'true';
              return CustomRpcConfigurationScreen(isRestoreFlow: isRestoreFlow);
            },
          ),
          GoRoute(
            path: '/backup_wallet',
            builder: (BuildContext context, GoRouterState state) => const BackupWalletScreen(),
          ),
          GoRoute(
            path: '/private_keys',
            builder: (BuildContext context, GoRouterState state) {
              final Map<String, dynamic> extra = (state.extra as Map<String, dynamic>?) ?? <String, dynamic>{};
              final bool hideProgress = extra['hideProgress'] as bool? ?? false;
              return PrivateKeysScreen(
                hideProgress: hideProgress,
              );
            },
          ),
          GoRoute(
            path: '/restore_wallet',
            builder: (BuildContext context, GoRouterState state) => const RestoreWalletScreen(),
          ),
          GoRoute(
            path: '/create_password',
            builder: (BuildContext context, GoRouterState state) {
              return CreatePasswordScreen(extra: state.extra);
            },
          ),
          GoRoute(
            path: '/login',
            builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
          ),
          GoRoute(
            path: '/access_wallet',
            builder: (BuildContext context, GoRouterState state) => const AccessWalletScreen(),
          ),
          GoRoute(
            path: '/new_wallet',
            builder: (BuildContext context, GoRouterState state) => const WelcomeScreen(),
          ),
          GoRoute(
            path: '/wallet',
            builder: (BuildContext context, GoRouterState state) => const WalletScreen(),
          ),
          GoRoute(
            path: '/transaction_details',
            builder: (BuildContext context, GoRouterState state) {
              final Map<String, String?> extra = state.extra as Map<String, String?>;
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
            builder: (BuildContext context, GoRouterState state) => const PayRequest(),
          ),
          GoRoute(
            path: '/payment_details',
            builder: (BuildContext context, GoRouterState state) => const PaymentDetails(),
          ),
          GoRoute(
            path: '/payment_amount',
            builder: (BuildContext context, GoRouterState state) {
              final Map<String, String> extra = state.extra as Map<String, String>;
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
            builder: (BuildContext context, GoRouterState state) => const RequestAmountScreen(),
          ),
          GoRoute(
            path: '/scan',
            builder: (BuildContext context, GoRouterState state) => const QRScanner(),
          ),
          GoRoute(
            path: '/payment_request_details',
            builder: (BuildContext context, GoRouterState state) {
              final Map<String, dynamic> extra = state.extra as Map<String, dynamic>;
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
