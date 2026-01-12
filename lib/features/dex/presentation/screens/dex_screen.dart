import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/dex_view_model.dart';
import 'ovex_connect_dialog.dart';

class DexScreen extends StatefulWidget {
  const DexScreen({super.key});

  @override
  State<DexScreen> createState() => _DexScreenState();
}

class _DexScreenState extends State<DexScreen> {
  late final DexViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DexViewModel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh connection status when screen becomes visible
    _viewModel.refreshConnectionStatus();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _showInfoTooltip(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('DEX feature information'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showOvexConnectDialog(BuildContext context, DexViewModel dexViewModel) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(top: statusBarHeight),
          child: const OvexConnectDialog(),
        );
      },
    ).then((_) {
      // Refresh connection status when dialog closes
      dexViewModel.refreshConnectionStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DexViewModel>.value(
      value: _viewModel,
      child: Consumer<DexViewModel>(
        builder: (BuildContext context, DexViewModel viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('DEX', style: TextStyle(fontWeight: FontWeight.w500)),
              centerTitle: true,
              leading: Padding(
                padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
                child: InkWell(
                  onTap: () => context.go('/more'),
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
                      ),
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                // Debug: Disconnect Ovex button
                if (viewModel.isOvexConnected)
                  TextButton(
                    onPressed: () async {
                      await viewModel.disconnectOvex();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ovex account disconnected (debug)'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Disconnect',
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                Tooltip(
                  message: 'DEX information and help',
                  child: IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showInfoTooltip(context),
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: <Widget>[
                  const Text(
                    'Connect a Decentralized Exchange (DEX)',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Link a Dex to enable on-chain swaps and asset management directly from your ZARPLY wallet.',
                    style: TextStyle(
                      color: Color(0xFF636E81),
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: viewModel.isOvexConnected ? null : () => _showOvexConnectDialog(context, viewModel),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          // Ovex Icon
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SvgPicture.asset(
                                'images/ovex_icon.svg',
                                width: 50,
                                height: 50,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'OVEX',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  viewModel.isOvexConnected ? 'Connected' : 'Not connected',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF636E81),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (viewModel.isOvexConnected)
                            // Request button when connected
                            TextButton(
                              onPressed: () {
                                // TODO: Navigate to request screen






                                
                                // For now, just show a placeholder
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Request feature coming soon'),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'Request',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          else
                            // Arrow when not connected - make card clickable
                            InkWell(
                              onTap: () => _showOvexConnectDialog(context, viewModel),
                              child: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey,
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
        },
      ),
    );
  }
}
