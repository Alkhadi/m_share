import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/profile.dart';
import 'qr_service.dart';

/// Service for building a polished, shareable PDF profile.
///
/// This implementation renders a profile card styled to match the
/// application's UI. It includes an avatar, user details, a QR code,
/// clickable contact links and bank details, and plenty of spacing
/// to ensure information is never cramped or overlapping.
///
/// Rather than relying on emoji, this version loads custom icons
/// from asset images (PNG files exported from the app's UI icon set).
/// Each icon is drawn inside a small square with a white background
/// and grey border so it stands out regardless of page background.
class PdfService {
  /// Build a PDF containing the given [profile].
  static Future<File> buildProfilePdf({required Profile profile}) async {
    final pdf = pw.Document(
      author: profile.fullName.isNotEmpty ? profile.fullName : 'M Share',
      creator: 'M Share',
      title:
          'Digital Card — ${profile.fullName.isNotEmpty ? profile.fullName : "User"}',
      subject: 'Shareable contact & payment details',
      keywords: 'mshare, profile, contact, pdf, qr',
    );

    // Load fonts. The base font is used for most text, bold for headings,
    // and a symbols font to ensure emoji render correctly.
    final _Fonts fonts = await _loadFonts();

    // Generate a QR code containing either the user's website or a
    // serialized JSON representation of the profile. The avatar is
    // composited into the QR for a personalised touch.
    final String qrData = profile.website.isNotEmpty
        ? _ensureHttp(profile.website)
        : profile.toJson();
    final Uint8List qrBytes = await QrService.generateQrWithAvatar(
      qrData,
      avatarPath: profile.avatarPath,
      size: 1024,
    );
    final pw.ImageProvider qrImage = pw.MemoryImage(qrBytes);

    // Load UI/UX icons from assets. These PNG files should be
    // included in your Flutter project's assets and declared in
    // pubspec.yaml (e.g. under assets/icons/pdf/). The icons are
    // loaded here via the rootBundle so they can be embedded in the PDF.
    // Declare icon variables. These are nullable so that if loading fails
    // they remain null and fallback behaviour can be applied.
    pw.ImageProvider? phoneIcon;
    pw.ImageProvider? emailIcon;
    pw.ImageProvider? websiteIcon;
    pw.ImageProvider? addressIcon;
    pw.ImageProvider? wellbeingIcon;
    pw.ImageProvider? bankIcon;
    try {
      final Uint8List phoneBytes = (await rootBundle.load(
        'assets/icons/pdf/phone.png',
      )).buffer.asUint8List();
      phoneIcon = pw.MemoryImage(phoneBytes);
    } catch (_) {
      phoneIcon = null;
    }
    try {
      final Uint8List emailBytes = (await rootBundle.load(
        'assets/icons/pdf/email.png',
      )).buffer.asUint8List();
      emailIcon = pw.MemoryImage(emailBytes);
    } catch (_) {
      emailIcon = null;
    }
    try {
      final Uint8List websiteBytes = (await rootBundle.load(
        'assets/icons/pdf/website.png',
      )).buffer.asUint8List();
      websiteIcon = pw.MemoryImage(websiteBytes);
    } catch (_) {
      websiteIcon = null;
    }
    try {
      final Uint8List addressBytes = (await rootBundle.load(
        'assets/icons/pdf/address.png',
      )).buffer.asUint8List();
      addressIcon = pw.MemoryImage(addressBytes);
    } catch (_) {
      addressIcon = null;
    }
    try {
      final Uint8List wellbeingBytes = (await rootBundle.load(
        'assets/icons/pdf/wellbeing.png',
      )).buffer.asUint8List();
      wellbeingIcon = pw.MemoryImage(wellbeingBytes);
    } catch (_) {
      wellbeingIcon = null;
    }
    try {
      final Uint8List bankBytes = (await rootBundle.load(
        'assets/icons/pdf/bank.png',
      )).buffer.asUint8List();
      bankIcon = pw.MemoryImage(bankBytes);
    } catch (_) {
      bankIcon = null;
    }

    // Resolve the page background: either a custom image, a solid
    // colour, or a default grey.
    final pw.BoxDecoration bg = await _resolveBackground(profile);
    final _Palette pal = _computePalette(profile);

    // Define commonly used text styles. Note that fontFallback
    // includes the symbols font to ensure emoji display.
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

    // Try to load avatar image. If loading fails, omit the avatar.
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
              // Background layer.
              pw.Positioned.fill(child: pw.Container(decoration: bg)),
              // Top section: Avatar, name and role, address block.
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
                              : 'Professional Title',
                          style: hRole,
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 14),
                        // Address block with link and spacing below.
                        _addressCentered(profile, body, linkStyle, pal),
                        // Contact and banking details follow immediately after the address.
                        _iconLineWithValue(
                          icon: phoneIcon,
                          labelTextExact: 'Call:',
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
                        ),
                        _iconLineWithValue(
                          icon: emailIcon,
                          labelTextExact: 'Email:',
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
                        ),
                        _iconLineWithValue(
                          icon: websiteIcon,
                          labelTextExact: 'Website:',
                          valueText: _displayHost(
                            profile.website.isNotEmpty
                                ? profile.website
                                : 'google.com',
                          ),
                          link: _ensureHttpUri(
                            profile.website.isNotEmpty
                                ? profile.website
                                : 'google.com',
                          ),
                          body: body,
                          linkStyle: linkStyle,
                        ),
                        _iconLineWithValue(
                          icon: wellbeingIcon,
                          labelTextExact: 'Wellbeing:',
                          valueText: _displayHost(
                            profile.wellbeingLink.isNotEmpty
                                ? profile.wellbeingLink
                                : 'wellbeing.example.com',
                          ),
                          link: _ensureHttpUri(
                            profile.wellbeingLink.isNotEmpty
                                ? profile.wellbeingLink
                                : 'wellbeing.example.com',
                          ),
                          body: body,
                          linkStyle: linkStyle,
                        ),
                        _iconLineWithValue(
                          icon: bankIcon,
                          labelTextExact: 'Sort Code:',
                          valueText: profile.bankSortCode.isNotEmpty
                              ? profile.bankSortCode
                              : '09-01-35',
                          link: _payLinkUri(profile),
                          body: body,
                          linkStyle: linkStyle,
                        ),
                        _iconLineWithValue(
                          icon: bankIcon,
                          labelTextExact: 'Account Number:',
                          valueText: profile.bankAccountNumber.isNotEmpty
                              ? profile.bankAccountNumber
                              : '93087283',
                          link: _payLinkUri(profile),
                          body: body,
                          linkStyle: linkStyle,
                        ),
                        _iconActionLine(
                          icon: bankIcon,
                          prefixExact:
                              'Send Money to ${profile.fullName.isNotEmpty ? profile.fullName.split(' ').first : 'Friend'} ',
                          linkTextExact: 'Click Here',
                          link: _payLinkUri(profile),
                          body: body,
                          linkStyle: linkStyle,
                        ),
                        // Add large space at bottom to prevent overlap with QR code.
                        pw.SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
              // QR code anchored bottom right.
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

    // Save the document to a temporary file and return it.
    final Directory dir = await getTemporaryDirectory();
    final File file = File(
      '${dir.path}/MShare-${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Build the address block with a clickable maps link and spacing
  /// after the link to separate it from subsequent contact details.
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
          // Provide extra separation below the address for readability.
          pw.SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Convert raw address string into formatted lines. This logic removes
  /// duplicates and common UK elements ("London", "United Kingdom") and
  /// inserts sensible defaults when fields are missing.
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
      (String e) => e.toLowerCase().startsWith('united kingdom'),
    );
    final String line1 = cleaned.isNotEmpty
        ? '${cleaned[0]},'
        : 'Flat 72 Priory Court,';
    final String line2 = cleaned.length > 1
        ? '${cleaned[1]},'
        : '1 Cheltenham Road,';
    const String line3 = 'London';
    final String line4 =
        (postcode ?? (cleaned.length > 2 ? cleaned[2] : 'SE15 3BG'))
            .toUpperCase();
    const String line5 = 'United Kingdom.';
    return <String>[line1, line2, line3, line4, line5];
  }

  /// Build a row with an image icon, label, and linked value.
  static pw.Widget _iconLineWithValue({
    required pw.ImageProvider? icon,
    required String labelTextExact,
    required String valueText,
    required Uri link,
    required pw.TextStyle body,
    required pw.TextStyle linkStyle,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _imageChip(icon),
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

  /// Build a row with an image icon, prefix and a linked action text.
  static pw.Widget _iconActionLine({
    required pw.ImageProvider? icon,
    required String prefixExact,
    required String linkTextExact,
    required Uri link,
    required pw.TextStyle body,
    required pw.TextStyle linkStyle,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _imageChip(icon),
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

  /// Draw a small square with a centred image icon. If the icon
  /// fails to load, an empty square is drawn instead. The border and
  /// background ensure contrast on any page background.
  static pw.Widget _imageChip(pw.ImageProvider? image) => pw.Container(
    width: 20,
    height: 20,
    alignment: pw.Alignment.center,
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      border: pw.Border.all(color: PdfColors.grey400, width: 0.7),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: image != null
        ? pw.Image(image, width: 12, height: 12, fit: pw.BoxFit.contain)
        : pw.Container(),
  );

  /// Compute a payment link based on available data: prefer website,
  /// otherwise use maps for address, else a blank URL.
  static Uri _payLinkUri(Profile p) {
    if (p.website.isNotEmpty) return _ensureHttpUri(p.website);
    if (p.address.isNotEmpty) return _mapsUri(p.address);
    return Uri.parse('about:blank');
  }

  /// Display only the host portion of a URL, trimming protocol and www.
  static String _displayHost(String input) {
    final String t = input.trim();
    try {
      final Uri uri = t.startsWith('http')
          ? Uri.parse(t)
          : Uri.parse('https://$t');
      return uri.host.isNotEmpty
          ? uri.host.replaceFirst(RegExp(r'^www\.'), '')
          : t;
    } catch (_) {
      return t;
    }
  }

  /// Ensure a URL has a protocol; assume HTTPS if missing.
  static Uri _ensureHttpUri(String input) {
    final String t = input.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) {
      return Uri.parse(t);
    }
    return Uri.parse('https://$t');
  }

  /// Build a maps link for a given address.
  static Uri _mapsUri(String address) => Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
  );

  /// Fallback: ensure a URL begins with http or https.
  static String _ensureHttp(String input) {
    final String t = input.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    return 'https://$t';
  }

  /// Resolve the background for the PDF. If a custom image is provided
  /// in [profile.backgroundPath], load it; otherwise use a solid colour
  /// derived from the profile or a default.
  static Future<pw.BoxDecoration> _resolveBackground(Profile profile) async {
    if (profile.backgroundPath != null && profile.backgroundPath!.isNotEmpty) {
      try {
        final Uint8List bytes = profile.backgroundPath!.startsWith('assets/')
            ? (await rootBundle.load(
                profile.backgroundPath!,
              )).buffer.asUint8List()
            : await File(profile.backgroundPath!).readAsBytes();
        return pw.BoxDecoration(
          image: pw.DecorationImage(
            image: pw.MemoryImage(bytes),
            fit: pw.BoxFit.cover,
          ),
        );
      } catch (_) {}
    }
    return pw.BoxDecoration(
      color: profile.backgroundColor != null
          ? PdfColor.fromInt(profile.backgroundColor!.toARGB32())
          : PdfColors.grey200,
    );
  }

  /// Compute text and link colours based on the background colour for
  /// contrast. Light backgrounds use dark text; dark backgrounds use
  /// light text.
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

  /// Load fonts used in the PDF. If custom fonts are unavailable,
  /// fall back to built-in Helvetica fonts. The symbols font ensures
  /// emoji render correctly.
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
      bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter-Bold.ttf'));
    } catch (_) {
      bold = pw.Font.helveticaBold();
    }
    try {
      symbols = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansSymbols2-Regular.ttf'),
      );
    } catch (_) {
      // Fall back to base if symbols font isn't found.
      symbols = base;
    }
    return _Fonts(base: base, bold: bold, symbols: symbols);
  }
}

/// Simple container for palette colours.
class _Palette {
  final PdfColor text;
  final PdfColor link;
  _Palette({required this.text, required this.link});
}

/// Container for fonts used throughout the document.
class _Fonts {
  final pw.Font base;
  final pw.Font bold;
  final pw.Font symbols;
  _Fonts({required this.base, required this.bold, required this.symbols});
}
