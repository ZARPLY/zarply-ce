import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:qr/qr.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/formatters.dart';
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
  Future<ui.Image>? _loadImageFuture;

  @override
  void initState() {
    super.initState();
    _loadImageFuture = _loadImage();
  }

  Future<ui.Image> _loadImage() async {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    const AssetImage imageProvider = AssetImage('images/qr-code-logo.png');
    final ImageStream stream =
        imageProvider.resolve(const ImageConfiguration());
    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo info, bool _) => completer.complete(info.image),
      onError: (Object error, _) => completer.completeError(error),
    );

    stream.addListener(listener);
    return completer.future;
  }

  Future<void> _shareQRCode() async {
    final ShareResult result =
        await Share.share('Payment request for R${widget.amount}');

    if (result.status == ShareResultStatus.success) {
      setState(() {
        isQRCodeShared = true;
      });
    }
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
                FutureBuilder<ui.Image>(
                  future: _loadImageFuture,
                  builder:
                      (BuildContext context, AsyncSnapshot<ui.Image> snapshot) {
                    return CustomPaint(
                      size: const Size(300, 300),
                      painter: QRPainter(
                        data: 'zarply:payment:${widget.amount}',
                        version: 4,
                        color: Colors.blue,
                        emptyColor: Colors.white,
                        gapless: true,
                        embeddedImageSize: const Size(60, 60),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  Formatters.formatAmount(double.parse(widget.amount)),
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

class QRPainter extends CustomPainter {
  QRPainter({
    required this.data,
    this.version = 1,
    this.errorCorrectionLevel = QrErrorCorrectLevel.L,
    this.color = Colors.black,
    this.emptyColor = Colors.white,
    this.gapless = false,
    this.embeddedImageSize = const Size(40, 40),
  }) {
    _loadImage();
  }

  final String data;
  final int version;
  final int errorCorrectionLevel;
  final Color color;
  final Color emptyColor;
  final bool gapless;
  final Size embeddedImageSize;
  ui.Image? _loadedImage;

  void _loadImage() {
    const AssetImage imageProvider = AssetImage('images/qr-code-logo.png');
    final ImageStream stream =
        imageProvider.resolve(const ImageConfiguration());
    stream.addListener(
      ImageStreamListener((ImageInfo info, _) {
        _loadedImage = info.image;
      }),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final QrCode qrCode = QrCode(version, errorCorrectionLevel)..addData(data);
    final QrImage qrImage = QrImage(qrCode);

    final double squareSize = size.width / qrCode.moduleCount;
    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (int x = 0; x < qrCode.moduleCount; x++) {
      for (int y = 0; y < qrCode.moduleCount; y++) {
        paint.color = qrImage.isDark(x, y) ? color : emptyColor;
        final Rect rect = Rect.fromLTWH(
          x * squareSize,
          y * squareSize,
          squareSize - (gapless ? 0 : 1),
          squareSize - (gapless ? 0 : 1),
        );
        canvas.drawRect(rect, paint);
      }
    }

    if (_loadedImage != null) {
      final ui.Paint paint = Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high;

      final ui.Size srcSize = Size(
        _loadedImage!.width.toDouble(),
        _loadedImage!.height.toDouble(),
      );
      final ui.Rect src =
          Alignment.center.inscribe(srcSize, Offset.zero & srcSize);
      final Offset center = Offset(size.width / 2, size.height / 2);
      final ui.Rect dst = Rect.fromCenter(
        center: center,
        width: embeddedImageSize.width,
        height: embeddedImageSize.height,
      );
      canvas.drawImageRect(_loadedImage!, src, dst, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
