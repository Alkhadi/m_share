import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for generating & scanning QR codes.
class QrService {
  /// Generate a high-resolution QR PNG with optional avatar overlay.
  static Future<Uint8List> generateQrWithAvatar(
    String data, {
    String? avatarPath,
    int size = 1024,
  }) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
    );

    final ui.Image qrImage = await painter.toImage(size.toDouble());

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final double dSize = size.toDouble();

    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, dSize, dSize),
      ui.Paint()..color = Colors.white,
    );
    canvas.drawImage(qrImage, ui.Offset.zero, ui.Paint());

    if (avatarPath == null || avatarPath.isEmpty) {
      return _exportCanvasToPng(recorder, size);
    }

    final Uint8List avatarBytes = avatarPath.startsWith('assets/')
        ? (await rootBundle.load(avatarPath)).buffer.asUint8List()
        : await File(avatarPath).readAsBytes();

    final ui.Codec avatarCodec = await ui.instantiateImageCodec(avatarBytes);
    final ui.FrameInfo frame = await avatarCodec.getNextFrame();
    final ui.Image avatarImg = frame.image;

    final double overlaySize = dSize * 0.24;
    final ui.Rect dstRect = ui.Rect.fromLTWH(
      (dSize - overlaySize) / 2,
      (dSize - overlaySize) / 2,
      overlaySize,
      overlaySize,
    );

    final double radius = overlaySize / 2.0;
    final ui.Offset center = ui.Offset(
      dstRect.left + radius,
      dstRect.top + radius,
    );
    canvas.drawCircle(center, radius + 6.0, ui.Paint()..color = Colors.white);

    final ui.Path clip = ui.Path()..addOval(dstRect);
    canvas.save();
    canvas.clipPath(clip);
    final ui.Rect srcRect = ui.Rect.fromLTWH(
      0,
      0,
      avatarImg.width.toDouble(),
      avatarImg.height.toDouble(),
    );
    canvas.drawImageRect(avatarImg, srcRect, dstRect, ui.Paint());
    canvas.restore();

    return _exportCanvasToPng(recorder, size);
  }

  static Future<Uint8List> _exportCanvasToPng(
    ui.PictureRecorder recorder,
    int size,
  ) async {
    final ui.Picture picture = recorder.endRecording();
    final ui.Image out = await picture.toImage(size, size);
    final ByteData? byteData = await out.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }
}

/// A simple full-screen QR scanner that returns the scanned text via [onDetected].
/// If [autoOpenUrl] is true and the payload looks like a URL, it will be launched.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key, this.onDetected, this.autoOpenUrl = true});
  final ValueChanged<String>? onDetected;
  final bool autoOpenUrl;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _looksLikeUrl(String s) {
    final t = s.trim();
    return t.startsWith('http://') || t.startsWith('https://');
  }

  Future<void> _maybeOpen(String value) async {
    if (!widget.autoOpenUrl) return;
    if (_looksLikeUrl(value)) {
      final uri = Uri.tryParse(value);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) async {
          if (_handled) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;
          final String? raw = barcodes.first.rawValue;
          if (raw == null || raw.isEmpty) return;

          _handled = true;
          widget.onDetected?.call(raw);
          await _maybeOpen(raw);
          if (mounted) Navigator.of(context).pop(raw);
        },
      ),
    );
  }
}
