import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:solana/dto.dart';

import '../../../../core/provider/auth_provider.dart';
import '../../../../core/provider/wallet_provider.dart';
import '../models/wallet_view_model.dart';
import '../widgets/balance_amount.dart';
import '../widgets/quick_actions.dart';
import '../widgets/transactions_list.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with WidgetsBindingObserver {
  late WalletViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _viewModel = WalletViewModel();

    final WalletProvider walletProvider =
        Provider.of<WalletProvider>(context, listen: false);
    _viewModel.wallet = walletProvider.wallet;
    _viewModel.tokenAccount = walletProvider.userTokenAccount;

    // Load transactions from repository
    _loadTransactionsFromRepository();

    _viewModel.loadCachedBalances();

    _viewModel.isLoadingTransactions = false;
  }

  Future<void> _loadTransactionsFromRepository() async {
    try {
      final Map<String, List<TransactionDetails?>> storedTransactions =
          await _viewModel.loadStoredTransactions();

      if (storedTransactions.isNotEmpty) {
        _viewModel.updateOldestSignature();
        await _viewModel.updateTransactionCount();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading transactions from repository: $e'),
        ),
      );
    }
  }

  Future<void> _refreshBalances() async {
    await _viewModel.loadCachedBalances();
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
                    height: viewModel.isExpanded
                        ? 0
                        : MediaQuery.of(context).size.height * 0.35,
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                            viewModel.isExpanded
                                                ? Icons.keyboard_arrow_down
                                                : Icons.keyboard_arrow_up,
                                            color: Colors.black,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => viewModel
                                            .refreshTransactionsFromButton(),
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                                      text: '${viewModel.wallet?.address}\n',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${viewModel.solBalance} SOL\n',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          '${viewModel.tokenAccount?.pubkey}\n',
                                      style: const TextStyle(fontSize: 14),
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  onTap: () {
                    showMenu(
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
                    ).then((String? value) async {
                      if (value == 'logout') {
                        await Provider.of<AuthProvider>(context, listen: false)
                            .logout();
                        context.go('/login');
                      }
                    });
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
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          );
        },
      ),
    );
  }
}
