import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/urls.dart'; // WebLinks for GitHub Pages
import '../config/utils.dart'; // buildQuery with short keys
import '../models/profile.dart';
import '../services/share_service.dart';
import '../widgets/bank_buttons.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Profile _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('profile_json');
    final legacyQuery = prefs.getString('profile');
    setState(() {
      if (json != null) {
        _profile = Profile.fromJson(json);
      } else if (legacyQuery != null) {
        // backward-compatible: decode query string into map
        final decoded = Uri.decodeComponent(legacyQuery);
        final map = <String, dynamic>{};
        for (final part in decoded.split('&')) {
          final split = part.split('=');
          if (split.isNotEmpty) {
            map[split.first] = split.length > 1
                ? split.sublist(1).join('=')
                : '';
          }
        }
        _profile = Profile.fromMap(map);
      } else {
        _profile = Profile.defaultProfile();
      }
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_json', _profile.toJson());
  }

  Future<void> _editProfile() async {
    final updated = await Navigator.of(context).push<Profile>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: _profile)),
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() => _profile = updated);
      await _saveProfile();
    }
  }

  void _openShareSection() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewPadding.bottom;
        final svc = ShareService(profile: _profile);
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset + 20),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _shareTile(
                  icon: Icons.text_snippet_rounded,
                  label: 'Share My Profile as Text',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await svc.shareAsText(ctx);
                  },
                ),
                _shareTile(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Share PDF + QR',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await svc.sharePdfWithQr(ctx);
                  },
                ),
                _shareTile(
                  icon: Icons.qr_code_2_rounded,
                  label: 'Share QR Image',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await svc.shareQrImage(ctx);
                  },
                ),
                _shareTile(
                  icon: Icons.email_rounded,
                  label: 'Email My M Share',
                  onTap: () async {
                    Navigator.pop(ctx);
                    await svc.shareViaEmail(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _shareTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
    }
  }

  static String _ensureHttp(String input) {
    final t = input.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    return 'https://$t';
  }

  Widget _buildAvatar(Color foreground) {
    final avatarPath = _profile.avatarPath;
    return Center(
      child: CircleAvatar(
        radius: 48,
        backgroundImage: avatarPath != null
            ? (avatarPath.startsWith('assets/')
                  ? AssetImage(avatarPath) as ImageProvider
                  : FileImage(File(avatarPath)))
            : null,
        child: avatarPath == null
            ? Text(
                _profile.fullName.isNotEmpty
                    ? _profile.fullName[0].toUpperCase()
                    : '?',
                style: TextStyle(fontSize: 40, color: foreground),
              )
            : null,
      ),
    );
  }

  Widget _contactRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color foreground,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 20, color: foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Wellbeing tile (above bank section)
  Widget _wellbeingSection(Color foreground) {
    final qp = buildQuery(
      name: _profile.fullName,
      phone: _profile.phone,
      email: _profile.email,
      site: _profile.website,
      addr: _profile.address,
      acc: _profile.bankAccountNumber,
      sort: _profile.bankSortCode,
      ref: 'M SHARE',
      ig: _profile.instagram,
      ln: _profile.linkedin,
      yt: _profile.youtube,
      x: _profile.xHandle,
    );
    return InkWell(
      onTap: () => _launchUrl(Uri.parse(WebLinks.wellbeing(qp))),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Wellbeing',
            style: TextStyle(color: foreground, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _bankSection(Color foreground) {
    final scheme = Theme.of(context).colorScheme;
    final bool hasBgImage = _profile.backgroundPath != null;
    final Color cardColor = hasBgImage
        ? Colors.black.withOpacity(0.4)
        : scheme.surfaceContainerHighest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Send/Receive Money (Bank)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: foreground,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: cardColor,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: foreground),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _profile.fullName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: foreground,
                    ),
                  ),
                  if (_profile.wellbeingLink.isNotEmpty)
                    Text(
                      'Wellbeing: ${_profile.wellbeingLink}',
                      style: TextStyle(color: foreground),
                    ),
                  Text(
                    'Account: ${_profile.bankAccountNumber}',
                    style: TextStyle(color: foreground),
                  ),
                  Text(
                    'Sort: ${_profile.bankSortCode}',
                    style: TextStyle(color: foreground),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Open your banking app with details prefilled:',
                    style: TextStyle(
                      fontSize: 12,
                      color: foreground.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  BankButtons(profile: _profile, foreground: foreground),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String? bg = _profile.backgroundPath;
    final Color bgColor = _profile.backgroundColor ?? Colors.grey.shade200;

    Color foreground;
    if (bg != null) {
      foreground = Colors.white;
    } else {
      final brightness = ThemeData.estimateBrightnessForColor(bgColor);
      foreground = brightness == Brightness.dark
          ? Colors.white
          : Colors.black87;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('My M Share', style: TextStyle(color: foreground)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded, color: foreground),
            onPressed: _openShareSection,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (bg != null)
            Positioned.fill(
              child: bg.startsWith('assets/')
                  ? Image.asset(bg, fit: BoxFit.cover)
                  : Image.file(File(bg), fit: BoxFit.cover),
            )
          else
            Positioned.fill(child: Container(color: bgColor)),
          if (bg != null)
            Positioned.fill(child: Container(color: Colors.black45)),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAvatar(foreground),
                  const SizedBox(height: 8),
                  Text(
                    _profile.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: foreground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_profile.role.isNotEmpty)
                    Text(
                      _profile.role,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: foreground),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 16),
                  _contactRow(
                    icon: Icons.location_on,
                    label: _profile.address,
                    onTap: () async {
                      final q = Uri.encodeComponent(_profile.address);
                      await _launchUrl(
                        Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=$q',
                        ),
                      );
                    },
                    foreground: foreground,
                  ),
                  _contactRow(
                    icon: Icons.phone,
                    label: _profile.phone,
                    onTap: () async =>
                        _launchUrl(Uri.parse('tel:${_profile.phone}')),
                    foreground: foreground,
                  ),
                  _contactRow(
                    icon: Icons.email,
                    label: _profile.email,
                    onTap: () async =>
                        _launchUrl(Uri.parse('mailto:${_profile.email}')),
                    foreground: foreground,
                  ),
                  _contactRow(
                    icon: Icons.link,
                    label: _profile.website,
                    onTap: () async =>
                        _launchUrl(Uri.parse(_ensureHttp(_profile.website))),
                    foreground: foreground,
                  ),
                  const SizedBox(height: 24),
                  _wellbeingSection(foreground),
                  const SizedBox(height: 16),
                  _bankSection(foreground),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
          onPressed: _editProfile,
          tooltip: 'Edit Profile',
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.edit_rounded, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
