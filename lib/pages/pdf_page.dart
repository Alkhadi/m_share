// lib/pages/pdf_page.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../models/profile_data.dart';
import '../widgets/common.dart';
import '../widgets/share_sheet.dart';

class PdfPage extends StatelessWidget {
  final ProfileData data;
  const PdfPage({super.key, required this.data});

  void _openShare(BuildContext context) {
    final Uri url = data.profileUrl();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1220),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => ShareSheet(data: data, profileUrl: url),
    );
  }

  Future<File> _copyAssetToTemp() async {
    final Directory dir = await getTemporaryDirectory();
    final String path = '${dir.path}/m_share_profile.pdf';
    final ByteData bytes = await rootBundle.load(
      'assets/pdf/m_share_profile.pdf',
    );
    final File file = File(path);
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return file;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavBar(
        profile: () => Navigator.pop(context),
        money: () => Navigator.popAndPushNamed(context, '/bank'),
        wellbeing: () => Navigator.popAndPushNamed(context, '/wellbeing'),
        pdf: () {},
        share: () => _openShare(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: border),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Download Profile PDF',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'This PDF contains tappable links for phone, email, website, maps, and banking.',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final File f = await _copyAssetToTemp();
                      await OpenFilex.open(f.path);
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download / Open PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Profile'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
