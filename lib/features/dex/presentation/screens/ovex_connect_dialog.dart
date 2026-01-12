import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../models/ovex_connect_view_model.dart';

class OvexConnectDialog extends StatefulWidget {
  const OvexConnectDialog({super.key});

  @override
  State<OvexConnectDialog> createState() => _OvexConnectDialogState();
}

class _OvexConnectDialogState extends State<OvexConnectDialog> {
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
      Navigator.of(context).pop();
    } else if (mounted && _viewModel.errorMessage != null) {
      // Show error message
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
          final MediaQueryData mediaQuery = MediaQuery.of(context);
          final double screenHeight = mediaQuery.size.height;
          final double statusBarHeight = mediaQuery.padding.top;
          final double availableHeight = screenHeight - statusBarHeight;
          
          return Container(
            width: double.infinity,
            height: availableHeight,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: <Widget>[
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Connect OVEX',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content - Scrollable area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Ovex Logo - Centered
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: SvgPicture.asset(
                                'images/ovex_icon.svg',
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // Heading - Left aligned and bigger
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Connect OVEX',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF181C1F),
                              ),
                              textAlign: TextAlign.left,
                            ),
                            Text(
                              'API key',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF181C1F),
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Sub-text
                        Text(
                          'Details to find the API key',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.left,
                        ),

                        const SizedBox(height: 32),

                        // Email Input
                        TextField(
                          controller: viewModel.emailController,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey[500],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blue),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            suffixIcon: viewModel.emailController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      viewModel.emailController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                          onSubmitted: (_) {
                            _apiKeyFocus.requestFocus();
                          },
                        ),

                        const SizedBox(height: 16),

                        // API Key Input
                        TextField(
                          controller: viewModel.apiKeyController,
                          focusNode: _apiKeyFocus,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: 'API Key',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                                color: Colors.grey[500],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.blue),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            suffixIcon: viewModel.apiKeyController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      viewModel.apiKeyController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                          ),
                          onSubmitted: (_) {
                            if (viewModel.isFormValid && !viewModel.isLoading) {
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
                                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    viewModel.errorMessage!,
                                    style: TextStyle(color: Colors.red[700], fontSize: 14),
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

                // Connect Button - Always at bottom
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey, width: 0.5),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: viewModel.isFormValid && !viewModel.isLoading ? _handleConnect : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: viewModel.isFormValid ? Colors.blue : Colors.grey[300],
                        foregroundColor: viewModel.isFormValid ? Colors.white : Colors.grey[600],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: viewModel.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Connect',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
