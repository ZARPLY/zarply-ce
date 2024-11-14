import 'package:flutter/material.dart';
import 'package:zarply/shared/auth_layout.dart';

class RestoreWalletScreen extends StatelessWidget {
  const RestoreWalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthLayout(
      title: Text("Restore Wallet"),
      body: Center(child: Text("Restore wallet screen")),
    );
  }
}
