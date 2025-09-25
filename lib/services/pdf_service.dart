// lib/services/pdf_service.dart
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/profile.dart';
import '../models/profile_ext.dart'; // adds bankName/iban/reference/canonicalId

class PdfService {
  /// Builds a one‑page PDF with tappable links.
  ///
  /// Note: bankName/iban/reference are provided by the ProfileX extension
  /// with safe defaults so your project compiles even if your Profile class
  /// doesn’t yet include those fields.
  static Future<File> buildProfilePdf({required Profile profile}) async {
    final pdf = pw.Document();

    final pw.ImageProvider? avatarProvider =
        (profile.avatarPath != null &&
            profile.avatarPath!.isNotEmpty &&
            profile.avatarPath!.startsWith('assets/'))
        ? pw.MemoryImage(
            (await rootBundle.load(profile.avatarPath!)).buffer.asUint8List(),
          )
        : null;

    final canonical = 'https://mindpaylink.com/p/${profile.canonicalId}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (avatarProvider != null)
              pw.Center(
                child: pw.ClipOval(
                  child: pw.Image(
                    avatarProvider,
                    width: 80,
                    height: 80,
                    fit: pw.BoxFit.cover,
                  ),
                ),
              ),
            pw.SizedBox(height: 12),
            pw.Text(
              profile.fullName,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            if (profile.role.isNotEmpty)
              pw.Text(profile.role, style: const pw.TextStyle(fontSize: 16)),
            pw.SizedBox(height: 12),

            // Contact (wrap each with UrlLink instead of using a non‑existent 'link:' param)
            pw.UrlLink(
              destination: 'tel:${profile.phone}',
              child: pw.Text(
                '📞 ${profile.phone}',
                style: const pw.TextStyle(fontSize: 14),
              ),
            ),
            pw.UrlLink(
              destination: 'mailto:${profile.email}',
              child: pw.Text(
                '📧 ${profile.email}',
                style: const pw.TextStyle(fontSize: 14),
              ),
            ),
            pw.UrlLink(
              destination: profile.website,
              child: pw.Text(
                '🌐 ${profile.website}',
                style: const pw.TextStyle(fontSize: 14),
              ),
            ),
            pw.UrlLink(
              destination:
                  'https://maps.google.com/?q=${Uri.encodeComponent(profile.address)}',
              child: pw.Text(
                '🏠 ${profile.address}',
                style: const pw.TextStyle(fontSize: 14),
              ),
            ),

            pw.SizedBox(height: 12),

            // Bank
            if (profile.bankName.isNotEmpty)
              pw.Text('🏦 Bank: ${profile.bankName}'),
            pw.Text('Sort Code: ${profile.bankSortCode}'),
            pw.Text('Account Number: ${profile.bankAccountNumber}'),
            if (profile.iban.isNotEmpty) pw.Text('IBAN: ${profile.iban}'),
            pw.Text('Reference: ${profile.reference}'),

            pw.SizedBox(height: 20),

            // Canonical URL
            pw.Text(
              'Profile online:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.UrlLink(
              destination: canonical,
              child: pw.Text(
                canonical,
                style: pw.TextStyle(color: PdfColors.blue),
              ),
            ),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/m_share_profile.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
