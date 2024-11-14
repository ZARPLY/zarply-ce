import 'package:flutter/material.dart';
import 'package:zarply/shared/auth_layout.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthLayout(
      title: Text("Settings"),
      body: Text('SettingsScreen'),
    );
  }
}
