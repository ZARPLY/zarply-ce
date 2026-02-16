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

  /// Minimum SOL required for rent exemption and transaction fees.
  static const double minSolForFees = 0.003;

  final double solBalance;
  final double zarpBalance;

  /// True if SOL balance is sufficient for fees.
  bool get hasEnoughSolForFees => solBalance >= minSolForFees;
}
