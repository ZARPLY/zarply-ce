import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solana/solana.dart';

import '../../provider/wallet_provider.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({required this.child, super.key});
  final Widget child;

  static AppData of(BuildContext context) => AppData.of(context);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late final Future<bool> _initFuture;

  @override
  void initState() {
    super.initState();
    final WalletProvider walletProvider = Provider.of<WalletProvider>(context, listen: false);

    // Only initialize if not already ready
    if (!walletProvider.isReady) {
      _initFuture = walletProvider.initialize();
    } else {
      _initFuture = Future<bool>.value(walletProvider.hasWallet);
    }
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

        if (snapshot.data ?? false) {
          final WalletProvider walletProvider = Provider.of<WalletProvider>(context, listen: false);
          return AppData(
            wallet: walletProvider.wallet!,
            walletBalance: walletProvider.walletBalance,
            solBalance: walletProvider.solBalance,
            child: widget.child,
          );
        }
        return widget.child;
      },
    );
  }
}

class AppData extends InheritedWidget {
  const AppData({
    required this.wallet,
    required this.walletBalance,
    required this.solBalance,
    required super.child,
    super.key,
  });

  final Wallet wallet;
  final double walletBalance;
  final double solBalance;

  static AppData of(BuildContext context) {
    final AppData? data = context.dependOnInheritedWidgetOfExactType<AppData>();
    assert(data != null, 'AppInitializer.of() called with no ancestor!');
    return data!;
  }

  @override
  bool updateShouldNotify(AppData oldWidget) =>
      wallet != oldWidget.wallet || walletBalance != oldWidget.walletBalance || solBalance != oldWidget.solBalance;
}
