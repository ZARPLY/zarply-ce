import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';

import '../services/transaction_parser_service.dart';
import '../services/wallet_solana_service.dart';
import '../services/wallet_storage_service.dart';
import '../widgets/activity_item.dart';
import '../widgets/balance_amount.dart';
import '../widgets/quick_actions.dart';
import '../widgets/toggle_bar.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // services
  final WalletStorageService walletStorageService = WalletStorageService();

  final WalletSolanaService walletSolanaService = WalletSolanaService(
    rpcUrl: dotenv.env['solana_wallet_rpc_url'] ?? '',
    websocketUrl: dotenv.env['solana_wallet_websocket_url'] ?? '',
  );

  // data storing variables
  Wallet? _wallet;
  double _walletAmount = 0;
  final Map<String, List<TransactionDetails?>> _transactions =
      <String, List<TransactionDetails?>>{};
  bool isLamport = true;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    await _loadWalletFromStorage();
    if (_wallet != null) {
      await _loadWalletData();
    }
  }

  Future<void> _loadWalletFromStorage() async {
    final Wallet? wallet = await walletStorageService.retrieveWallet();
    setState(() {
      _wallet = wallet;
    });
  }

  Future<void> _loadWalletData() async {
    final double walletAmount =
        await walletSolanaService.getAccountBalance(_wallet!.address);
    final Map<String, List<TransactionDetails?>> transactions =
        await walletSolanaService.getAccountTransactions(
      walletAddress: _wallet!.address,
    );

    setState(() {
      _walletAmount = walletAmount;
      _transactions.addAll(transactions);
    });
  }

  Future<void> _createWallet() async {
    final Wallet wallet = await walletSolanaService.createWallet();
    if (wallet.address.isNotEmpty) {
      await walletStorageService.saveWallet(wallet);
      setState(() {
        _wallet = wallet;
      });

      await _loadWalletData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_wallet == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ElevatedButton(
            onPressed: _createWallet,
            child: const Text('Create Wallet'),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Flexible(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const ToggleBar(),
                    Row(
                      children: <Widget>[
                        const SizedBox(
                          width: 30,
                          height: 30,
                          child: Image(image: AssetImage('images/saflag.png')),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.white30,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'JT',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                BalanceAmount(
                  isLamport: isLamport,
                  walletAmount: _walletAmount,
                ),
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
              padding: const EdgeInsets.all(8),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: GestureDetector(
                          onTap: () {
                            log('Circular button clicked');
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(235, 236, 239, 1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.keyboard_arrow_up,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'Activity',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
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
    );
  }
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
          padding: const EdgeInsets.all(8),
          child: Text(
            item['month'],
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
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
