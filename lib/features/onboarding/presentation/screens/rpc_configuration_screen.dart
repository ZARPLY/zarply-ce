import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/widgets/loading_button.dart';
import '../models/welcome_view_model.dart';
import '../widgets/progress_steps.dart';

class RpcConfigurationScreen extends StatefulWidget {
  const RpcConfigurationScreen({super.key});

  @override
  State<RpcConfigurationScreen> createState() => _RpcConfigurationScreenState();
}

class _RpcConfigurationScreenState extends State<RpcConfigurationScreen> {
  final TextEditingController _rpcController = TextEditingController();
  final TextEditingController _websocketController = TextEditingController();
  final SecureStorageService _storageService = SecureStorageService();

  bool _useCustomRpc = false;
  bool _isLoading = false;
  String? _errorMessage;

  final String _defaultRpcUrl = 'https://api.devnet.solana.com';
  final String _defaultWebsocketUrl = 'wss://api.devnet.solana.com';

  @override
  void initState() {
    super.initState();
    _loadSavedConfiguration();
  }

  @override
  void dispose() {
    _rpcController.dispose();
    _websocketController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedConfiguration() async {
    try {
      final ({String? rpcUrl, String? websocketUrl}) config =
          await _storageService.getRpcConfiguration();
      if (config.rpcUrl != null && config.websocketUrl != null) {
        setState(() {
          _useCustomRpc = true;
          _rpcController.text = config.rpcUrl!;
          _websocketController.text = config.websocketUrl!;
        });
      }
    } catch (e) {
      // Ignore errors, use defaults
    }
  }

  void _setError(String message) {
    setState(() => _errorMessage = message);
  }

  bool _validateUrls() {
    if (!_useCustomRpc) return true;

    if (_rpcController.text.trim().isEmpty) {
      _setError('RPC URL is required when using custom configuration');
      return false;
    }

    if (_websocketController.text.trim().isEmpty) {
      _setError('WebSocket URL is required when using custom configuration');
      return false;
    }

    try {
      final Uri rpcUri = Uri.parse(_rpcController.text.trim());
      final Uri wsUri = Uri.parse(_websocketController.text.trim());

      if (!rpcUri.isAbsolute || (!rpcUri.scheme.startsWith('http'))) {
        _setError('RPC URL must be a valid HTTP/HTTPS URL');
        return false;
      }

      if (!wsUri.isAbsolute || (!wsUri.scheme.startsWith('ws'))) {
        _setError('WebSocket URL must be a valid WS/WSS URL');
        return false;
      }
    } catch (e) {
      _setError('Invalid URL format');
      return false;
    }

    return true;
  }

  Future<void> _saveConfigurationAndContinue() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (!_validateUrls()) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (_useCustomRpc) {
        await _storageService.saveRpcConfiguration(
          rpcUrl: _rpcController.text.trim(),
          websocketUrl: _websocketController.text.trim(),
        );
      } else {
        // Clear any existing custom configuration
        await _storageService.clearRpcConfiguration();
      }

      if (!mounted) return;

      // Now create the wallet using the configured RPC
      final WalletProvider walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );

      final WelcomeViewModel welcomeViewModel = WelcomeViewModel();
      final bool success =
          await welcomeViewModel.createAndStoreWallet(walletProvider);

      if (!mounted) return;

      if (success) {
        context.go('/backup_wallet');
      } else {
        _setError(welcomeViewModel.errorMessage ?? 'Failed to create wallet');
      }
    } catch (e) {
      _setError('Failed to save configuration: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
          child: InkWell(
            onTap: () => context.go('/welcome'),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEBECEF),
                borderRadius: BorderRadius.circular(80),
              ),
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const ProgressSteps(currentStep: 1, totalSteps: 4),
                const SizedBox(height: 32),
                Text(
                  'Network Configuration',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: !_useCustomRpc ? Colors.blue : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: !_useCustomRpc ? Colors.blue[50] : Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Radio<bool>(
                            value: false,
                            groupValue: _useCustomRpc,
                            onChanged: (bool? value) {
                              setState(() => _useCustomRpc = value!);
                            },
                            activeColor: Colors.blue,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Use Default (Recommended)',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Free public Solana RPC endpoint',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!_useCustomRpc) ...<Widget>[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'RPC: $_defaultRpcUrl',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'WS: $_defaultWebsocketUrl',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Custom RPC Option
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _useCustomRpc ? Colors.blue : Colors.grey[300]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: _useCustomRpc ? Colors.blue[50] : Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Radio<bool>(
                            value: true,
                            groupValue: _useCustomRpc,
                            onChanged: (bool? value) {
                              setState(() => _useCustomRpc = value!);
                            },
                            activeColor: Colors.blue,
                          ),
                          Expanded(
                            child: Text(
                              'Use Custom',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      if (_useCustomRpc) ...<Widget>[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _rpcController,
                          decoration: const InputDecoration(
                            labelText: 'RPC URL',
                            hintText:
                                'https://your-endpoint.solana-mainnet.quiknode.pro/xyz/',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _websocketController,
                          decoration: const InputDecoration(
                            labelText: 'WebSocket URL',
                            hintText:
                                'wss://your-endpoint.solana-mainnet.quiknode.pro/xyz/',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                // Add more content as needed
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom > 0
              ? MediaQuery.of(context).viewInsets.bottom
              : 24,
          top: 8,
        ),
        child: SizedBox(
          width: double.infinity,
          child: LoadingButton(
            isLoading: _isLoading,
            onPressed: _saveConfigurationAndContinue,
            child: const Text('Continue'),
          ),
        ),
      ),
    );
  }
}
