import 'package:flutter/material.dart';
import 'package:zarply/shared/auth_layout.dart';

class BeneficiariesScreen extends StatelessWidget {
  const BeneficiariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthLayout(
      title: Text("Beneficiaries"),
      body: Text("BeneficiariesScreen"),
    );
  }
}
