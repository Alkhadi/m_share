import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:qr_flutter/qr_flutter.dart';

/// Service for generating QR codes with optional avatar overlay.
/// Used by PdfService and ShareService.
class QrService {
  /// Generate a high-resolution QR code image as PNG bytes.
  ///
  /// [data] → the string encoded in the QR.
  /// [avatarPath] → optional asset or file path for a center avatar.
  /// [size] → square output dimension in pixels (default 1024).
  ///
  /// The output PNG always has a solid white background
  /// to avoid transparency issues in PDF/printing.
  static Future<Uint8List> generateQrWithAvatar(
    String data, {
    String? avatarPath,
    int size = 1024,
  }) async {
    // Render QR code using qr_flutter styles
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

    // Convert to image (needs a double for size)
    final ui.Image qrImage = await painter.toImage(size.toDouble());

    // Create canvas with a white background
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final double dSize = size.toDouble();

    // Fill background white
    canvas.drawRect(
      ui.Rect.fromLTWH(0.0, 0.0, dSize, dSize),
      ui.Paint()..color = Colors.white,
    );

    // Draw QR onto canvas
    canvas.drawImage(qrImage, ui.Offset.zero, ui.Paint());

    // If no avatar, export immediately
    if (avatarPath == null || avatarPath.isEmpty) {
      return _exportCanvasToPng(recorder, size);
    }

    // Load avatar bytes from asset or file
    final Uint8List avatarBytes = avatarPath.startsWith('assets/')
        ? (await rootBundle.load(avatarPath)).buffer.asUint8List()
        : await File(avatarPath).readAsBytes();

    // Decode avatar image
    final ui.Codec avatarCodec = await ui.instantiateImageCodec(avatarBytes);
    final ui.FrameInfo frame = await avatarCodec.getNextFrame();
    final ui.Image avatarImg = frame.image;

    // Calculate overlay rect (24% of QR size)
    final double overlaySize = dSize * 0.24;
    final ui.Rect dstRect = ui.Rect.fromLTWH(
      (dSize - overlaySize) / 2,
      (dSize - overlaySize) / 2,
      overlaySize,
      overlaySize,
    );

    // Draw white halo around avatar
    final double radius = overlaySize / 2.0;
    final ui.Offset center = ui.Offset(
      dstRect.left + radius,
      dstRect.top + radius,
    );
    canvas.drawCircle(center, radius + 6.0, ui.Paint()..color = Colors.white);

    // Clip to circle and draw avatar inside
    final ui.Path clip = ui.Path()..addOval(dstRect);
    canvas.save();
    canvas.clipPath(clip);

    final ui.Rect srcRect = ui.Rect.fromLTWH(
      0.0,
      0.0,
      avatarImg.width.toDouble(),
      avatarImg.height.toDouble(),
    );
    canvas.drawImageRect(avatarImg, srcRect, dstRect, ui.Paint());
    canvas.restore();

    // Export final PNG bytes
    return _exportCanvasToPng(recorder, size);
  }

  /// Helper to export canvas to PNG bytes.
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
