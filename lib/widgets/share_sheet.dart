import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/profile_data.dart';
// Generates a PNG share card from the profile (social-friendly image)
import 'sharecard/share_card.dart' show buildShareCardImageBytes;

/// Bottom sheet to copy/share a user's profile (text + PNG card).
class ShareSheet extends StatefulWidget {
  final ProfileData data;
  final Uri profileUrl;
  const ShareSheet({super.key, required this.data, required this.profileUrl});

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  late final String _text;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _text = _composeShareText(widget.data, widget.profileUrl);
  }

  /// Compose human‑readable share text (includes bank + online link).
  String _composeShareText(ProfileData d, Uri url) {
    final lines = <String>[];

    // Header
    lines.add('${d.name}');
    if (d.title.isNotEmpty) lines.add(d.title);

    // Address, phone, email, site
    if (d.addr.isNotEmpty)
      lines.addAll(
        d.addr
            .split(RegExp(r'[\n,]+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty),
      );
    if (d.phone.isNotEmpty) lines.add('📞 Call: ${d.phone}');
    if (d.email.isNotEmpty) lines.add('📧 Email: ${d.email}');
    if (d.site.isNotEmpty) lines.add('🌐 Website: ${_ensureHttp(d.site)}');
    if (d.wellbeingLink.isNotEmpty)
      lines.add('🩺 Wellbeing: ${_ensureHttp(d.wellbeingLink)}');

    // Social chips if present
    void addSocial(String label, String? url) {
      if (url != null && url.trim().isNotEmpty) {
        lines.add('$label: ${_ensureHttp(url)}');
      }
    }

    addSocial('LinkedIn', d.ln);
    addSocial('Instagram', d.ig);
    addSocial('YouTube', d.yt);
    addSocial('X (Twitter)', d.x);

    // Bank block
    final hasAnyBank =
        (d.bankName?.isNotEmpty ?? false) ||
        (d.ac?.isNotEmpty ?? false) ||
        (d.sort?.isNotEmpty ?? false) ||
        (d.iban?.isNotEmpty ?? false) ||
        d.ref.isNotEmpty;

    if (hasAnyBank) {
      lines.add('—');
      lines.add('Bank Details');
      if ((d.bankName ?? '').isNotEmpty) lines.add('🏦 Bank: ${d.bankName}');
      if ((d.sort ?? '').isNotEmpty) lines.add('🏦 Sort Code: ${d.sort}');
      if ((d.ac ?? '').isNotEmpty) lines.add('🏦 Account Number: ${d.ac}');
      if ((d.iban ?? '').isNotEmpty) lines.add('🏦 IBAN: ${d.iban}');
      if (d.ref.isNotEmpty) lines.add('🏦 Reference: ${d.ref}');
    }

    // Links
    lines.add('—');
    lines.add('Open online: $url');

    return lines.join('\n');
  }

  /// Copy the shareable text.
  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied profile text.')));
  }

  /// Write bytes to a temp file and return the file.
  Future<File> _writeBytes(String filename, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Render PNG share card → save to temp → toast path.
  Future<void> _savePng() async {
    setState(() => _busy = true);
    try {
      final bytes = await buildShareCardImageBytes(
        widget.data,
        widget.profileUrl,
      );
      final file = await _writeBytes('m_share_profile.png', bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved: ${file.path}')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Render PNG share card → share with system sheet (with text).
  Future<void> _sharePng() async {
    setState(() => _busy = true);
    try {
      final bytes = await buildShareCardImageBytes(
        widget.data,
        widget.profileUrl,
      );
      final file = await _writeBytes('m_share_profile.png', bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: _text,
        subject: 'Profile: ${widget.data.name}',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Share raw text only.
  Future<void> _shareNative() async {
    await Share.share(_text, subject: 'Profile: ${widget.data.name}');
  }

  /// Share to WhatsApp / SMS / Email (URL encoded).
  Future<void> _shareTo(String target) async {
    final text = Uri.encodeComponent(_text);
    late final Uri uri;
    switch (target) {
      case 'wa':
        uri = Uri.parse('https://wa.me/?text=$text');
        break;
      case 'sms':
        // Both "sms:?body=" and "sms:&body=" are accepted by most devices;
        // using the canonical variant here:
        uri = Uri.parse('sms:?body=$text');
        break;
      case 'mail':
        uri = Uri.parse(
          'mailto:?subject=${Uri.encodeComponent('Profile: ${widget.data.name}')}&body=$text',
        );
        break;
      default:
        return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Read-only text preview
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A1020),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              padding: const EdgeInsets.all(10),
              child: SelectableText(
                _text,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),

            // Actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _copy,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
                OutlinedButton.icon(
                  onPressed: _shareNative,
                  icon: const Icon(Icons.share),
                  label: const Text('Share…'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _savePng,
                  icon: const Icon(Icons.image),
                  label: Text(_busy ? 'Working…' : 'Save PNG'),
                ),
                FilledButton.icon(
                  onPressed: _busy ? null : _sharePng,
                  icon: const Icon(Icons.ios_share),
                  label: Text(_busy ? 'Working…' : 'Share PNG'),
                ),
                OutlinedButton(
                  onPressed: () => _shareTo('wa'),
                  child: const Text('WhatsApp'),
                ),
                OutlinedButton(
                  onPressed: () => _shareTo('sms'),
                  child: const Text('SMS'),
                ),
                OutlinedButton(
                  onPressed: () => _shareTo('mail'),
                  child: const Text('Email'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- helpers --------------------

String _ensureHttp(String input) {
  final t = input.trim();
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  return 'https://$t';
}
