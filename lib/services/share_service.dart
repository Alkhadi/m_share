import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/profile.dart';
import 'pdf_service.dart';
import 'qr_service.dart';

/// Service responsible for sharing a profile via different mediums:
/// PDF, QR image, plain text, and email. The share text is
/// carefully composed to mirror the layout of the PDF while
/// remaining easy to copy and paste.
class ShareService {
  ShareService({required this.profile});
  final Profile profile;

  /// Generate a PDF and share it with a QR code. The subject
  /// 'My M Share Digital Card' indicates the branding.
  Future<void> sharePdfWithQr(BuildContext context) async {
    final pdf = await PdfService.buildProfilePdf(profile: profile);
    await Share.shareXFiles([XFile(pdf.path)], text: 'My M Share digital card');
  }

  /// Share only the QR code image. The QR encodes the user's primary
  /// website or fallback to their profile JSON.
  Future<void> shareQrImage(BuildContext context) async {
    final String data = _primaryShareUrl(profile) ?? profile.website;
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

  /// Share the profile as plain text. The layout closely matches
  /// the PDF: name and role, address (with map link), phone, email,
  /// website, wellbeing link, social links, and bank details.
  Future<void> shareAsText(BuildContext context) async {
    // Simply share the plain text representation of the profile. The
    // subject brands the share with the app name. Attachments are
    // unnecessary for plain-text sharing.
    await ShareService.shareText(profile, subject: 'My M Share digital card');
  }

  /// Share the profile via email with the PDF attached. The body
  /// includes the plain text profile and the PDF is attached as a
  /// file. Subject is branded to M Share.
  Future<void> shareViaEmail(BuildContext context) async {
    final pdf = await PdfService.buildProfilePdf(profile: profile);
    final body = ShareService.renderShareText(profile);
    await Share.shareXFiles(
      [XFile(pdf.path)],
      subject: 'My M Share Digital Card',
      text: body,
    );
  }

  /// Share arbitrary image bytes. Useful for sharing a screenshot or
  /// other picture alongside the profile.
  Future<void> shareImageBytes(
    Uint8List pngBytes, {
    String suggestedName = 'profile_image.png',
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$suggestedName');
    await file.writeAsBytes(pngBytes);
    await Share.shareXFiles([XFile(file.path)]);
  }

  // -------- Static API --------

  /// Compose a plain-text representation of the profile. This
  /// replicates the PDF ordering and includes all available social
  /// links. Use this for email bodies or direct text shares.
  static String renderShareText(Profile p) {
    // Build a shortened Google Maps link for the provided address. Rather
    // than encoding the entire address (which produces a very long URL),
    // extract the postcode from the address and build a query on that.
    // If no postcode is found, fall back to the full encoded address.
    final String mapQuery = _extractPostcode(p.address).isNotEmpty
        ? _extractPostcode(p.address)
        : p.address;
    final String mapUrl = mapQuery.isNotEmpty
        ? 'https://maps.google.com/?q=${Uri.encodeComponent(mapQuery)}'
        : '';

    // Extract values with sensible defaults. These defaults mirror the
    // PDF generation so that the text and PDF share the same content.
    final String name = p.fullName.isNotEmpty ? p.fullName : 'Mariatou Koroma';
    final String role = p.role.isNotEmpty ? p.role : 'Professional Title';
    final String phone = p.phone.isNotEmpty ? p.phone : '07736806367';
    final String email = p.email.isNotEmpty ? p.email : 'ngummariato@gmail.com';
    final String website = p.website.isNotEmpty
        ? _ensureHttp(p.website)
        : 'https://google.com';
    final String wellbeing = p.wellbeingLink.isNotEmpty
        ? _ensureHttp(p.wellbeingLink)
        : 'https://wellbeing.example.com';
    final String sortCode = p.bankSortCode.isNotEmpty
        ? p.bankSortCode
        : '09-01-35';
    final String accountNumber = p.bankAccountNumber.isNotEmpty
        ? p.bankAccountNumber
        : '93087283';

    // Compose each line. Emojis approximate the PDF icons. We show the
    // formatted address lines first, followed by a "Find Address" prompt
    // with "Click Here" to mirror the PDF. The map link is included on
    // the same line so that messaging apps can hyperlink it. Using a
    // shorter URL keeps the text neat.
    final List<String> lines = [];
    lines.add('$name\n$role');
    // Break the address into separate lines for clarity. If the address
    // string contains commas or newlines, split on those characters.
    final List<String> addressParts = p.address
        .split(RegExp(r'[\n,]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    lines.addAll(addressParts);
    // Show the prompt for finding the address. The actual link is not
    // included in the plain text to keep it concise; users can still
    // locate the address using the lines above.
    if (mapUrl.isNotEmpty) {
      lines.add('🏠 Find Address: Click Here: $mapUrl');
    } else {
      lines.add('🏠 Find Address');
    }
    lines.add('📞 Call: $phone');
    lines.add('📧 Email: $email');
    lines.add('🌐 Website: $website');
    lines.add('🩺 Wellbeing: $wellbeing');
    // Social links. Only include entries with non-empty values.
    final List<String> socialLines = [];
    void addSocial(String prefix, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        socialLines.add('$prefix: ${_ensureHttp(value)}');
      }
    }

    addSocial('LinkedIn', p.linkedin);
    addSocial('Instagram', p.instagram);
    addSocial('Facebook', p.facebook);
    addSocial('X (Twitter)', p.xHandle);
    addSocial('TikTok', p.tiktok);
    addSocial('YouTube', p.youtube);
    addSocial('Snapchat', p.snapchat);
    addSocial('Pinterest', p.pinterest);
    addSocial('WhatsApp', p.whatsapp);
    if (socialLines.isNotEmpty) {
      lines.add('Socials:');
      lines.addAll(socialLines);
    }
    // Bank details and send money line. Bank icon not possible in text
    // representation, but we prefix with a money bag emoji for clarity.
    lines.add('—');
    lines.add('Bank Details');
    lines.add('🏦 Sort Code: $sortCode');
    lines.add('🏦 Account Number: $accountNumber');
    // Compute a payment link: prefer website, else address, else blank.
    final Uri payLink = _payLinkUri(p);
    if (payLink.toString().isNotEmpty && payLink.toString() != 'about:blank') {
      final String firstName = name.split(' ').isNotEmpty
          ? name.split(' ').first
          : 'Friend';
      lines.add('💷 Send Money to $firstName: ${payLink.toString()}');
    }
    return lines.join('\n');
  }

  /// Share arbitrary text with an optional subject via the Share API.
  static Future<void> shareText(Profile p, {String? subject}) async {
    await Share.share(renderShareText(p), subject: subject);
  }

  /// Share a PDF and optional PNG as attachments. Specify names for
  /// each file; default names include the mshare prefix.
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

  /// Share a single image. Useful for sending a QR code or avatar alone.
  static Future<void> shareImage(
    Uint8List pngBytes, {
    String suggestedName = 'image.png',
  }) async {
    final tmp = await getTemporaryDirectory();
    final file = File('${tmp.path}/$suggestedName')..writeAsBytesSync(pngBytes);
    await Share.shareXFiles([XFile(file.path)]);
  }

  /// Convert raw bytes into an XFile with a specified name and MIME type.
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

  /// Share an email with attachments. Attachments must be XFiles created
  /// via [xfileFromBytes]. Use this helper for complex email workflows.
  static Future<void> shareEmailWithAttachments({
    required String subject,
    required String body,
    required List<XFile> files,
  }) async {
    await Share.shareXFiles(files, subject: subject, text: body);
  }

  /// Internal utility: compute a payment link for Send Money. Prefer the
  /// user's website if available; otherwise use their address as a Google
  /// Maps URL. If neither is available, return a blank URI. This
  /// duplicates the logic in PdfService for text-based sharing.
  static Uri _payLinkUri(Profile p) {
    if (p.website.isNotEmpty) return Uri.parse(_ensureHttp(p.website));
    if (p.address.isNotEmpty) {
      // For payment links, use the postcode (if available) to shorten
      // the URL. Fall back to the full address if no postcode is found.
      final String query = _extractPostcode(p.address).isNotEmpty
          ? _extractPostcode(p.address)
          : p.address;
      return Uri.parse(
        'https://maps.google.com/?q=${Uri.encodeComponent(query)}',
      );
    }
    return Uri.parse('about:blank');
  }

  /// Copy the user's bank details (sort code and account number) to the
  /// device clipboard. This helper can be invoked by UI widgets when
  /// users tap the bank details or "Send Money" link. Providing this
  /// method here keeps the business logic in one place and mirrors
  /// the intent of the PDF version, where tapping the bank details
  /// should make them easy to reuse. In environments where clipboard
  /// access is unavailable, this call will silently fail.
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

  // Internal utility: ensure a URL begins with http or https.
  static String _ensureHttp(String input) {
    final t = input.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    return 'https://$t';
  }

  /// Extract a UK-style postcode (e.g. SE15 3BG) from the given
  /// address. Returns an empty string if no postcode is found. This
  /// helper uses a regular expression similar to the one used in
  /// PdfService to locate postcodes. If no postcode is found, return
  /// an empty string so that the full address can be used as a fallback.
  static String _extractPostcode(String address) {
    final RegExp regPost = RegExp(r'\b[A-Z]{1,2}\d[A-Z0-9]?\s*\d[A-Z]{2}\b');
    final Match? m = regPost.firstMatch(address.toUpperCase());
    if (m != null) {
      return m.group(0)?.trim() ?? '';
    }
    return '';
  }

  /// Determine the primary share URL. Prefer the user's website, then
  /// LinkedIn if available; otherwise return null.
  String? _primaryShareUrl(Profile p) {
    if (p.website.isNotEmpty) return _ensureHttp(p.website);
    if (p.linkedin?.isNotEmpty == true) return _ensureHttp(p.linkedin!);
    return null;
  }
}
