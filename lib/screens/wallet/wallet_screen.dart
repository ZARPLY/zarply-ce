import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../../provider/wallet_provider.dart';
import '../../services/transaction_parser_service.dart';
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
  final Map<String, List<TransactionDetails?>> _transactions =
      <String, List<TransactionDetails?>>{};
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
      final Map<String, List<TransactionDetails?>> transactions =
          await walletSolanaService.getAccountTransactions(
        walletAddress: wallet.address,
      );

      setState(() {
        _walletAmount = walletAmount;
        _solBalance = solBalance;
        _transactions.addAll(transactions);
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
                  _isExpanded ? 0 : MediaQuery.of(context).size.height * 0.45,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isExpanded ? 0.0 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Spacer(),
                      BalanceAmount(
                        walletAmount: _walletAmount,
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
                        child: buildTransactionsList(_transactions),
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
                  const Image(image: AssetImage('images/zarp.jpeg')),
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
          Container(
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

  Widget buildTransactionsList(
    Map<String, List<TransactionDetails?>> groupedTransactions,
  ) {
    final List<dynamic> transactionItems = <dynamic>[];

    final List<String> sortedMonths = groupedTransactions.keys.toList()
      ..sort((String a, String b) => b.compareTo(a));

    for (final String monthKey in sortedMonths) {
      transactionItems.add(<String, String>{
        'type': 'header',
        'month': _formatMonthHeader(monthKey),
      });
      transactionItems.addAll(groupedTransactions[monthKey]!);
    }

    return ListView.builder(
      itemCount: transactionItems.length,
      itemBuilder: (BuildContext context, int index) {
        final dynamic item = transactionItems[index];

        if (item is Map && item['type'] == 'header') {
          return Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
            child: Text(
              item['month'],
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }

        return _buildTransactionTile(item);
      },
    );
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
        TransactionDetailsParser.parseTransferDetails(transaction);

    if (transferInfo == null) {
      return const SizedBox.shrink();
    }

    return ActivityItem(
      transferInfo: transferInfo,
    );
  }
}
