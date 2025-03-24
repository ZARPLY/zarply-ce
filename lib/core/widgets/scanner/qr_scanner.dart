import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../features/request/domain/entities/payment_request.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  MobileScannerController controller = MobileScannerController();
  final ImagePicker _picker = ImagePicker();

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;

    try {
      for (final Barcode barcode in barcodes) {
        final String? code = barcode.rawValue;
        if (code != null && code.startsWith('zarply:payment:')) {
          final List<String> parts = code.split(':');
          if (parts.length == 5) {
            final String amount = parts[2];
            final String walletAddress = parts[3];
            final int timestamp = int.parse(parts[4]);

            final PaymentRequest paymentRequest = PaymentRequest(
              amount: amount,
              walletAddress: walletAddress,
              timestamp: timestamp,
            );

            final bool isExpired =
                DateTime.now().millisecondsSinceEpoch - timestamp > 86400000;

            if (isExpired) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'This QR code has expired. Please request a new one.',
                  ),
                ),
              );
              return;
            }

            if (mounted) {
              context.go(
                '/payment_amount',
                extra: <String, String>{
                  'amount': paymentRequest.amount,
                  'recipientAddress': paymentRequest.walletAddress,
                  'source': '/scan',
                },
              );
            }
            break;
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error processing QR code')),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _uploadQRCode() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final BarcodeCapture? barcodeCapture =
          await controller.analyzeImage(image.path);

      if (barcodeCapture == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not detect a QR code in this image. '
                'Please ensure the image is clear and contains a valid QR code.'),
          ),
        );
        return;
      }

      if (barcodeCapture.barcodes.isNotEmpty &&
          barcodeCapture.barcodes.first.rawValue != null) {
        final String code = barcodeCapture.barcodes.first.rawValue!;
        if (code.startsWith('zarply:payment:')) {
          final List<String> parts = code.split(':');
          if (parts.length == 5) {
            final String amount = parts[2];
            final String walletAddress = parts[3];
            final int timestamp = int.parse(parts[4]);

            final PaymentRequest paymentRequest = PaymentRequest(
              amount: amount,
              walletAddress: walletAddress,
              timestamp: timestamp,
            );

            final bool isExpired =
                DateTime.now().millisecondsSinceEpoch - timestamp > 86400000;

            if (isExpired) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'This QR code has expired. Please request a new one.',
                  ),
                ),
              );
              return;
            }

            if (mounted) {
              context.go(
                '/payment_amount',
                extra: <String, String>{
                  'amount': paymentRequest.amount,
                  'recipientAddress': paymentRequest.walletAddress,
                  'source': '/scan',
                },
              );
            }
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error processing image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8, right: 8),
          child: InkWell(
            onTap: () => context.go('/wallet'),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEBECEF),
                borderRadius: BorderRadius.circular(80),
              ),
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.arrow_back_ios,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        title: const Text('Scan QR Code'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _uploadQRCode,
            tooltip: 'Upload QR Code',
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: _onDetect,
        overlayBuilder: (BuildContext context, BoxConstraints constraints) =>
            const QRScannerOverlay(),
      ),
    );
  }
}

class QRScannerOverlay extends StatelessWidget {
  const QRScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const ShapeDecoration(
        shape: QRScannerOverlayShape(
          borderColor: Colors.blue,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: 250,
        ),
      ),
    );
  }
}

class QRScannerOverlayShape extends ShapeBorder {
  const QRScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..addRect(rect)
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.center,
            width: cutOutSize,
            height: cutOutSize,
          ),
          Radius.circular(borderRadius),
        ),
      );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final Paint paint = Paint()..color = overlayColor;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        getOuterPath(rect),
      ),
      paint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}
