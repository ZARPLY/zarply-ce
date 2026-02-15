/// Immutable balance pair for SOL and ZARP.
class WalletBalances {
  const WalletBalances({
    required this.solBalance,
    required this.zarpBalance,
  });

  final double solBalance;
  final double zarpBalance;
}
