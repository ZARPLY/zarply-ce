import 'package:flutter/material.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';
import 'package:intl/intl.dart';
import 'package:zarply/components/balance_amount.dart';
import 'package:zarply/services/transaction_parser_service.dart';
import 'package:zarply/services/wallet_solana_service.dart';
import 'package:zarply/services/wallet_storage_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // services
  final walletStorageService = WalletStorageService();
  final walletSolanaService = WalletSolanaService(
      rpcUrl: 'https://api.devnet.solana.com',
      websocketUrl: 'wss://api.devnet.solana.com');

  // data storing variables
  Wallet? _wallet;
  double _walletAmount = 0;
  final List<TransactionDetails?> _transactions = [];
  bool isLamport = true;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    Wallet? wallet = await walletStorageService.retrieveWallet();
    if (wallet != null) {
      final walletAmount =
          await walletSolanaService.getAccountBalance(wallet.address);
      final transactions = await walletSolanaService.getAccountTransactions(
          walletAddress: wallet.address);

      setState(() {
        _wallet = wallet;
        _walletAmount = walletAmount;
        _transactions.addAll(transactions);
      });
    }
  }

  void _createWallet() async {
    var wallet = await walletSolanaService.createWallet();
    if (wallet.address.isNotEmpty) {
      final walletAmount =
          await walletSolanaService.getAccountBalance(wallet.address);
      final transactions = await walletSolanaService.getAccountTransactions(
          walletAddress: wallet.address);

      setState(() {
        _wallet = wallet;
        _walletAmount = walletAmount;
        _transactions.addAll(transactions);
      });
      walletStorageService.saveWallet(wallet);
    }
  }

  void _makeTransaction() async {
    // await walletSolanaService.requestAirdrop(_wallet!.address, 100000000);
    final transaction = await walletSolanaService.sendTransaction(
        senderWallet: _wallet!,
        recipientAddress: "5cwnBsrohuK84gbTig8sZgN4ALF4M3MBaRZasB5r3Moy",
        lamports: 500000);

    if (transaction.isNotEmpty) {
      _refreshWallet();
    }
  }

  void _refreshWallet() async {
    final walletAmount =
        await walletSolanaService.getAccountBalance(_wallet!.address);
    final transactions = await walletSolanaService.getAccountTransactions(
        walletAddress: _wallet!.address);

    if (transactions.isNotEmpty) {
      setState(() {
        _walletAmount = walletAmount;
        _transactions.addAll(transactions);
      });
    }
  }

  // Utility method to shorten wallet addresses
  String _shortenAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 5)}...${address.substring(address.length - 5)}';
  }

  // Utility method to format datetime
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    if (_wallet == null) {
      return Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ElevatedButton(
                onPressed: _createWallet, child: const Text('Create Wallet')),
          ));
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              children: [
                Row(
                  children: [
                    Switch(
                      value: isLamport,
                      onChanged: (value) {
                        setState(() {
                          isLamport = value;
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child:
                          Center(child: Text(isLamport ? "Lamport" : "Rand")),
                    ),
                  ],
                ),
                BalanceAmount(
                    isLamport: isLamport, walletAmount: _walletAmount),
                ElevatedButton.icon(
                  onPressed: _makeTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25), // Rounded shape
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                  ),
                  icon: const Icon(Icons.more_horiz, color: Colors.black),
                  label: const Text(
                    "Make transaction",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                // const QuickActions(),
              ],
            ),
          ),
          Flexible(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[100],
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(25), // Rounded shape
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 15),
                      ),
                      icon: const Icon(Icons.expand, color: Colors.black),
                      label: const Text(
                        "Contact",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    const Text("History")
                  ],
                ),
                Flexible(
                  flex: 1,
                  child: ListView.builder(
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions.elementAt(index);
                        final transferInfo =
                            TransactionDetailsParser.parseTransferDetails(
                                transaction!);

                        if (transferInfo == null) {
                          return ListTile(
                            title: const Text('Non-transfer Transaction'),
                            subtitle: Text(transaction.transaction
                                .toJson()["signatures"]!
                                .first),
                          );
                        }

                        return ListTile(
                          title:
                              Text('Transfer: ${transferInfo.formattedAmount}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'To: ${_shortenAddress(transferInfo.recipient)}'),
                              if (transferInfo.timestamp != null)
                                Text(
                                    'Date: ${_formatDateTime(transferInfo.timestamp!)}'),
                            ],
                          ),
                        );
                      }),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
