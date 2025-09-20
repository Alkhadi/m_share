import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:qr_flutter/qr_flutter.dart';

/// QR generator used by PdfService and ShareService.
/// Produces a PNG byte array of the QR code; optionally composites a circular
/// avatar in the center with a thin white halo for contrast.
class QrService {
  /// Generate a high-resolution QR image (PNG bytes) for [data].
  ///
  /// If [avatarPath] is provided (assets or file path), it is composited
  /// as a circular image at the center of the QR with a white halo.
  /// [size] is the output square dimension in pixels.
  static Future<Uint8List> generateQrWithAvatar(
    String data, {
    String? avatarPath,
    int size = 1024,
  }) async {
    // Paint the QR (module/eye colors via styles; no deprecated fields).
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

    // Render QR to an image (expects a double).
    final ui.Image qrImage = await painter.toImage(size.toDouble());

    // Compose onto a new canvas with a white background to avoid transparent PNGs.
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(recorder);
    final double dSize = size.toDouble();

    // White background
    final ui.Paint bgPaint = ui.Paint()..color = Colors.white;
    canvas.drawRect(ui.Rect.fromLTWH(0.0, 0.0, dSize, dSize), bgPaint);

    // Draw the QR on top
    canvas.drawImage(qrImage, ui.Offset.zero, ui.Paint());

    // If no avatar requested, export now.
    if (avatarPath == null || avatarPath.isEmpty) {
      final ui.Picture picture = recorder.endRecording();
      final ui.Image out = await picture.toImage(size, size);
      final byteData = await out.toByteData(format: ui.ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    }

    // Load avatar (assets/ or file) and overlay it centered.
    Uint8List avatarBytes;
    if (avatarPath.startsWith('assets/')) {
      avatarBytes = (await rootBundle.load(avatarPath)).buffer.asUint8List();
    } else {
      avatarBytes = await File(avatarPath).readAsBytes();
    }

    final ui.Codec avatarCodec = await ui.instantiateImageCodec(avatarBytes);
    final ui.FrameInfo frame = await avatarCodec.getNextFrame();
    final ui.Image avatarImg = frame.image;

    // Destination rect (~24% of QR width)
    final double overlaySize = dSize * 0.24;
    final ui.Rect dstRect = ui.Rect.fromLTWH(
      (dSize - overlaySize) / 2.0,
      (dSize - overlaySize) / 2.0,
      overlaySize,
      overlaySize,
    );

    // White halo
    final double radius = overlaySize / 2.0;
    final ui.Offset center =
        ui.Offset(dstRect.left + radius, dstRect.top + radius);
    canvas.drawCircle(center, radius + 6.0, ui.Paint()..color = Colors.white);

    // Clip to circle and draw avatar
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

    // Export PNG
    final ui.Picture picture = recorder.endRecording();
    final ui.Image out = await picture.toImage(size, size);
    final byteData = await out.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
