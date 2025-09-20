// lib/services/export_service.dart
// Capture any widget behind a GlobalKey into a PNG file + temp file helpers.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart'
    show GlobalKey, BuildContext, WidgetsBinding;
import 'package:path_provider/path_provider.dart';

class ExportService {
  static Future<File?> captureToPng(
    dynamic key, {
    double pixelRatio = 3.0,
    String filenamePrefix = 'capture',
  }) async {
    if (key is! GlobalKey) return null;

    // Capture the boundary synchronously (no await before using BuildContext).
    final BuildContext? ctx = key.currentContext;
    final RenderRepaintBoundary? boundary =
        ctx?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    // If the boundary still needs paint, wait for end of this frame (no context used here).
    if (boundary.debugNeedsPaint) {
      await WidgetsBinding.instance.endOfFrame;
    }

    // Render to image and encode as PNG
    final ui.Image img = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final bytes = byteData.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final f = File(
      '${dir.path}/$filenamePrefix-${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  static Future<File> writeTempBytes(List<int> bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/$filename');
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }
}
