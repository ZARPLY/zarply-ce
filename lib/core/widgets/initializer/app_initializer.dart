import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solana/solana.dart';
import 'package:zarply/core/provider/wallet_provider.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({required this.child, Key? key }) : super(key: key);
  final Widget child;

  @override
  State<AppInitializer> createState() => _AppInitializerState();

  static _AppData of(BuildContext context) {
    return _AppData.of(context);
  }
}

class _AppInitializerState extends State<AppInitializer> {
  late Future<bool> _initFuture; 

  @override
  void initState(){
    super.initState();
    final WalletProvider walletProvider = Provider.of<WalletProvider>(context, listen: false);
    _initFuture = walletProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _initFuture,
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final bool hasWallet = snapshot.data == true;
        if (hasWallet) {
          final Wallet wallet = Provider.of<WalletProvider>(context, listen: false).wallet!;
          final double walletBalance =
            Provider.of<WalletProvider>(context, listen: false).walletBalance;
          final double solBalance =
            Provider.of<WalletProvider>(context, listen: false).solBalance;
        
        return _AppData(
          wallet: wallet,
          walletBalance:walletBalance,
          solBalance: solBalance,
          child: widget.child,
        );
        } else {
          return widget.child; 
        }
      },
    );
  }
}


class _AppData extends InheritedWidget {
  const _AppData({
    required this.wallet, 
    required this.walletBalance,
    required this.solBalance, 
    required Widget child,
  }) : super(child: child);

  final Wallet wallet; 
  final double walletBalance;
  final double solBalance;

  static _AppData of(BuildContext context) {
    final _AppData? data = context.dependOnInheritedWidgetOfExactType<_AppData>();
    assert(data != null, 'No AppInitializer above in the tree');
    return data!;
  }

  @override
  bool updateShouldNotify(_AppData oldWidget) {
    return wallet != oldWidget.wallet ||
      walletBalance != oldWidget.walletBalance ||
      solBalance != oldWidget.solBalance;
  }
}
