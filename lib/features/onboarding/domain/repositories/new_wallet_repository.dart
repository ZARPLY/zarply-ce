import 'package:flutter/material.dart';

abstract class NewWalletRepository {
  Future<String?> getWalletPublicKey();
  Future<String?> getAssociatedTokenAccountPublicKey();
  Future<void> copyToClipboard(String text, BuildContext context);
}
