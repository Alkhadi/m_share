import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/profile.dart';
import 'pdf_service.dart';
import 'qr_service.dart';

/// Unified sharing helper for text, PDF+QR, QR image and email.
class ShareService {
  ShareService({required this.profile});
  final Profile profile;

  Future<void> sharePdfWithQr(BuildContext context) async {
    final pdf = await PdfService.buildProfilePdf(profile: profile);
    await Share.shareXFiles([XFile(pdf.path)], text: 'My digital card');
  }

  Future<void> shareQrImage(BuildContext context) async {
    final String data = _primaryShareUrl(profile) ?? profile.website;
    final Uint8List png = await QrService.generateQrWithAvatar(
      data,
      avatarPath: profile.avatarPath,
      size: 800,
    );
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/cardlink-qr-${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(png);
    await Share.shareXFiles([XFile(file.path)], text: 'Scan my QR');
  }

  Future<void> shareAsText(BuildContext context) async {
    await ShareService.shareText(profile, subject: 'My CardLink Pro profile');
  }

  Future<void> shareViaEmail(BuildContext context) async {
    final pdf = await PdfService.buildProfilePdf(profile: profile);
    final body = ShareService.renderShareText(profile);
    await Share.shareXFiles(
      [XFile(pdf.path)],
      subject: 'My Digital Business Card',
      text: body,
    );
  }

  Future<void> shareImageBytes(Uint8List pngBytes,
      {String suggestedName = 'profile_image.png'}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$suggestedName');
    await file.writeAsBytes(pngBytes);
    await Share.shareXFiles([XFile(file.path)]);
  }

  // -------- Static API (legacy) --------

  static String renderShareText(Profile p) {
    final mapUrl =
        'https://maps.google.com/?q=${Uri.encodeComponent(p.address)}';
    final socials = <String>[
      if (p.linkedin?.isNotEmpty == true)
        'LinkedIn: ${_ensureHttp(p.linkedin!)}',
      if (p.instagram?.isNotEmpty == true)
        'Instagram: ${_ensureHttp(p.instagram!)}',
      if (p.facebook?.isNotEmpty == true)
        'Facebook: ${_ensureHttp(p.facebook!)}',
      if (p.xHandle?.isNotEmpty == true)
        'X (Twitter): ${_ensureHttp(p.xHandle!)}',
      if (p.tiktok?.isNotEmpty == true) 'TikTok: ${_ensureHttp(p.tiktok!)}',
      if (p.youtube?.isNotEmpty == true) 'YouTube: ${_ensureHttp(p.youtube!)}',
      if (p.snapchat?.isNotEmpty == true)
        'Snapchat: ${_ensureHttp(p.snapchat!)}',
    ];
    final wellbeing = p.wellbeingLink.isNotEmpty
        ? '\nWellbeing: ${_ensureHttp(p.wellbeingLink)}'
        : '';

    return [
      '${p.fullName}\n${p.role}',
      '📍 ${p.address}\nMap: $mapUrl',
      '📞 Tel: ${p.phone}',
      '✉️  Email: ${p.email}',
      '🌐 Website: ${_ensureHttp(p.website)}$wellbeing',
      if (socials.isNotEmpty) 'Social:\n${socials.join('\n')}',
      '—',
      'Bank Details',
      'Sort code: ${p.bankSortCode}',
      'Account number: ${p.bankAccountNumber}',
    ].join('\n');
  }

  static Future<void> shareText(Profile p, {String? subject}) async {
    await Share.share(renderShareText(p), subject: subject);
  }

  static Future<void> sharePdfAndImage({
    required Uint8List pdfBytes,
    Uint8List? pngBytes,
    String pdfName = 'cardlink.pdf',
    String? pngName,
    String? text,
  }) async {
    final tmp = await getTemporaryDirectory();
    final pdfFile = File('${tmp.path}/$pdfName')..writeAsBytesSync(pdfBytes);

    final files = <XFile>[XFile(pdfFile.path)];
    if (pngBytes != null) {
      final name = pngName ?? 'cardlink-qr.png';
      final pngFile = File('${tmp.path}/$name')..writeAsBytesSync(pngBytes);
      files.add(XFile(pngFile.path));
    }

    await Share.shareXFiles(files, text: text ?? 'My digital card');
  }

  static Future<void> shareImage(Uint8List pngBytes,
      {String suggestedName = 'image.png'}) async {
    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}/$suggestedName')..writeAsBytesSync(pngBytes);
    await Share.shareXFiles([XFile(file.path)]);
  }

  static Future<XFile> xfileFromBytes(
      Uint8List bytes, String name, String mime) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return XFile(file.path, mimeType: mime);
  }

  static Future<void> shareEmailWithAttachments({
    required String subject,
    required String body,
    required List<XFile> files,
  }) async {
    await Share.shareXFiles(files, subject: subject, text: body);
  }

  // Internals
  static String _ensureHttp(String input) {
    final t = input.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    return 'https://$t';
  }

  String? _primaryShareUrl(Profile p) {
    if (p.website.isNotEmpty) return _ensureHttp(p.website);
    if (p.linkedin?.isNotEmpty == true) return _ensureHttp(p.linkedin!);
    return null;
  }
}
