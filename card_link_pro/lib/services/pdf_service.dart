import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/profile.dart';
import 'qr_service.dart';

/// Professionally formatted, tappable PDF with Inter (primary) + Noto Symbols 2 (emoji fallback).
class PdfService {
  static Future<File> buildProfilePdf({required Profile profile}) async {
    final pdf = pw.Document(
      author: profile.fullName.isNotEmpty ? profile.fullName : 'CardLink Pro',
      creator: 'CardLink Pro',
      title:
          'Digital Card — ${profile.fullName.isNotEmpty ? profile.fullName : "User"}',
      subject: 'Shareable contact & payment details',
      keywords: 'cardlink, profile, contact, pdf, qr',
    );

    final _Fonts fonts = await _loadFonts();

    final String qrData = profile.website.isNotEmpty
        ? _ensureHttp(profile.website)
        : profile.toJson();
    final Uint8List qrBytes = await QrService.generateQrWithAvatar(
      qrData,
      avatarPath: profile.avatarPath,
      size: 1024,
    );
    final pw.ImageProvider qrImage = pw.MemoryImage(qrBytes);

    final pw.BoxDecoration bg = await _resolveBackground(profile);
    final _Palette pal = _computePalette(profile);

    final pw.TextStyle hName = pw.TextStyle(
      font: fonts.bold,
      fontFallback: [fonts.symbols],
      fontSize: 22,
      color: pal.text,
    );
    final pw.TextStyle hRole = pw.TextStyle(
      font: fonts.base,
      fontFallback: [fonts.symbols],
      fontSize: 12.5,
      color: pal.text,
    );
    final pw.TextStyle body = pw.TextStyle(
      font: fonts.base,
      fontFallback: [fonts.symbols],
      fontSize: 12.5,
      color: pal.text,
    );
    final pw.TextStyle linkStyle = pw.TextStyle(
      font: fonts.base,
      fontFallback: [fonts.symbols],
      fontSize: 12.5,
      color: pal.link,
      decoration: pw.TextDecoration.underline,
    );

    pw.Widget? avatar;
    if ((profile.avatarPath ?? '').isNotEmpty) {
      try {
        final Uint8List bytes = profile.avatarPath!.startsWith('assets/')
            ? (await rootBundle.load(profile.avatarPath!)).buffer.asUint8List()
            : await File(profile.avatarPath!).readAsBytes();
        avatar = pw.ClipOval(
          child: pw.Container(
            width: 72,
            height: 72,
            child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.cover),
          ),
        );
      } catch (_) {
        avatar = null;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Stack(
            children: [
              pw.Positioned.fill(child: pw.Container(decoration: bg)),
              pw.Align(
                alignment: pw.Alignment.topCenter,
                child: pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 18),
                  child: pw.Container(
                    width: 520,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (avatar != null) avatar,
                        if (avatar != null) pw.SizedBox(height: 10),
                        pw.Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName
                              : 'Mariatou Koroma',
                          style: hName,
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          profile.role.isNotEmpty
                              ? profile.role
                              : 'Professional Title · HSA',
                          style: hRole,
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 14),
                        _addressCentered(profile, body, linkStyle, pal),
                      ],
                    ),
                  ),
                ),
              ),
              pw.Positioned.fill(
                child: pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Container(
                    width: 520,
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        _emojiLineWithValue(
                          emoji: '☎︎',
                          labelTextExact: 'P Call:',
                          valueText: profile.phone.isNotEmpty
                              ? profile.phone
                              : '07736806367',
                          link: Uri(
                            scheme: 'tel',
                            path: profile.phone.isNotEmpty
                                ? profile.phone
                                : '07736806367',
                          ),
                          body: body,
                          linkStyle: linkStyle,
                          fonts: fonts,
                        ),
                        _emojiLineWithValue(
                          emoji: '📧',
                          labelTextExact: 'E Email:',
                          valueText: profile.email.isNotEmpty
                              ? profile.email
                              : 'ngummariato@gmail.com',
                          link: Uri(
                            scheme: 'mailto',
                            path: profile.email.isNotEmpty
                                ? profile.email
                                : 'ngummariato@gmail.com',
                          ),
                          body: body,
                          linkStyle: linkStyle,
                          fonts: fonts,
                        ),
                        _emojiLineWithValue(
                          emoji: '🌐',
                          labelTextExact: 'W Website:',
                          valueText: _displayHost(profile.website.isNotEmpty
                              ? profile.website
                              : 'google.com'),
                          link: _ensureHttpUri(profile.website.isNotEmpty
                              ? profile.website
                              : 'google.com'),
                          body: body,
                          linkStyle: linkStyle,
                          fonts: fonts,
                        ),
                        _emojiLineWithValue(
                          emoji: '🩺',
                          labelTextExact: 'WB Wellbeing:',
                          valueText: _displayHost(
                            profile.wellbeingLink.isNotEmpty
                                ? profile.wellbeingLink
                                : 'wellbeing.example.com',
                          ),
                          link: _ensureHttpUri(profile.wellbeingLink.isNotEmpty
                              ? profile.wellbeingLink
                              : 'wellbeing.example.com'),
                          body: body,
                          linkStyle: linkStyle,
                          fonts: fonts,
                        ),
                        _emojiLineWithValue(
                          emoji: '💷',
                          labelTextExact: '£ Sort Code:',
                          valueText: profile.bankSortCode.isNotEmpty
                              ? profile.bankSortCode
                              : '09-01-35',
                          link: _payLinkUri(profile),
                          body: body,
                          linkStyle: linkStyle,
                          fonts: fonts,
                        ),
                        _emojiLineWithValue(
                          emoji: '💷',
                          labelTextExact: '£ Account Number:',
                          valueText: profile.bankAccountNumber.isNotEmpty
                              ? profile.bankAccountNumber
                              : '93087283',
                          link: _payLinkUri(profile),
                          body: body,
                          linkStyle: linkStyle,
                          fonts: fonts,
                        ),
                        _emojiActionLine(
                          emoji: '💷',
                          prefixExact:
                              '£ Send Money to ${profile.fullName.isNotEmpty ? profile.fullName.split(' ').first : 'Friend'} ',
                          linkTextExact: 'Click Here',
                          link: _payLinkUri(profile),
                          body: body,
                          linkStyle: linkStyle,
                          fonts: fonts,
                        ),
                        pw.SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
              pw.Positioned(
                right: 24,
                bottom: 24,
                child: pw.Container(
                  width: 120,
                  height: 120,
                  padding: const pw.EdgeInsets.all(8),
                  color: PdfColors.white,
                  child: pw.Image(qrImage, fit: pw.BoxFit.contain),
                ),
              ),
            ],
          );
        },
      ),
    );

    final Directory dir = await getTemporaryDirectory();
    final File file = File(
      '${dir.path}/CardLink-Pro-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _addressCentered(
    Profile p,
    pw.TextStyle body,
    pw.TextStyle linkStyle,
    _Palette pal,
  ) {
    final List<String> lines = _formatAddressLinesExact(p.address);
    final Uri link = _mapsUri(p.address);
    return pw.Container(
      width: 360,
      alignment: pw.Alignment.center,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          for (final String line in lines)
            pw.Text(line, style: body, textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 8),
          pw.Text('Find Address', style: body, textAlign: pw.TextAlign.center),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('Click ', style: body),
              pw.UrlLink(
                destination: link.toString(),
                child: pw.Text('Here', style: linkStyle),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static List<String> _formatAddressLinesExact(String addr) {
    final String raw = addr.replaceAll('\r', ' ').trim();
    final List<String> parts = raw
        .split(RegExp(r'[\n,]+'))
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
    final RegExp regPost = RegExp(r'\b[A-Z]{1,2}\d[A-Z0-9]?\s*\d[A-Z]{2}\b');
    String? postcode;
    for (final String s in parts) {
      final Match? m = regPost.firstMatch(s.toUpperCase());
      if (m != null) {
        postcode = m.group(0);
        break;
      }
    }
    final List<String> cleaned = List<String>.from(parts);
    if (postcode != null) {
      cleaned.removeWhere((String e) => e.toUpperCase().contains(postcode!));
    }
    cleaned.removeWhere((String e) => e.toLowerCase() == 'london');
    cleaned.removeWhere(
        (String e) => e.toLowerCase().startsWith('united kingdom'));
    final String line1 =
        cleaned.isNotEmpty ? '${cleaned[0]},' : 'Flat 72 Priory Court,';
    final String line2 =
        cleaned.length > 1 ? '${cleaned[1]},' : '1 Cheltenham Road,';
    const String line3 = 'London';
    final String line4 =
        (postcode ?? (cleaned.length > 2 ? cleaned[2] : 'SE15 3BG'))
            .toUpperCase();
    const String line5 = 'United Kingdom.';
    return <String>[line1, line2, line3, line4, line5];
  }

  static pw.Widget _emojiLineWithValue({
    required String emoji,
    required String labelTextExact,
    required String valueText,
    required Uri link,
    required pw.TextStyle body,
    required pw.TextStyle linkStyle,
    required _Fonts fonts,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _emojiChip(emoji, fonts),
          pw.SizedBox(width: 10),
          pw.Text(labelTextExact, style: body),
          pw.SizedBox(width: 6),
          pw.UrlLink(
            destination: link.toString(),
            child: pw.Text(valueText, style: linkStyle),
          ),
        ],
      ),
    );
  }

  static pw.Widget _emojiActionLine({
    required String emoji,
    required String prefixExact,
    required String linkTextExact,
    required Uri link,
    required pw.TextStyle body,
    required pw.TextStyle linkStyle,
    required _Fonts fonts,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _emojiChip(emoji, fonts),
          pw.SizedBox(width: 10),
          pw.Text(prefixExact, style: body),
          pw.UrlLink(
            destination: link.toString(),
            child: pw.Text(linkTextExact, style: linkStyle),
          ),
        ],
      ),
    );
  }

  static pw.Widget _emojiChip(String emoji, _Fonts fonts) => pw.Container(
        width: 20,
        height: 20,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: PdfColors.grey400, width: 0.7),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Text(
          emoji,
          style: pw.TextStyle(
            font: fonts.base,
            fontFallback: [fonts.symbols],
            fontSize: 12,
          ),
        ),
      );

  static Uri _payLinkUri(Profile p) {
    if (p.website.isNotEmpty) return _ensureHttpUri(p.website);
    if (p.address.isNotEmpty) return _mapsUri(p.address);
    return Uri.parse('about:blank');
  }

  static String _displayHost(String input) {
    final String t = input.trim();
    try {
      final Uri uri =
          t.startsWith('http') ? Uri.parse(t) : Uri.parse('https://$t');
      return uri.host.isNotEmpty
          ? uri.host.replaceFirst(RegExp(r'^www\.'), '')
          : t;
    } catch (_) {
      return t;
    }
  }

  static Uri _ensureHttpUri(String input) {
    final String t = input.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) {
      return Uri.parse(t);
    }
    return Uri.parse('https://$t');
  }

  static Uri _mapsUri(String address) => Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');

  static String _ensureHttp(String input) {
    final String t = input.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    return 'https://$t';
  }

  static Future<pw.BoxDecoration> _resolveBackground(Profile profile) async {
    if (profile.backgroundPath != null && profile.backgroundPath!.isNotEmpty) {
      try {
        final Uint8List bytes = profile.backgroundPath!.startsWith('assets/')
            ? (await rootBundle.load(profile.backgroundPath!))
                .buffer
                .asUint8List()
            : await File(profile.backgroundPath!).readAsBytes();
        return pw.BoxDecoration(
          image: pw.DecorationImage(
            image: pw.MemoryImage(bytes),
            fit: pw.BoxFit.cover,
          ),
        );
      } catch (_) {
        // fall through to color
      }
    }
    return pw.BoxDecoration(
      color: profile.backgroundColor != null
          ? PdfColor.fromInt(profile.backgroundColor!.toARGB32())
          : PdfColors.grey200,
    );
  }

  static _Palette _computePalette(Profile profile) {
    if (profile.backgroundColor != null) {
      final int argb = profile.backgroundColor!.toARGB32();
      final int r = (argb >> 16) & 0xFF;
      final int g = (argb >> 8) & 0xFF;
      final int b = (argb) & 0xFF;

      double lin(int c) {
        final double v = c / 255.0;
        return v <= 0.03928
            ? v / 12.92
            : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
      }

      final double luma = 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
      final bool darkBg = luma < 0.5;
      return _Palette(
        text: darkBg ? PdfColors.white : PdfColors.black,
        link: darkBg ? PdfColors.cyan : PdfColors.blue,
      );
    }
    return _Palette(text: PdfColors.white, link: PdfColors.cyan);
  }

  static Future<_Fonts> _loadFonts() async {
    pw.Font base;
    pw.Font bold;
    pw.Font symbols;
    try {
      base = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Inter-Regular.ttf'),
      );
    } catch (_) {
      base = pw.Font.helvetica();
    }
    try {
      bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Inter-Bold.ttf'),
      );
    } catch (_) {
      bold = pw.Font.helveticaBold();
    }
    try {
      symbols = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansSymbols2-Regular.ttf'),
      );
    } catch (_) {
      symbols = base;
    }
    return _Fonts(base: base, bold: bold, symbols: symbols);
  }
}

class _Palette {
  final PdfColor text;
  final PdfColor link;
  _Palette({required this.text, required this.link});
}

class _Fonts {
  final pw.Font base;
  final pw.Font bold;
  final pw.Font symbols;
  _Fonts({required this.base, required this.bold, required this.symbols});
}
