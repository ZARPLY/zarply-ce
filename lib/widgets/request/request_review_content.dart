import 'package:flutter/material.dart';
import '../../utils/formatters.dart';
import 'request_qrcode.dart';

class RequestReviewContent extends StatefulWidget {
  const RequestReviewContent({
    required this.amount,
    required this.onCancel,
    super.key,
  });
  final String amount;
  final VoidCallback onCancel;

  @override
  State<RequestReviewContent> createState() => _RequestReviewContentState();
}

class _RequestReviewContentState extends State<RequestReviewContent> {
  bool isRequestReadyForPayment = false;

  Future<void> _requestReadyForPayment() async {
    setState(() {
      isRequestReadyForPayment = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return !isRequestReadyForPayment
        ? Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Review Request',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: widget.onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF9BA1AC),
                  ),
                  child: const Icon(
                    Icons.call_received,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  Formatters.formatAmount(double.parse(widget.amount) / 100),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 32),
                Text(
                  'Minimum amount is R5',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Valid for 24 hours',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue,
                      ),
                ),
                const Spacer(),
                Text(
                  'Review the details before making a payment. Once complete, this payment cannot be reversed. Confirm to proceed.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _requestReadyForPayment,
                    style: ElevatedButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Confirm Payment'),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          )
        : RequestQRCode(amount: widget.amount);
  }
}
