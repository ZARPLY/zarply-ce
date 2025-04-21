import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/provider/wallet_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  usePathUrlStrategy();

  final WalletProvider walletProvider = WalletProvider();
  await walletProvider.initialize();
  runApp(
    ChangeNotifierProvider<WalletProvider>.value(
      value: walletProvider, 
      child: const MyApp(),
      ),
      );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final wp = Provider.of<WalletProvider>(context, listen: false);
    final GoRouter router = createRouter(wp);

          return MaterialApp.router(
            title: 'ZARPLY',
            theme: AppTheme.lightTheme,
            routerConfig: router,
          );
  }
}
