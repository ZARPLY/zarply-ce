import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

class RequestQRCodeViewModel extends ChangeNotifier {
  RequestQRCodeViewModel({required this.amount, required this.walletAddress});

  final String amount;
  final String walletAddress;
  bool isQRCodeShared = false;
  Future<ui.Image>? _loadImageFuture;

  Future<ui.Image>? get loadImageFuture => _loadImageFuture;

  void init() {
    _loadImageFuture = _loadImage();
  }

  Future<ui.Image> _loadImage() async {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    const AssetImage imageProvider = AssetImage('images/qr-code-logo.png');
    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
    final ImageStreamListener listener = ImageStreamListener(
      (ImageInfo info, bool _) => completer.complete(info.image),
      onError: (Object error, _) => completer.completeError(error),
    );

    stream.addListener(listener);
    return completer.future;
  }

  String get qrCodeData =>
      'zarply:payment:$amount:$walletAddress:${DateTime.now().millisecondsSinceEpoch}';

  Future<void> shareQRCode(GlobalKey qrKey) async {
    final RenderRepaintBoundary boundary =
        qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage();
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();

    final ShareResult result = await Share.shareXFiles(
      <XFile>[
        XFile.fromData(pngBytes, mimeType: 'image/png', name: 'qr_code.png'),
      ],
      subject: 'ZARPLY Payment Request',
    );

    if (result.status == ShareResultStatus.success) {
      isQRCodeShared = true;
      notifyListeners();
    }
  }
}
