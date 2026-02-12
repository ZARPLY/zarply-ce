import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
  DateTime? _lastDialogShownTime;
  static bool _didInitialSystemRefresh = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _viewModel = WalletViewModel();

    final WalletProvider walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _viewModel.wallet = walletProvider.wallet;
    _viewModel.tokenAccount = walletProvider.userTokenAccount;

    // Load fresh data on initialization
    _initializeData();

    // Fire a one-time, background "system refresh" after the first frame.
    // This uses the normal refresh path but does NOT show the pull-to-refresh
    // indicator, so it is invisible to the user.
    if (!_didInitialSystemRefresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _didInitialSystemRefresh = true;
        _viewModel.refreshTransactions();
      });
    }
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
      // Ensure wallet and token account are set
      if (_viewModel.wallet == null || _viewModel.tokenAccount == null) {
        final WalletProvider walletProvider = Provider.of<WalletProvider>(context, listen: false);
        _viewModel.wallet = walletProvider.wallet;
        _viewModel.tokenAccount = walletProvider.userTokenAccount;

        // If still null, wait a bit for initialization to complete
        if (_viewModel.wallet == null || _viewModel.tokenAccount == null) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          _viewModel.wallet = walletProvider.wallet;
          _viewModel.tokenAccount = walletProvider.userTokenAccount;
        }
      }

      // Load cached data first for immediate display
      await _viewModel.loadCachedBalances();

      // Check if wallet needs funding on mainnet (before refreshing, using cached balance)
      await _checkAndShowFundingDialog();

      // Then load fresh data in background
      await Future.wait(<Future<void>>[
        _loadTransactionsFromRepository(),
        _refreshBalances(),
      ]);

      // Check again after refreshing balances to catch any changes
      await _checkAndShowFundingDialog();

      // Check for legacy account and drain if needed
      await _viewModel.checkLegacyMigrationIfNeeded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading wallet data: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _viewModel.isLoadingTransactions = false;
        });
      }
    }
  }

  Future<void> _loadTransactionsFromRepository() async {
    try {
      // Load transactions from network and store them locally
      await _viewModel.loadTransactions();

      // Update transaction count and oldest signature
      await _viewModel.updateTransactionCount();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transactions: $e'),
          ),
        );
      }
    }
  }

  Future<void> _refreshBalances() async {
    await _viewModel.loadCachedBalances();
  }

  Future<void> _checkAndShowFundingDialog() async {
    // Check if wallet needs funding on mainnet
    if (_isMainnet && _viewModel.wallet != null && mounted) {
      // Check if SOL balance is insufficient (less than 0.001 SOL needed for transactions)
      if (_viewModel.solBalance < 0.001) {
        final DateTime now = DateTime.now();
        if (_lastDialogShownTime != null && now.difference(_lastDialogShownTime!).inSeconds < 30) {
          return;
        }

        // Show dialog if account needs funding
        // ignore: use_build_context_synchronously
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
              'Your SOL account requires funding before transactions can be processed. Please transfer SOL to your wallet address to continue.',
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
                  _lastDialogShownTime = DateTime.now();
                  // Clear the first-time flag if it was set (for first-time users)
                  _walletStorageService.clearFirstTimeUserFlag();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
        _lastDialogShownTime = DateTime.now();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshBalances();
      _loadTransactionsFromRepository();
      // Check funding status when app resumes (after balances refresh)
      Future<void>.delayed(const Duration(milliseconds: 500), _checkAndShowFundingDialog);
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
                                      GestureDetector(
                                        onTap: () => viewModel.refreshTransactionsFromButton(),
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFEBECEF),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.refresh,
                                            color: Colors.blue,
                                            size: 20,
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
                              child: TransactionsList(viewModel: viewModel),
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
                  Tooltip(
                    richMessage: TextSpan(
                      children: <InlineSpan>[
                        WidgetSpan(
                          child: SizedBox(
                            width: 250,
                            child: Center(
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: <InlineSpan>[
                                    const TextSpan(
                                      text: 'Solana details\n\n',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Network: ${_isMainnet ? 'Mainnet' : 'Devnet'}\n',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: '\n',
                                      style: TextStyle(fontSize: 8),
                                    ),
                                    const TextSpan(
                                      text: 'Address:\n',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${viewModel.wallet?.address}\n',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: '\nBalance:\n',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${viewModel.solBalance} SOL\n',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: '\nToken Account:\n',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${viewModel.tokenAccount?.pubkey}\n',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    preferBelow: true,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
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
                    // Use replace to avoid navigation stack issues
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
                  context.go('/pay_request');
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
