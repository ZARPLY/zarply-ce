import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zarply/provider/auth_provider.dart';
import 'package:zarply/router/app_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  usePathUrlStrategy();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider = AuthProvider();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => authProvider,
      child: Builder(
        builder: (context) {
          final authProvider = Provider.of<AuthProvider>(context);
          final router = createRouter(authProvider);

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
