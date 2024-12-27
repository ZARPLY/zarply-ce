import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'request_completed.dart';

class RequestQRCode extends StatefulWidget {
  const RequestQRCode({
    required this.amount,
    super.key,
  });

  final String amount;

  @override
  State<RequestQRCode> createState() => _RequestQRCodeState();
}

class _RequestQRCodeState extends State<RequestQRCode> {
  bool isQRCodeShared = false;

  void _shareQRCode() {
    // Implement sharing functionality
    Share.share('Payment request for R${widget.amount}');
    setState(() {
      isQRCodeShared = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return !isQRCodeShared
        ? Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Request Sent',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w400,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                QrImageView(
                  data: 'zarply:payment:${widget.amount}',
                  version: QrVersions.auto,
                  size: 300,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.blue,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.blue,
                  ),
                  embeddedImage:
                      const AssetImage('images/qr_code_zarply_logo.png'),
                  embeddedImageStyle: const QrEmbeddedImageStyle(
                    size: Size(60, 60),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'R${widget.amount}',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Valid for 24 hours',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue,
                      ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _shareQRCode,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('Share Barcode'),
                        SizedBox(width: 8),
                        Icon(Icons.ios_share),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          )
        : RequestCompleted(amount: widget.amount);
  }
}
