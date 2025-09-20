import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/profile.dart';
import '../services/pdf_service.dart';
import '../services/share_service.dart';
import 'pay_dialog.dart';

/// Legacy-styled share bottom sheet updated to call ShareService APIs.
class ShareSheet extends StatelessWidget {
  final Profile profile;
  final GlobalKey captureKey; // retained for backwards compatibility; unused

  const ShareSheet({
    super.key,
    required this.profile,
    required this.captureKey,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, controller) {
        return SingleChildScrollView(
          controller: controller,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.text_snippet_outlined),
                  title: const Text('Share My Profile as Text'),
                  onTap: () async {
                    Navigator.pop(context);
                    await ShareService.shareText(profile,
                        subject: 'My CardLink Pro profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf),
                  title: const Text('Share PDF + QR'),
                  onTap: () async {
                    Navigator.pop(context);
                    final pdfFile =
                        await PdfService.buildProfilePdf(profile: profile);
                    final pdfBytes = await pdfFile.readAsBytes();
                    await ShareService.sharePdfAndImage(pdfBytes: pdfBytes);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code_2),
                  title: const Text('Share QR Code'),
                  onTap: () async {
                    Navigator.pop(context);
                    final url = profile.website.isNotEmpty
                        ? profile.website
                        : 'https://example.com';
                    final png = await _qrPngBytes(url);
                    if (png != null) {
                      final ts =
                          DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
                      await ShareService.shareImage(png,
                          suggestedName: 'cardlink-qr-$ts.png');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email My Profile'),
                  onTap: () async {
                    Navigator.pop(context);
                    final pdfFile =
                        await PdfService.buildProfilePdf(profile: profile);
                    final pdfBytes = await pdfFile.readAsBytes();
                    final xfile = await ShareService.xfileFromBytes(
                        pdfBytes, 'cardlink.pdf', 'application/pdf');
                    await ShareService.shareEmailWithAttachments(
                      subject: 'My CardLink Pro Profile',
                      body: ShareService.renderShareText(profile),
                      files: [xfile],
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Send/Receive Money (Bank)'),
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (_) => PayDialog(profile: profile));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List?> _qrPngBytes(String data) async {
    try {
      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        gapless: true,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );
      final image = await painter.toImage(900);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
