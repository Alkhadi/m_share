// lib/services/share_service.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/urls.dart';
import '../config/utils.dart';
import '../models/profile.dart';
import '../models/profile_ext.dart'; // bankName/iban/reference/canonicalId
import 'pdf_service.dart';
import 'qr_service.dart';
import 'short_url_service.dart';
import 'upload_service.dart';

/// Central share routines: PDF, QR image, Text, Email, Web upload.
class ShareService {
  ShareService({required this.profile});
  final Profile profile;

  String _qp() => buildQuery(
    name: profile.fullName,
    phone: profile.phone,
    email: profile.email,
    site: profile.website,
    addr: profile.address,
    acc: profile.bankAccountNumber,
    sort: profile.bankSortCode,
    ref: 'M SHARE',
    x: profile.xHandle,
    ig: profile.instagram,
    yt: profile.youtube,
    ln: profile.linkedin,
  );

  /// Upload profile to Worker (PDF + metadata).
  Future<Uri?> shareToWeb(BuildContext context) async {
    try {
      final pdfFile = await PdfService.buildProfilePdf(profile: profile);
      final pdfBytes = await pdfFile.readAsBytes();

      final metadata = {
        "name": profile.fullName,
        "title": profile.role,
        "email": profile.email,
        "phone": profile.phone,
        "site": profile.website,
        "addr": profile.address,
        "payee_full_name": profile.fullName,
        "bank_name": profile.bankName, // from extension ('' if absent)
        "account_number": profile.bankAccountNumber,
        "sort_code": profile.bankSortCode,
        "iban": profile.iban, // from extension ('' if absent)
        "reference": profile.reference, // from extension ('M SHARE' default)
      };

      final url = await uploadProfileToWeb(
        pdfBytes: pdfBytes,
        metadata: metadata,
        // uploadKey: "YOUR_SECRET" // if REQUIRE_UPLOAD_KEY=true
      );

      if (url != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Uploaded! $url')));
      }
      return url;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload error: $e')));
      }
      return null;
    }
  }

  Future<void> sharePdfWithQr(BuildContext context) async {
    final file = await PdfService.buildProfilePdf(profile: profile);
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'My M Share digital card');
  }

  Future<void> shareQrImage(BuildContext context) async {
    final String qp = _qp();
    final String data = WebLinks.pdf(qp);
    final Uint8List png = await QrService.generateQrWithAvatar(
      data,
      avatarPath: profile.avatarPath,
      size: 800,
    );
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/mshare-qr-${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(png);
    await Share.shareXFiles([XFile(file.path)], text: 'Scan my M Share QR');
  }

  Future<void> shareAsText(BuildContext context) async {
    await ShareService.shareText(profile, subject: 'My M Share digital card');
  }

  Future<void> shareViaEmail(BuildContext context) async {
    final pdfFile = await PdfService.buildProfilePdf(profile: profile);
    final body = renderShareText(profile);
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      subject: 'My M Share Digital Card',
      text: body,
    );
  }

  Future<void> shareImageBytes(
    Uint8List pngBytes, {
    String suggestedName = 'image.png',
  }) async {
    await ShareService.shareImage(pngBytes, suggestedName: suggestedName);
  }

  // ------------------------ static helpers ------------------------

  static String renderShareText(Profile p) {
    final String mapQuery = _extractPostcode(p.address).isNotEmpty
        ? _extractPostcode(p.address)
        : p.address;
    final String mapUrl = mapQuery.isNotEmpty
        ? 'https://maps.google.com/?q=${Uri.encodeComponent(mapQuery)}'
        : '';

    final String name = p.fullName.isNotEmpty ? p.fullName : 'Your Name';
    final String role = p.role.isNotEmpty ? p.role : 'Professional Title';
    final String phone = p.phone.isNotEmpty ? p.phone : '';
    final String email = p.email.isNotEmpty ? p.email : '';
    final String website = p.website.isNotEmpty ? _ensureHttp(p.website) : '';
    final String wellbeing = p.wellbeingLink.isNotEmpty
        ? _ensureHttp(p.wellbeingLink)
        : '';
    final String sortCode = p.bankSortCode.isNotEmpty ? p.bankSortCode : '';
    final String accountNumber = p.bankAccountNumber.isNotEmpty
        ? p.bankAccountNumber
        : '';

    final qp = buildQuery(
      name: name,
      phone: phone,
      email: email,
      site: website,
      addr: p.address,
      acc: accountNumber,
      sort: sortCode,
      ref: 'M SHARE',
      x: p.xHandle,
      ig: p.instagram,
      yt: p.youtube,
      ln: p.linkedin,
    );

    final lines = <String>[
      '$name\n$role',
      ...p.address
          .split(RegExp(r'[\n,]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty),
      if (mapUrl.isNotEmpty) '🏠 Find Address: Click Here: $mapUrl',
      if (phone.isNotEmpty) '📞 Call: $phone',
      if (email.isNotEmpty) '📧 Email: $email',
      if (website.isNotEmpty) '🌐 Website: $website',
      if (wellbeing.isNotEmpty) '🩺 Wellbeing: $wellbeing',
      '—',
      'Bank Details',
      if (sortCode.isNotEmpty) '🏦 Sort Code: $sortCode',
      if (accountNumber.isNotEmpty) '🏦 Account Number: $accountNumber',
      '—',
      'Open my pages:',
      '• Profile: ${WebLinks.home(qp)}',
      '• Bank: ${WebLinks.bank(qp)}',
      '• Wellbeing: ${WebLinks.wellbeing(qp)}',
      '• PDF: ${WebLinks.pdf(qp)}',
    ];

    return lines.join('\n');
  }

  static Future<void> shareText(Profile p, {String? subject}) async {
    final qp = buildQuery(
      name: p.fullName,
      phone: p.phone,
      email: p.email,
      site: p.website,
      addr: p.address,
      acc: p.bankAccountNumber,
      sort: p.bankSortCode,
      ref: 'M SHARE',
      x: p.xHandle,
      ig: p.instagram,
      yt: p.youtube,
      ln: p.linkedin,
    );

    final fullProfile = WebLinks.home(qp);
    final fullBank = WebLinks.bank(qp);
    final fullWellbeing = WebLinks.wellbeing(qp);
    final fullPdf = WebLinks.pdf(qp);

    final shortProfile = await ShortUrlService.shorten(fullProfile);
    final shortBank = await ShortUrlService.shorten(fullBank);
    final shortWellbeing = await ShortUrlService.shorten(fullWellbeing);
    final shortPdf = await ShortUrlService.shorten(fullPdf);

    final lines = <String>[
      '${p.fullName}\n${p.role}',
      p.address,
      if (p.phone.isNotEmpty) '📞 Call: ${p.phone}',
      if (p.email.isNotEmpty) '📧 Email: ${p.email}',
      if (p.website.isNotEmpty) '🌐 Website: ${p.website}',
      if (p.wellbeingLink.isNotEmpty) '🩺 Wellbeing: ${p.wellbeingLink}',
      '—',
      'Bank Details',
      if (p.bankSortCode.isNotEmpty) '🏦 Sort Code: ${p.bankSortCode}',
      if (p.bankAccountNumber.isNotEmpty)
        '🏦 Account Number: ${p.bankAccountNumber}',
      '—',
      'Open my pages:',
      '• Profile: $shortProfile',
      '• Bank: $shortBank',
      '• Wellbeing: $shortWellbeing',
      '• PDF: $shortPdf',
    ];

    await Share.share(
      lines.join('\n'),
      subject: subject ?? 'My M Share profile',
    );
  }

  static Future<void> sharePdfAndImage({
    required Uint8List pdfBytes,
    Uint8List? pngBytes,
    String pdfName = 'mshare.pdf',
    String? pngName,
    String? text,
  }) async {
    final tmp = await getTemporaryDirectory();
    final pdfFile = File('${tmp.path}/$pdfName')..writeAsBytesSync(pdfBytes);
    final files = <XFile>[XFile(pdfFile.path)];
    if (pngBytes != null) {
      final name = pngName ?? 'mshare-qr.png';
      final pngFile = File('${tmp.path}/$name')..writeAsBytesSync(pngBytes);
      files.add(XFile(pngFile.path));
    }
    await Share.shareXFiles(files, text: text ?? 'My M Share digital card');
  }

  static Future<void> shareImage(
    Uint8List pngBytes, {
    String suggestedName = 'image.png',
  }) async {
    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}/$suggestedName')..writeAsBytesSync(pngBytes);
    await Share.shareXFiles([XFile(file.path)]);
  }

  static Future<XFile> xfileFromBytes(
    Uint8List bytes,
    String name,
    String mime,
  ) async {
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

  static String _ensureHttp(String input) {
    final t = input.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    return 'https://$t';
  }

  static String _extractPostcode(String address) {
    final RegExp regPost = RegExp(r'\b[A-Z]{1,2}\d[A-Z0-9]?\s*\d[A-Z]{2}\b');
    final Match? m = regPost.firstMatch(address.toUpperCase());
    if (m != null) return (m.group(0) ?? '').trim();
    return '';
  }

  static Future<void> copyBankDetails(Profile p) async {
    final String sortCode = p.bankSortCode.isNotEmpty
        ? p.bankSortCode
        : '09-01-35';
    final String accountNumber = p.bankAccountNumber.isNotEmpty
        ? p.bankAccountNumber
        : '93087283';
    final String fullDetails =
        'Sort Code: $sortCode\nAccount Number: $accountNumber';
    await Clipboard.setData(ClipboardData(text: fullDetails));
  }
}
