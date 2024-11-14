import 'package:flutter/material.dart';
import 'package:zarply/shared/auth_layout.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthLayout(
      title: Text("About"),
      body: Text('AboutScreen'),
    );
  }
}
