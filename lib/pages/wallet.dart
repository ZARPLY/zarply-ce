import 'package:flutter/material.dart';
import 'package:solana/dto.dart';
import 'package:solana/solana.dart';
import 'package:zarply/components/balance_amount.dart';
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
  Iterable<TransactionDetails> _transactions = const Iterable.empty();
  bool isLamport = true;

  @override
  void initState() {
    super.initState();
    _getWallet();
  }

  Future<void> _getWallet() async {
    Wallet? wallet = await walletStorageService.retrieveWallet();
    if (wallet != null) {
      final walletAmount =
          await walletSolanaService.getAccountBalance(wallet.address);
      // final transactions =
      //     await walletSolanaService.getAccountTransactions(wallet.address);
      setState(() {
        _wallet = wallet;
        _walletAmount = walletAmount;
        // _transactions = transactions;
      });
    }
  }

  void _createWallet() async {
    var wallet = await walletSolanaService.createWallet();
    if (wallet.address.isNotEmpty) {
      final walletAmount =
          await walletSolanaService.getAccountBalance(wallet.address);
      final transactions =
          await walletSolanaService.getAccountTransactions(wallet.address);

      setState(() {
        _wallet = wallet;
        _walletAmount = walletAmount;
        _transactions = transactions;
      });
      walletStorageService.saveWallet(wallet);
    }
  }

  void _makeTransaction() async {
    await walletSolanaService.requestAirdrop(_wallet!.address, 100000000);
    final transaction = await walletSolanaService.sendTransaction(
        senderWallet: _wallet!,
        recipientAddress: "5cwnBsrohuK84gbTig8sZgN4ALF4M3MBaRZasB5r3Moy",
        lamports: 500000000);

    if (transaction.isNotEmpty) {
      final walletAmount =
          await walletSolanaService.getAccountBalance(_wallet!.address);
      final transactions =
          await walletSolanaService.getAccountTransactions(_wallet!.address);
      setState(() async {
        _walletAmount = walletAmount;
        _transactions = transactions;
      });
    }
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
                        final transaction =
                            _transactions.elementAt(index).transaction.toJson();
                        final meta = _transactions.elementAt(index).meta;
                        return ListTile(
                          title: Text(transaction["messsage"]),
                          subtitle: Text(meta!.returnData!.data),
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
