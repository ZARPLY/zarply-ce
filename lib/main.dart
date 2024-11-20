import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zarply/pages/login.dart';
import 'package:zarply/provider/auth_provider.dart';
import 'package:zarply/shared/auth_layout.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login & Registration Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Consumer<AuthProvider>(builder: (context, authProvider, child) {
        return authProvider.isAuthenticated
            ? const AuthLayout()
            : const LoginScreen();
      }),
    );
  }
}
