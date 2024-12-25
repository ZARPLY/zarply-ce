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
    return ChangeNotifierProvider<AuthProvider>(
      create: (BuildContext context) => authProvider,
      child: Builder(
        builder: (BuildContext context) {
          final AuthProvider authProvider = Provider.of<AuthProvider>(context);
          final GoRouter router = createRouter(authProvider);

          return MaterialApp.router(
            title: 'ZARPLY',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFEBECEF),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
              ),
              textSelectionTheme: const TextSelectionThemeData(
                cursorColor: Colors.grey,
              ),
              inputDecorationTheme: InputDecorationTheme(
                labelStyle: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Colors.black,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFFD3D9DF),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.transparent,
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
              scaffoldBackgroundColor: Colors.white,
              textTheme: const TextTheme(
                titleLarge: TextStyle(
                  color: Colors.black,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
                headlineLarge: TextStyle(
                  color: Colors.black,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
                bodyLarge: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                bodyMedium: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                bodySmall: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                titleTextStyle: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
