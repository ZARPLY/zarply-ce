import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../models/welcome_view_model.dart';
import '../widgets/progress_steps.dart';

class RpcConfigurationScreen extends StatefulWidget {
  const RpcConfigurationScreen({super.key, this.isRestoreFlow = false});

  final bool isRestoreFlow;

  @override
  State<RpcConfigurationScreen> createState() => _RpcConfigurationScreenState();
}

class _RpcConfigurationScreenState extends State<RpcConfigurationScreen> {
  final SecureStorageService _storageService = SecureStorageService();

  bool _useDefaultRpc = false; // No default selection
  bool _useCustomRpc = false;
  bool _isCreatingWallet = false;
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
    super.dispose();
  }

  Future<void> _loadSavedConfiguration() async {
    try {
      final ({String? rpcUrl, String? websocketUrl}) config =
          await _storageService.getRpcConfiguration();
      if (config.rpcUrl != null && config.websocketUrl != null) {
        setState(() {
          _useCustomRpc = true;
          _useDefaultRpc = false;
        });
      }
      // If no saved config, keep no selection
    } catch (e) {
      // Keep no selection on error
    }
  }

  void _setError(String message) {
    setState(() => _errorMessage = message);
  }

  Future<void> _onDefaultRpcChanged() async {
    if (_useDefaultRpc || _isCreatingWallet) {
      return; // Already selected or creating wallet
    }

    setState(() {
      _useDefaultRpc = true;
      _useCustomRpc = false;
      _isCreatingWallet = true;
      _errorMessage = null;
    });

    try {
      // Clear any existing custom configuration
      await _storageService.clearRpcConfiguration();

      if (!mounted) return;

      if (widget.isRestoreFlow) {
        // For restore flow, proceed to restore wallet screen
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
        setState(() {
          _isCreatingWallet = false;
        });
      }
    }
  }

  void _onCustomRpcChanged() {
    if (_useCustomRpc || _isCreatingWallet) {
      return; // Already selected or creating wallet
    }

    setState(() {
      _useCustomRpc = true;
      _useDefaultRpc = false;
      _errorMessage = null;
    });

    // Navigate to the custom RPC configuration screen
    final String route = widget.isRestoreFlow
        ? '/custom_rpc_configuration?restore=true'
        : '/custom_rpc_configuration';
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isCreatingWallet,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
            child: InkWell(
              onTap: _isCreatingWallet ? null : () => context.go('/welcome'),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _isCreatingWallet
                      ? Colors.grey[300]
                      : const Color(0xFFEBECEF),
                  borderRadius: BorderRadius.circular(80),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.arrow_back_ios,
                    size: 18,
                    color: _isCreatingWallet ? Colors.grey[500] : Colors.black,
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
        body: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.isRestoreFlow
                          ? 'Configure Network'
                          : 'Network Configuration',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Choose your preferred network configuration.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Default RPC Option
                    Opacity(
                      opacity: _isCreatingWallet ? 0.6 : 1.0,
                      child: GestureDetector(
                        onTap: _isCreatingWallet ? null : _onDefaultRpcChanged,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _useDefaultRpc
                                  ? Colors.blue
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color:
                                _useDefaultRpc ? Colors.blue[50] : Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                              if (_useDefaultRpc) ...<Widget>[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Custom RPC Option
                    Opacity(
                      opacity: _isCreatingWallet ? 0.6 : 1.0,
                      child: GestureDetector(
                        onTap: _isCreatingWallet ? null : _onCustomRpcChanged,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _useCustomRpc
                                  ? Colors.blue
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color:
                                _useCustomRpc ? Colors.blue[50] : Colors.white,
                          ),
                          child: Row(
                            children: <Widget>[
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
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Error message
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
                  ],
                ),
              ),
            ),

            // Loading overlay
            if (_isCreatingWallet && !widget.isRestoreFlow)
              const ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Creating your wallet...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
