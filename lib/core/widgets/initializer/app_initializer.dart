import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solana/solana.dart';

import '../../provider/wallet_provider.dart';

class AppInitializer extends StatefulWidget {
  const AppInitializer({required this.child, super.key});
  final Widget child;

  static _AppData of(BuildContext context) => _AppData.of(context);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late final Future<bool> _initFuture;

  @override
  void initState() {
    super.initState();
    final WalletProvider walletProvider =
        Provider.of<WalletProvider>(context, listen: false);

    print(
        'DEBUG: AppInitializer initState - isReady: ${walletProvider.isReady}, hasWallet: ${walletProvider.hasWallet}');

    // Only initialize if not already ready and doesn't have wallet data
    if (!walletProvider.isReady || walletProvider.wallet == null) {
      print('DEBUG: AppInitializer calling initialize()');
      _initFuture = walletProvider.initialize();
    } else {
      // If already ready and has wallet, just return true
      print(
          'DEBUG: AppInitializer skipping initialize() - already ready with wallet: ${walletProvider.wallet?.address}');
      _initFuture = Future<bool>.value(true);
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

        if (snapshot.data == true) {
          final WalletProvider walletProvider =
              Provider.of<WalletProvider>(context, listen: false);

          print(
              'DEBUG: AppInitializer build - wallet exists: ${walletProvider.wallet != null}');

          // Check if wallet exists before creating AppData
          if (walletProvider.wallet != null) {
            return _AppData(
              wallet: walletProvider.wallet!,
              walletBalance: walletProvider.walletBalance,
              solBalance: walletProvider.solBalance,
              child: widget.child,
            );
          } else {
            // If no wallet after initialization, just return the child
            print('DEBUG: AppInitializer no wallet found, returning child');
            return widget.child;
          }
        }
        return widget.child;
      },
    );
  }
}

class _AppData extends InheritedWidget {
  const _AppData({
    required this.wallet,
    required this.walletBalance,
    required this.solBalance,
    required super.child,
  });

  final Wallet wallet;
  final double walletBalance;
  final double solBalance;

  static _AppData of(BuildContext context) {
    final _AppData? data =
        context.dependOnInheritedWidgetOfExactType<_AppData>();
    assert(data != null, 'AppInitializer.of() called with no ancestor!');
    return data!;
  }

  @override
  bool updateShouldNotify(_AppData oldWidget) =>
      wallet != oldWidget.wallet ||
      walletBalance != oldWidget.walletBalance ||
      solBalance != oldWidget.solBalance;
}
