import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/models/wallet_balances.dart';
import '../../../../core/provider/auth_provider.dart';
import '../../../../core/provider/wallet_provider.dart';
import '../../data/services/wallet_storage_service.dart';
import '../models/wallet_view_model.dart';
import '../widgets/balance_amount.dart';
import '../widgets/quick_actions.dart';
import '../widgets/transactions_list.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with WidgetsBindingObserver {
  late WalletViewModel _viewModel;
  final WalletStorageService _walletStorageService = WalletStorageService();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  DateTime? _lastDialogShownTime;
  bool _hasShownFundingDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _viewModel = Provider.of<WalletViewModel>(context, listen: false);
    _viewModel.wallet = Provider.of<WalletProvider>(context, listen: false).wallet;
    _viewModel.tokenAccount = Provider.of<WalletProvider>(context, listen: false).userTokenAccount;

    _initializeData();
  }

  bool get _isMainnet {
    final String? rpcUrl = dotenv.env['solana_wallet_rpc_url'];
    if (rpcUrl == null) {
      return false;
    }
    return rpcUrl.contains('mainnet');
  }

  Future<void> _initializeData() async {
    try {
      if (_viewModel.wallet == null || _viewModel.tokenAccount == null) {
        final WalletProvider walletProvider = Provider.of<WalletProvider>(context, listen: false);
        _viewModel.wallet = walletProvider.wallet;
        _viewModel.tokenAccount = walletProvider.userTokenAccount;

        if (_viewModel.wallet == null || _viewModel.tokenAccount == null) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          _viewModel.wallet = walletProvider.wallet;
          _viewModel.tokenAccount = walletProvider.userTokenAccount;
        }
      }

      await _viewModel.loadCachedBalances();
      await _checkAndShowFundingDialog();

      await Future.wait(<Future<void>>[
        _loadTransactionsFromRepository(),
        _refreshBalances(),
      ]);

      await _checkAndShowFundingDialog();
      await _viewModel.checkLegacyMigrationIfNeeded();
    } catch (e) {
      _logError('ERROR in _initializeData', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to load wallet data. Please check your internet connection and try again.',
            ),
          ),
        );
      }
    }
  }

  void _logError(String context, dynamic error) {
    debugPrint('=== $context ===');
    debugPrint('Error: $error');
    if (error.toString().contains('403')) {
      debugPrint(' 403 FORBIDDEN DETECTED - Check RPC endpoint or rate limits');
    }
    debugPrint('==================');
  }

  Future<void> _loadTransactionsFromRepository() async {
    try {
      await _viewModel.loadTransactions();
    } catch (e) {
      _logError('ERROR in _loadTransactionsFromRepository', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to load transactions. Please check your internet connection and try again.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshBalances() async {
    try {
      await _viewModel.refreshBalances();
    } catch (e) {
      _logError('ERROR in _refreshBalances', e);
      rethrow;
    }
  }

  Future<void> _checkAndShowFundingDialog() async {
    if (!_isMainnet) return;
    if (_hasShownFundingDialog) return;
    if (_viewModel.solBalance >= WalletBalances.minSolForFees) return;
    
    final DateTime now = DateTime.now();
    if (_lastDialogShownTime != null && 
        now.difference(_lastDialogShownTime!).inSeconds < 30) {
      return;
    }

    if (!mounted) return;

    _hasShownFundingDialog = true;
    _lastDialogShownTime = now;
    
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Fund your account',
          style: TextStyle(color: Colors.black),
        ),
        content: const Text(
          'Your SOL account requires at least 0.003 SOL for rent exemption and transaction fees. '
          'Please transfer SOL to your wallet address to continue.',
          style: TextStyle(color: Colors.black),
        ),
        actions: <Widget>[
          TextButton(
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all<Color>(Colors.blue),
              overlayColor: WidgetStateProperty.all<Color?>(
                Colors.grey.withValues(alpha: 0.1),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _walletStorageService.clearFirstTimeUserFlag();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showWalletInfoDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Center(
            child: Text(
              'Solana details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildInfoRow('Network:', _isMainnet ? 'Mainnet' : 'Devnet'),
                const SizedBox(height: 16),
                _buildCopyableRow(
                  label: 'Address:',
                  value: _viewModel.wallet?.address ?? 'N/A',
                  onCopy: () {
                    if (_viewModel.wallet?.address != null) {
                      Clipboard.setData(ClipboardData(text: _viewModel.wallet!.address));
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Balance:', '${_viewModel.solBalance} SOL'),
                const SizedBox(height: 16),
                _buildCopyableRow(
                  label: 'Token Account:',
                  value: _viewModel.tokenAccount?.pubkey ?? 'N/A',
                  onCopy: () {
                    if (_viewModel.tokenAccount?.pubkey != null) {
                      Clipboard.setData(ClipboardData(text: _viewModel.tokenAccount!.pubkey));
                    }
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableRow({
    required String label,
    required String value,
    required VoidCallback onCopy,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onCopy,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.copy,
                  color: Colors.grey[600],
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_viewModel.isRefreshing) return;
      _viewModel.refreshTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WalletViewModel>.value(
      value: _viewModel,
      child: Consumer<WalletViewModel>(
        builder: (BuildContext context, WalletViewModel viewModel, _) {
          return Scaffold(
            body: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: viewModel.isExpanded ? 0 : MediaQuery.of(context).size.height * 0.35,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: viewModel.isExpanded ? 0.0 : 1.0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const SizedBox(height: 16),
                              BalanceAmount(
                                walletAmount: viewModel.walletAmount,
                                walletAddress: viewModel.wallet?.address ?? '',
                              ),
                              const SizedBox(height: 16),
                              const QuickActions(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                SizedBox(
                                  width: 90,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[
                                      GestureDetector(
                                        onTap: () => viewModel.toggleExpanded(),
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEBECEF),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            viewModel.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      AbsorbPointer(
                                        absorbing: viewModel.isRefreshing,
                                        child: GestureDetector(
                                          onTap: () {
                                            if (viewModel.isRefreshing) return;
                                            _refreshIndicatorKey.currentState?.show();
                                          },
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFEBECEF),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.refresh,
                                              color: viewModel.isRefreshing ? Colors.grey : Colors.blue,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'History',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  progressIndicatorTheme: const ProgressIndicatorThemeData(
                                    color: Colors.blue,
                                    circularTrackColor: Colors.white,
                                  ),
                                ),
                                child: RefreshIndicator(
                                  key: _refreshIndicatorKey,
                                  color: Colors.blue,
                                  backgroundColor: Colors.white,
                                  onRefresh: () async {
                                    try {
                                      await viewModel.refreshTransactions();
                                    } catch (e) {
                                      _logError('ERROR in refreshTransactions', e);
                                    }
                                  },
                                  child: TransactionsList(viewModel: viewModel),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: Colors.blue[700],
            appBar: AppBar(
              title: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: <Widget>[
                        const SizedBox(
                          width: 30,
                          height: 30,
                          child: Image(image: AssetImage('images/zarp.png')),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ZARP',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showWalletInfoDialog,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white30,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'i',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: Image(image: AssetImage('images/saflag.png')),
                ),
                GestureDetector(
                  onTap: () async {
                    final AuthProvider authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final GoRouter router = GoRouter.of(context);

                    final String? value = await showMenu(
                      context: context,
                      position: RelativeRect.fromLTRB(
                        MediaQuery.of(context).size.width - 100,
                        kToolbarHeight + MediaQuery.of(context).padding.top,
                        MediaQuery.of(context).size.width - 20,
                        0,
                      ),
                      items: <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.logout),
                              SizedBox(width: 8),
                              Text('Logout'),
                            ],
                          ),
                        ),
                      ],
                    );

                    if (value != 'logout' || !mounted) return;

                    await authProvider.logout();

                    if (!mounted) return;
                    await router.replace('/login');
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white30,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'JT',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
              ],
              backgroundColor: Colors.blue[700],
            ),
            floatingActionButton: SizedBox(
              width: 60,
              height: 60,
              child: FloatingActionButton(
                onPressed: () {
                  context.push('/pay_request').then((_) {
                    if (mounted && !_viewModel.isRefreshing) {
                      _viewModel.refreshTransactions();
                    }
                  });
                },
                shape: const CircleBorder(),
                backgroundColor: Colors.blue,
                child: const Padding(
                  padding: EdgeInsets.only(right: 2, top: 8),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Image(
                      image: AssetImage('images/logo.png'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          );
        },
      ),
    );
  }
}
