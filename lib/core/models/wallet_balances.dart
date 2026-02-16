/// Immutable balance pair for SOL and ZARP.
class WalletBalances {
  const WalletBalances({
    required this.solBalance,
    required this.zarpBalance,
  });

  factory WalletBalances.empty() {
    return const WalletBalances(
      solBalance: 0,
      zarpBalance: 0,
    );
  }

  final double solBalance;
  final double zarpBalance;
}
