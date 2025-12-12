import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/solana.dart';

class PaymentDetailsViewModel extends ChangeNotifier {
  PaymentDetailsViewModel({required this.ownPublicKey}) 
      : _solanaClient = SolanaClient(
          rpcUrl: Uri.parse(dotenv.env['solana_wallet_rpc_url']!),
          websocketUrl: Uri.parse(dotenv.env['solana_wallet_websocket_url']!),
          ) {
    publicKeyController.addListener(_updateFormValidity);
    descriptionController.addListener(_updateFormValidity);
    }
  
  final String ownPublicKey;
  final SolanaClient _solanaClient;
  final TextEditingController publicKeyController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool isFormValid = false;
  String? publicKeyError;
  bool? accountExists;
  bool isCheckingAccount = false;
  bool get canContinue =>
      isFormValid && (accountExists ?? false) && !isCheckingAccount;

  @override
  void dispose() {
    publicKeyController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _updateFormValidity() {
    final String publicKey = publicKeyController.text;

    publicKeyError  = null;
    accountExists   = null;

    if (publicKey.isEmpty) {
      publicKeyError = 'Public key is required';
    } else if (publicKey == ownPublicKey) {
      publicKeyError = 'You cannot pay yourself';
    } else if (publicKey.length < 32) {
      publicKeyError = 'Invalid public key format';
    } else {
      publicKeyError = null;
      _checkAccountExists(publicKey);
    }

    isFormValid = publicKeyError == null && publicKeyController.text.isNotEmpty;
    notifyListeners();
  }

  Future<void> _checkAccountExists(String publicKey) async {
    accountExists = null;
    isCheckingAccount = true;
    notifyListeners();
    try {
      await _solanaClient.rpcClient.getAccountInfo(publicKey);
      accountExists = true;                  
    } catch (_) {
      accountExists = false;                  
    }
    isCheckingAccount = false;
    notifyListeners();
  }
}
