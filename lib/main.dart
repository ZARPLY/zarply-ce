import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'provider/wallet_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  usePathUrlStrategy();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final WalletProvider walletProvider = WalletProvider();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WalletProvider>(
      create: (BuildContext context) => walletProvider,
      child: Builder(
        builder: (BuildContext context) {
          final WalletProvider walletProvider =
              Provider.of<WalletProvider>(context, listen: false);
          final GoRouter router = createRouter(walletProvider);

          return MaterialApp.router(
            title: 'ZARPLY',
            theme: AppTheme.lightTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
