import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qr/qr.dart';

import '../../../../core/utils/formatters.dart';
import '../../domain/entities/payment_request.dart';
import '../models/request_qrcode_view_model.dart';
import 'request_completed.dart';

class RequestQRCode extends StatefulWidget {
  const RequestQRCode({
    required this.paymentRequest,
    super.key,
  });

  final PaymentRequest paymentRequest;

  @override
  State<RequestQRCode> createState() => _RequestQRCodeState();
}

class _RequestQRCodeState extends State<RequestQRCode> {
  final GlobalKey _qrKey = GlobalKey();
  late RequestQRCodeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RequestQRCodeViewModel>(
      create: (_) {
        _viewModel = RequestQRCodeViewModel(
          paymentRequest: widget.paymentRequest,
        );
        _viewModel.init();
        return _viewModel;
      },
      child: Consumer<RequestQRCodeViewModel>(
        builder: (BuildContext context, RequestQRCodeViewModel viewModel, _) {
          return !viewModel.isQRCodeShared
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
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
                        RepaintBoundary(
                          key: _qrKey,
                          child: FutureBuilder<ui.Image>(
                            future: viewModel.loadImageFuture,
                            builder:
                                (
                                  BuildContext context,
                                  AsyncSnapshot<ui.Image> snapshot,
                                ) {
                                  if (snapshot.connectionState == ConnectionState.done) {
                                    if (snapshot.hasError) {
                                      return const Text('Error loading image');
                                    }
                                    return CustomPaint(
                                      size: const Size(300, 300),
                                      painter: QRPainter(
                                        data: viewModel.qrCodeData,
                                        version: 10,
                                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                                        color: Colors.blue,
                                        emptyColor: Colors.white,
                                        gapless: true,
                                        embeddedImageSize: const Size(60, 60),
                                        loadedImage: snapshot.data,
                                      ),
                                    );
                                  } else {
                                    return const CircularProgressIndicator();
                                  }
                                },
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          Formatters.formatAmount(
                            double.parse(widget.paymentRequest.amount) / 100,
                          ),
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Valid for 24 hours',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => viewModel.shareQRCode(_qrKey),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              foregroundColor: Colors.blue,
                              side: const BorderSide(
                                color: Colors.blue,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text('Share Barcode'),
                                SizedBox(width: 8),
                                Icon(Icons.share, color: Colors.blue),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => context.go('/wallet'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Done'),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                )
              : RequestCompleted(paymentRequest: widget.paymentRequest);
        },
      ),
    );
  }
}

class QRPainter extends CustomPainter {
  QRPainter({
    required this.data,
    this.version = 10,
    this.errorCorrectionLevel = QrErrorCorrectLevel.H,
    this.color = Colors.black,
    this.emptyColor = Colors.white,
    this.gapless = false,
    this.embeddedImageSize = const Size(60, 60),
    this.loadedImage,
  });

  final String data;
  final int version;
  final int errorCorrectionLevel;
  final Color color;
  final Color emptyColor;
  final bool gapless;
  final Size embeddedImageSize;
  final ui.Image? loadedImage;

  @override
  void paint(Canvas canvas, Size size) {
    final QrCode qrCode = QrCode(version, errorCorrectionLevel)..addData(data);
    final QrImage qrImage = QrImage(qrCode);

    const double padding = 16;
    final double availableSize = size.width - (padding * 2);
    final double squareSize = availableSize / qrCode.moduleCount;
    final Paint paint = Paint()..style = PaintingStyle.fill;

    paint.color = emptyColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    for (int x = 0; x < qrCode.moduleCount; x++) {
      for (int y = 0; y < qrCode.moduleCount; y++) {
        paint.color = qrImage.isDark(x, y) ? color : emptyColor;
        final Rect rect = Rect.fromLTWH(
          padding + (x * squareSize),
          padding + (y * squareSize),
          squareSize - (gapless ? 0 : 1),
          squareSize - (gapless ? 0 : 1),
        );
        canvas.drawRect(rect, paint);
      }
    }

    if (loadedImage != null) {
      final ui.Paint paint = Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high;

      final ui.Size srcSize = Size(
        loadedImage!.width.toDouble(),
        loadedImage!.height.toDouble(),
      );
      final ui.Rect src = Alignment.center.inscribe(srcSize, Offset.zero & srcSize);
      final Offset center = Offset(size.width / 2, size.height / 2);
      final ui.Rect dst = Rect.fromCenter(
        center: center,
        width: embeddedImageSize.width,
        height: embeddedImageSize.height,
      );
      canvas.drawImageRect(loadedImage!, src, dst, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
