// lib/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/profile_data.dart';
import '../widgets/common.dart';
import '../widgets/share_sheet.dart';
import 'bank_page.dart';
import 'pdf_page.dart';
import 'wellbeing_page.dart';

class ProfilePage extends StatelessWidget {
  final ProfileData data;
  const ProfilePage({super.key, required this.data});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NavBar(
        profile: () {},
        money: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BankPage(data: data)),
        ),
        wellbeing: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WellbeingPage(data: data)),
        ),
        pdf: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PdfPage(data: data)),
        ),
        share: () => _openShare(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: border),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: SizedBox(
                          width: 160,
                          height: 160,
                          child:
                              data.avatarUrl != null &&
                                  data.avatarUrl!.isNotEmpty
                              ? (data.avatarUrl!.startsWith('http')
                                    ? Image.network(
                                        data.avatarUrl!,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        data.avatarUrl!,
                                        fit: BoxFit.cover,
                                      ))
                              : Container(color: const Color(0xFF0A1020)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.title,
                              style: const TextStyle(color: muted),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PdfPage(data: data),
                                    ),
                                  ),
                                  icon: const Text('⬇️'),
                                  label: const Text('Download Profile (PDF)'),
                                ),
                                FilledButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BankPage(data: data),
                                    ),
                                  ),
                                  icon: const Text('💷'),
                                  label: const Text('Send/Receive Money'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => WellbeingPage(data: data),
                                    ),
                                  ),
                                  icon: const Text('💡'),
                                  label: const Text('Wellbeing'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _openShare(context),
                                  icon: const Icon(Icons.share_outlined),
                                  label: const Text('Share'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: border, height: 1),
                  const SizedBox(height: 14),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final bool twoCol = constraints.maxWidth >= 760;
                      const double spacing = 12.0;

                      Widget wrapTile(Widget child) => SizedBox(
                        width: twoCol
                            ? (constraints.maxWidth - spacing) / 2
                            : constraints.maxWidth,
                        child: child,
                      );

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          wrapTile(
                            Tile(
                              label: 'Phone',
                              value: _linkOrDash('tel:', data.phone),
                            ),
                          ),
                          wrapTile(
                            Tile(
                              label: 'Email',
                              value: _linkOrDash('mailto:', data.email),
                            ),
                          ),
                          wrapTile(
                            Tile(
                              label: 'Website',
                              value: _linkOrDash('', data.site),
                            ),
                          ),
                          wrapTile(
                            Tile(
                              label: 'Address',
                              value: _addressWidget(data.addr),
                            ),
                          ),

                          // Full width wellbeing
                          SizedBox(
                            width: constraints.maxWidth,
                            child: Tile(
                              label: 'Wellbeing link',
                              value: _linkOrDash('', data.wellbeingLink),
                              full: true,
                            ),
                          ),

                          wrapTile(
                            Tile(
                              label: 'AC Number',
                              value: Text(
                                (data.ac ?? '').isEmpty ? '—' : data.ac!,
                              ),
                            ),
                          ),
                          wrapTile(
                            Tile(
                              label: 'Sort code',
                              value: Text(
                                (data.sort ?? '').isEmpty ? '—' : data.sort!,
                              ),
                            ),
                          ),
                          wrapTile(
                            Tile(
                              label: 'IBAN',
                              value: Text(
                                (data.iban ?? '').isEmpty ? '—' : data.iban!,
                              ),
                            ),
                          ),
                          wrapTile(
                            Tile(
                              label: 'Reference',
                              value: Text(data.ref.isEmpty ? '—' : data.ref),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    children: [
                      if (data.x != null && data.x!.isNotEmpty)
                        BadgeChip(child: _outLink('X', data.x!)),
                      if (data.ig != null && data.ig!.isNotEmpty)
                        BadgeChip(child: _outLink('Instagram', data.ig!)),
                      if (data.yt != null && data.yt!.isNotEmpty)
                        BadgeChip(child: _outLink('YouTube', data.yt!)),
                      if (data.ln != null && data.ln!.isNotEmpty)
                        BadgeChip(child: _outLink('LinkedIn', data.ln!)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tip: You can pass values via URL params (web) or update defaults in code.',
              style: TextStyle(color: muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _linkOrDash(String scheme, String? val) {
    if (val == null || val.isEmpty) return const Text('—');
    final Uri uri = Uri.tryParse(scheme + val) ?? Uri();
    return InkWell(
      onTap: () => launchUrl(uri, mode: LaunchMode.externalApplication),
      child: Text(val, style: const TextStyle(color: Color(0xFF38BDF8))),
    );
  }

  Widget _addressWidget(String? addr) {
    if (addr == null || addr.isEmpty) return const Text('—');
    final String q = Uri.encodeComponent(addr);
    final Uri url = Uri.parse('https://maps.google.com/?q=$q');
    return InkWell(
      onTap: () => launchUrl(url, mode: LaunchMode.externalApplication),
      child: Text(addr, style: const TextStyle(color: Color(0xFF38BDF8))),
    );
  }

  Widget _outLink(String label, String url) {
    final Uri u = Uri.parse(url);
    return InkWell(
      onTap: () => launchUrl(u, mode: LaunchMode.externalApplication),
      child: Text(label, style: const TextStyle(color: Color(0xFFE5E7EB))),
    );
  }
}
