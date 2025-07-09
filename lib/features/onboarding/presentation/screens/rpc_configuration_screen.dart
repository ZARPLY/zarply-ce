import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/widgets/loading_button.dart';
import '../models/welcome_view_model.dart';
import '../widgets/progress_steps.dart';

class RpcConfigurationScreen extends StatefulWidget {
  const RpcConfigurationScreen({super.key, this.isRestoreFlow = false});

  final bool isRestoreFlow;

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

      if (widget.isRestoreFlow) {
        // For restore flow, proceed to wallet screen
        context.go('/restore_wallet');
      } else {
        // For new wallet flow, create the wallet using the configured RPC
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
      resizeToAvoidBottomInset: true,
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
        title: Padding(
          padding: const EdgeInsets.only(right: 24),
          child: widget.isRestoreFlow
              ? null
              : const ProgressSteps(
                  currentStep: 1,
                  totalSteps: 4,
                ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.isRestoreFlow
                    ? 'Configure Network'
                    : 'Network Configuration',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
              ),
              const SizedBox(height: 16),
              if (widget.isRestoreFlow)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Configure your network settings for your restored wallet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Use QuickNode (Custom)',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Use your own QuickNode endpoint',
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
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
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
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.url,
                        style: const TextStyle(
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Info card
              if (_useCustomRpc) ...<Widget>[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'How to get QuickNode endpoints:',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Sign up at quicknode.com\n'
                        '2. Create a Solana endpoint\n'
                        '3. Copy the HTTP and WebSocket URLs\n'
                        '4. Paste them in the fields above',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Add the error message here if it exists
              if (_errorMessage != null) ...<Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(top: 16, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Add spacing to push button to bottom
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),

              SizedBox(
                width: double.infinity,
                child: LoadingButton(
                  isLoading: _isLoading,
                  onPressed: _saveConfigurationAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4169E1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    widget.isRestoreFlow
                        ? 'Continue'
                        : 'Continue & Create Wallet',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
