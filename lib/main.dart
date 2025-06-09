import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/provider/wallet_provider.dart';
import 'core/provider/auth_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> checkFirstInstall() async {
  const FlutterSecureStorage secureStorage = FlutterSecureStorage();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool hasLaunched = prefs.getBool('hasLaunched') ?? false;

  if (!hasLaunched) {
    await secureStorage.deleteAll();
    await prefs.setBool('hasLaunched', true);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  await dotenv.load(fileName: '.env');
  usePathUrlStrategy();
  await checkFirstInstall();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final WalletProvider walletProvider = WalletProvider();
  final AuthProvider authProvider = AuthProvider();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <ChangeNotifierProvider<dynamic>>[
        ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: Builder(
        builder: (BuildContext context) {
          final GoRouter router = createRouter(
            walletProvider,
            Provider.of<AuthProvider>(context),
          );
          
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
