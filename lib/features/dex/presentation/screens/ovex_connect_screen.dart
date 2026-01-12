import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/clear_icon_button.dart';
import '../../../../core/widgets/loading_button.dart';
import '../models/ovex_connect_view_model.dart';

class OvexConnectScreen extends StatefulWidget {
  const OvexConnectScreen({super.key});

  @override
  State<OvexConnectScreen> createState() => _OvexConnectScreenState();
}

class _OvexConnectScreenState extends State<OvexConnectScreen> {
  late OvexConnectViewModel _viewModel;
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _apiKeyFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel = OvexConnectViewModel();
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _apiKeyFocus.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleConnect() async {
    final bool success = await _viewModel.connectToOvex();
    
    if (success && mounted) {
      // Navigate back to DEX screen - the card will show "Connected" status
      context.go('/dex');
    } else if (mounted && _viewModel.errorMessage != null) {
      // Only show error messages as popups
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OvexConnectViewModel>.value(
      value: _viewModel,
      child: Consumer<OvexConnectViewModel>(
        builder: (BuildContext context, OvexConnectViewModel viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Connect to Ovex'),
              leading: BackButton(
                onPressed: () => context.go('/dex'),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 20),
                  const Text(
                    'Connect Your Ovex Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your Ovex account email and API key to enable on-ramp and off-ramp functionality.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Email Input
                  TextField(
                    controller: viewModel.emailController,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Ovex Account Email',
                      hintText: 'your.email@example.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email_outlined),
                      suffixIcon: ClearIconButton(
                        controller: viewModel.emailController,
                      ),
                    ),
                    onSubmitted: (_) {
                      _apiKeyFocus.requestFocus();
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // API Key Input
                  TextField(
                    controller: viewModel.apiKeyController,
                    focusNode: _apiKeyFocus,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'Enter your Ovex API key',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                      suffixIcon: ClearIconButton(
                        controller: viewModel.apiKeyController,
                      ),
                      helperText: 'Your API key is stored securely',
                    ),
                    onSubmitted: (_) {
                      if (!viewModel.isLoading) {
                        _handleConnect();
                      }
                    },
                  ),
                  
                  if (viewModel.errorMessage != null) ...<Widget>[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.error_outline, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              viewModel.errorMessage!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Connect Button
                  LoadingButton(
                    onPressed: _handleConnect,
                    isLoading: viewModel.isLoading,
                    child: const Text('Connect to Ovex'),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Info text
                  Text(
                    'Don\'t have an API key? Create one in your Ovex account settings.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
