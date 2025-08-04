import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:solana/dto.dart';

import '../../../../core/provider/auth_provider.dart';
import '../../../../core/provider/wallet_provider.dart';
import '../../../../core/services/exchange_rate_service.dart';
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
  bool _isDropdownOpen = false;
  bool _isSolMode = false; // Switch state for ZARP/SOL toggle
  double _currentSolToZarRate =
      2962.5; // Default rate based on your example (2629.47 ZAR = 0.8878 SOL)
  Timer? _exchangeRateTimer;

  Future<void> _loadExchangeRate() async {
    try {
      final double newRate = await ExchangeRateService.getSolToZarRate();
      if (newRate != _currentSolToZarRate) {
        _currentSolToZarRate = newRate;
        print('Updated SOL/ZAR rate: $_currentSolToZarRate'); // Debug log
        setState(() {});
      }
    } catch (e) {
      print('Failed to load exchange rate: $e'); // Debug log
      // Keep current rate if API fails
    }
  }

  void _startExchangeRateUpdates() {
    // Update exchange rate every 5 minutes
    _exchangeRateTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _loadExchangeRate();
    });
  }

  void _stopExchangeRateUpdates() {
    _exchangeRateTimer?.cancel();
    _exchangeRateTimer = null;
  }

  double _convertZarpToSol(double zarpAmount) {
    final double solAmount = zarpAmount / _currentSolToZarRate;
    print(
        'Converting $zarpAmount ZAR to SOL: $solAmount (rate: $_currentSolToZarRate)'); // Debug log
    print('Current ZARP balance: ${_viewModel.walletAmount}'); // Debug log
    print('Current SOL balance: ${_viewModel.solBalance}'); // Debug log
    return solAmount;
  }

  String _getCurrentCurrency() {
    return _isSolMode ? 'SOL' : 'ZARP';
  }

  String _getCurrentImage() {
    return _isSolMode ? 'images/solana.png' : 'images/zarp.png';
  }

  String _getCurrentAddress() {
    if (_isSolMode) {
      return _viewModel.wallet?.address ?? '';
    } else {
      return _viewModel.tokenAccount?.pubkey ?? '';
    }
  }

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

    // Load real-time exchange rate
    _loadExchangeRate();
    _startExchangeRateUpdates();
  }

  Future<void> _loadTransactionsFromRepository() async {
    try {
      final Map<String, List<TransactionDetails?>> storedTransactions =
          await _viewModel.loadStoredTransactions(
              selectedCurrency: _getCurrentCurrency());

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
    _stopExchangeRateUpdates();
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
                              // Debug logging
                              Builder(
                                builder: (context) {
                                  final double displayAmount = _isSolMode
                                      ? _convertZarpToSol(
                                          viewModel.walletAmount)
                                      : viewModel.walletAmount;
                                  print(
                                      'Display amount: $displayAmount (isSolMode: $_isSolMode)');
                                  print(
                                      'ZARP amount: ${viewModel.walletAmount}');
                                  print('SOL amount: ${viewModel.solBalance}');
                                  return BalanceAmount(
                                    walletAmount: displayAmount,
                                    walletAddress: _isSolMode
                                        ? _viewModel.wallet?.address ?? ''
                                        : _viewModel.tokenAccount?.pubkey ?? '',
                                    selectedCurrency:
                                        _isSolMode ? 'SOL' : 'ZARP',
                                  );
                                },
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
                              child: TransactionsList(
                                viewModel: viewModel,
                                selectedCurrency: _getCurrentCurrency(),
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
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDropdownOpen = !_isDropdownOpen;
                      });

                      showMenu(
                        context: context,
                        position: RelativeRect.fromLTRB(
                          0,
                          kToolbarHeight +
                              MediaQuery.of(context).padding.top +
                              10,
                          0,
                          0,
                        ),
                        items: <PopupMenuEntry<String>>[
                          PopupMenuItem<String>(
                            value: 'zarp',
                            child: Row(
                              children: <Widget>[
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Image(
                                      image: AssetImage('images/zarp.png')),
                                ),
                                const SizedBox(width: 8),
                                Text('ZARP'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'sol',
                            child: Row(
                              children: <Widget>[
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Image(
                                      image: AssetImage('images/solana.png')),
                                ),
                                const SizedBox(width: 8),
                                const Text('SOL'),
                              ],
                            ),
                          ),
                        ],
                      ).then((String? value) {
                        setState(() {
                          _isDropdownOpen = false;
                        });
                        if (value == 'sol') {
                          setState(() {
                            _isSolMode = true;
                          });
                          // Refresh exchange rate and reload transactions for SOL
                          _loadExchangeRate();
                          _viewModel.forceRefreshBalances();
                          _loadTransactionsFromRepository();
                        } else if (value == 'zarp') {
                          setState(() {
                            _isSolMode = false;
                          });
                          // Reload transactions for ZARP
                          _viewModel.forceRefreshBalances();
                          _loadTransactionsFromRepository();
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: Image(
                                image: AssetImage(_isSolMode
                                    ? 'images/solana.png'
                                    : 'images/zarp.png')),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isSolMode ? 'SOL' : 'ZARP',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: _isDropdownOpen ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
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
