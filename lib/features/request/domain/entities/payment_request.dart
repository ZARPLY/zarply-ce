class PaymentRequest {
  PaymentRequest({
    required this.amount,
    required this.walletAddress,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory PaymentRequest.fromJson(Map<String, dynamic> json) => PaymentRequest(
    amount: json['amount'],
    walletAddress: json['walletAddress'],
    timestamp: json['timestamp'],
  );
  final String amount;
  final String walletAddress;
  final int timestamp;

  String get qrCodeData => 'zarply:payment:$amount:$walletAddress:$timestamp';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'amount': amount,
    'walletAddress': walletAddress,
    'timestamp': timestamp,
  };
}
