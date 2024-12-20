import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'provider/auth_provider.dart';
import 'router/app_router.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  usePathUrlStrategy();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final AuthProvider authProvider = AuthProvider();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => authProvider,
      child: Builder(
        builder: (BuildContext context) {
          final AuthProvider authProvider = Provider.of<AuthProvider>(context);
          final GoRouter router = createRouter(authProvider);

          return MaterialApp.router(
            title: 'ZARPLY',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
