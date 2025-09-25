import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/profile.dart';
import '../services/pdf_service.dart';
import '../services/share_service.dart';

/// A sheet for sharing a profile via PDF+QR, QR image, text or email.
class QrShareSheet extends StatelessWidget {
  final Profile profile;
  const QrShareSheet({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final tileDecoration = BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Wrap(
          runSpacing: 16,
          alignment: WrapAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionTile(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Share PDF + QR',
                  decoration: tileDecoration,
                  onTap: () async {
                    final pdf = await PdfService.buildProfilePdf(
                      profile: profile,
                    );
                    final bytes = await pdf.readAsBytes();
                    await ShareService.sharePdfAndImage(pdfBytes: bytes);
                  },
                ),
                const SizedBox(width: 16),
                _ActionTile(
                  icon: Icons.qr_code_rounded,
                  label: 'Share QR Image',
                  decoration: tileDecoration,
                  onTap: () async {
                    // fallback to default if no website
                    final url = profile.website.isNotEmpty
                        ? profile.website
                        : 'https://example.com';
                    final png = await _qrPngBytes(url);
                    if (png != null) {
                      await ShareService.shareImage(
                        png,
                        suggestedName: 'mshare-qr.png',
                      );
                    }
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionTile(
                  icon: Icons.text_snippet_rounded,
                  label: 'Share My Profile as Text',
                  decoration: tileDecoration,
                  onTap: () async {
                    await ShareService.shareText(
                      profile,
                      subject: 'My M Share profile',
                    );
                  },
                ),
                const SizedBox(width: 16),
                _ActionTile(
                  icon: Icons.email_rounded,
                  label: 'Email My M Share Profile',
                  decoration: tileDecoration,
                  onTap: () async {
                    final pdf = await PdfService.buildProfilePdf(
                      profile: profile,
                    );
                    final xfile = await ShareService.xfileFromBytes(
                      await pdf.readAsBytes(),
                      'mshare-profile.pdf',
                      'application/pdf',
                    );
                    await ShareService.shareEmailWithAttachments(
                      subject: 'My M Share Profile',
                      body: ShareService.renderShareText(profile),
                      files: [xfile],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Future<void> Function() onTap;
  final Decoration decoration;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () async => await onTap(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120,
          decoration: decoration,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
