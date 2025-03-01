import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../provider/wallet_provider.dart';
import '../../services/transaction_parser_service.dart';
import '../../services/transaction_storage_service.dart';
import '../../services/wallet_solana_service.dart';
import '../../services/wallet_storage_service.dart';
import '../../widgets/wallet/activity_item.dart';
import '../../widgets/wallet/balance_amount.dart';
import '../../widgets/wallet/quick_actions.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  WalletScreenState createState() => WalletScreenState();
}

class WalletScreenState extends State<WalletScreen> {
  final WalletStorageService walletStorageService = WalletStorageService();
  final WalletSolanaService walletSolanaService = WalletSolanaService(
    rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
    websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
  );

  ProgramAccount? _tokenAccount;
  Wallet? _wallet;
  double _walletAmount = 0;
  double _solBalance = 0;
  bool _isLoading = true;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() {
      _isLoading = true;
    });

    final WalletProvider walletProvider =
        Provider.of<WalletProvider>(context, listen: false);
    final Wallet? wallet = walletProvider.wallet;
    final ProgramAccount? tokenAccount = walletProvider.userTokenAccount;

    if (wallet != null && tokenAccount != null) {
      final double walletAmount =
          await walletSolanaService.getZarpBalance(tokenAccount.pubkey);
      final double solBalance =
          await walletSolanaService.getSolBalance(wallet.address);

      setState(() {
        _walletAmount = walletAmount;
        _solBalance = solBalance;
        _tokenAccount = tokenAccount;
        _wallet = wallet;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshBalances() async {
    if (_tokenAccount != null && _wallet != null) {
      final double walletAmount =
          await walletSolanaService.getZarpBalance(_tokenAccount!.pubkey);
      final double solBalance =
          await walletSolanaService.getSolBalance(_wallet!.address);

      setState(() {
        _walletAmount = walletAmount;
        _solBalance = solBalance;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height:
                  _isExpanded ? 0 : MediaQuery.of(context).size.height * 0.35,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isExpanded ? 0.0 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 16),
                      BalanceAmount(
                        walletAmount: _walletAmount,
                        walletAddress: _wallet?.address ?? '',
                      ),
                      const Spacer(),
                      const QuickActions(),
                    ],
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
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEBECEF),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isExpanded
                                    ? Icons.keyboard_arrow_down
                                    : Icons.keyboard_arrow_up,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                          Text(
                            'History',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.blue,
                                    ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: TransactionsList(
                          tokenAccount: _tokenAccount,
                          walletSolanaService: walletSolanaService,
                          onRefreshStarted: _refreshBalances,
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
                                text: '${_wallet?.address}\n',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: '$_solBalance SOL\n',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(
                                text: '${_tokenAccount?.pubkey}\n',
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
                    color: Colors.black.withOpacity(0.1),
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
              ).then((String? value) {
                if (value == 'logout') {
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class TransactionsList extends StatefulWidget {
  const TransactionsList({
    required this.tokenAccount,
    required this.walletSolanaService,
    required this.onRefreshStarted,
    super.key,
  });

  final ProgramAccount? tokenAccount;
  final WalletSolanaService walletSolanaService;
  final Future<void> Function() onRefreshStarted;

  @override
  TransactionsListState createState() => TransactionsListState();
}

class TransactionsListState extends State<TransactionsList> {
  final TransactionStorageService _transactionStorageService =
      TransactionStorageService();
  final Map<String, List<TransactionDetails?>> _transactions =
      <String, List<TransactionDetails?>>{};
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    if (widget.tokenAccount == null) return;

    final Map<String, List<TransactionDetails?>> transactions =
        await _transactionStorageService.getStoredTransactions();

    if (transactions.isEmpty || _isRefreshing) {
      final String? lastSignature =
          await _transactionStorageService.getLastTransactionSignature();

      final Map<String, List<TransactionDetails?>> newTransactions =
          await widget.walletSolanaService.getAccountTransactions(
        walletAddress: widget.tokenAccount!.pubkey,
        before: lastSignature,
      );

      final Set<String> existingSignatures = <String>{};
      for (final List<TransactionDetails?> monthTransactions
          in transactions.values) {
        for (final TransactionDetails? tx in monthTransactions) {
          if (tx != null) {
            final String sig = tx.transaction.toJson()['signatures'][0];
            existingSignatures.add(sig);
          }
        }
      }

      bool hasNewTransactions = false;
      for (final String monthKey in newTransactions.keys) {
        if (!transactions.containsKey(monthKey)) {
          transactions[monthKey] = <TransactionDetails?>[];
        }

        final List<TransactionDetails?> uniqueNewTransactions =
            newTransactions[monthKey]!.where((TransactionDetails? tx) {
          if (tx == null) return false;
          final String sig = tx.transaction.toJson()['signatures'][0];
          final bool isUnique = !existingSignatures.contains(sig);
          if (isUnique) {
            hasNewTransactions = true;
          }
          return isUnique;
        }).toList();

        if (uniqueNewTransactions.isNotEmpty) {
          transactions[monthKey]!.insertAll(0, uniqueNewTransactions);
        }
      }

      if (hasNewTransactions) {
        await _transactionStorageService.storeTransactions(transactions);
      }
    }

    setState(() {
      _transactions.clear();
      _transactions.addAll(transactions);
      if (_isRefreshing) _isRefreshing = false;
    });
  }

  Future<void> _refreshTransactions() async {
    setState(() {
      _isRefreshing = true;
    });

    await Future.wait(<Future<void>>[
      widget.onRefreshStarted(),
      _loadTransactions(),
    ]);
  }

  String _formatMonthHeader(String monthKey) {
    final List<String> parts = monthKey.split('-');
    final String year = parts[0];
    final int month = int.parse(parts[1]);

    final List<String> monthNames = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${monthNames[month - 1]} $year';
  }

  Widget _buildTransactionTile(TransactionDetails? transaction) {
    if (transaction == null) return const SizedBox.shrink();
    final TransactionTransferInfo? transferInfo =
        TransactionDetailsParser.parseTransferDetails(
      transaction,
      widget.tokenAccount?.pubkey ?? '',
    );

    if (transferInfo == null || transferInfo.amount == 0) {
      return const SizedBox.shrink();
    }

    return ActivityItem(
      transferInfo: transferInfo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> transactionItems = <dynamic>[];

    final List<String> sortedMonths = _transactions.keys.toList()
      ..sort((String a, String b) => b.compareTo(a));

    for (final String monthKey in sortedMonths) {
      transactionItems.add(<String, dynamic>{
        'type': 'header',
        'month': _formatMonthHeader(monthKey),
        'monthKey': monthKey,
        'count': _transactions[monthKey]!.length,
      });
      final List<TransactionDetails?> sortedTransactions =
          List<TransactionDetails?>.from(_transactions[monthKey]!)
            ..sort((TransactionDetails? a, TransactionDetails? b) {
              if (a == null || b == null) return 0;
              return (b.blockTime ?? 0).compareTo(a.blockTime ?? 0);
            });
      transactionItems.addAll(sortedTransactions);
    }

    return RefreshIndicator(
      onRefresh: _refreshTransactions,
      child: ListView.builder(
        itemCount: transactionItems.length,
        itemBuilder: (BuildContext context, int index) {
          final dynamic item = transactionItems[index];

          if (item is Map && item['type'] == 'header') {
            final String monthKey = item['monthKey'];
            final int displayedCount =
                _transactions[monthKey]!.where((TransactionDetails? tx) {
              if (tx == null) return false;
              final TransactionTransferInfo? transferInfo =
                  TransactionDetailsParser.parseTransferDetails(
                tx,
                widget.tokenAccount?.pubkey ?? '',
              );
              return transferInfo != null && transferInfo.amount != 0;
            }).length;

            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    item['month'],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '$displayedCount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return _buildTransactionTile(item);
        },
      ),
    );
  }
}
