// lib/pages/wellbeing_page.dart
import 'package:flutter/material.dart';

import '../models/profile_data.dart';
import '../widgets/common.dart';
import '../widgets/share_sheet.dart';

class WellbeingPage extends StatelessWidget {
  final ProfileData data;
  const WellbeingPage({super.key, required this.data});

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
        profile: () => Navigator.pop(context),
        money: () => Navigator.popAndPushNamed(context, '/bank'),
        wellbeing: () {},
        pdf: () => Navigator.popAndPushNamed(context, '/pdf'),
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
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Wellbeing',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 10),
                  Tile(
                    label: 'Reset',
                    value: Text('inhale 4s • hold 4s • exhale 6–8s ×4'),
                    full: true,
                  ),
                  SizedBox(height: 8),
                  Tile(
                    label: 'Move',
                    value: Text('5–10 min brisk walk after long sits.'),
                    full: true,
                  ),
                  SizedBox(height: 8),
                  Tile(
                    label: 'Focus',
                    value: Text('25/5 Pomodoro; silence alerts.'),
                    full: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
