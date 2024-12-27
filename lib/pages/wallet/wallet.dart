import 'dart:developer';

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
  // services
  final WalletStorageService walletStorageService = WalletStorageService();

  final WalletSolanaService walletSolanaService = WalletSolanaService(
    rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
    websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
  );

  // data storing variables
  double _walletAmount = 0;
  final Map<String, List<TransactionDetails?>> _transactions =
      <String, List<TransactionDetails?>>{};
  bool isLamport = true;
  bool _isLoading = true;

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

    if (wallet != null) {
      final double walletAmount =
          await walletSolanaService.getAccountBalance(wallet.address);
      final Map<String, List<TransactionDetails?>> transactions =
          await walletSolanaService.getAccountTransactions(
        walletAddress: wallet.address,
      );

      setState(() {
        _walletAmount = walletAmount;
        _transactions.addAll(transactions);
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Spacer(),
                  BalanceAmount(
                    isLamport: isLamport,
                    walletAmount: _walletAmount,
                  ),
                  const Spacer(),
                  const QuickActions(),
                ],
              ),
            ),
          ),
          Flexible(
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
                            log('Circular button clicked');
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEBECEF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.keyboard_arrow_up,
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
                    Flexible(
                      flex: 1,
                      child: buildTransactionsList(_transactions),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
            Container(
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
            context.go('/pay-request');
          },
          shape: const CircleBorder(),
          backgroundColor: Colors.blue,
          child: const Padding(
            padding: EdgeInsets.only(right: 2, top: 8),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Image(
                image: AssetImage('images/zarply_logo.png'),
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
