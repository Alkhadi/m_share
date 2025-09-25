// lib/pages/bank_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/profile_data.dart';
import '../widgets/common.dart';
import '../widgets/share_sheet.dart';

class BankPage extends StatelessWidget {
  final ProfileData data;
  const BankPage({super.key, required this.data});

  void _openShare(BuildContext context) {
    final url = data.profileUrl();
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
    final details =
        'Payee: ${data.name}\n'
        'Bank: ${data.bankName ?? ''}\n'
        'Account: ${data.ac ?? ''}\n'
        'Sort code: ${data.sort ?? ''}\n'
        'IBAN: ${data.iban ?? ''}\n'
        'Reference: ${data.ref}';

    return Scaffold(
      appBar: NavBar(
        profile: () => Navigator.pop(context),
        money: () {},
        wellbeing: () => Navigator.popAndPushNamed(context, '/wellbeing'),
        pdf: () => Navigator.popAndPushNamed(context, '/pdf'),
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
              Text(
                'Send money to ${data.name}?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap Copy details then choose your bank app.',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  Tile(label: 'Account name', value: Text(data.name)),
                  Tile(label: 'Bank', value: Text(data.bankName ?? '—')),
                  Tile(label: 'Reference', value: Text(data.ref)),
                  Tile(label: 'Account number', value: Text(data.ac ?? '—')),
                  Tile(label: 'Sort code', value: Text(data.sort ?? '—')),
                  Tile(label: 'IBAN', value: Text(data.iban ?? '—')),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: details));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied. Now open your bank app below.'),
                      ),
                    );
                  }
                },
                child: const Text('Copy details'),
              ),
              const SizedBox(height: 12),
              const Text('Open your bank app:', style: TextStyle(color: muted)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _appBtn('Monzo', 'monzo://'),
                  _appBtn('Starling', 'starling://'),
                  _appBtn('Revolut', 'revolut://'),
                  _appBtn('Barclays', 'barclaysmobilebanking://'),
                  _appBtn('NatWest', 'natwest://'),
                  _appBtn('HSBC UK', 'hsbcukmobilebanking://'),
                  _appBtn('Santander', 'santanderuk://'),
                  _appBtn('Lloyds', 'lloydsbank://'),
                  _appBtn('Halifax', 'halifax://'),
                  _appBtn('TSB', 'tsb://'),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openShare(context),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBtn(String label, String scheme) {
    return OutlinedButton(
      onPressed: () async {
        final uri = Uri.parse(scheme);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          final q = Uri.encodeComponent('$label bank');
          final store = Uri.parse(
            'https://play.google.com/store/search?q=$q&c=apps',
          );
          await launchUrl(store, mode: LaunchMode.externalApplication);
        }
      },
      child: Text(label),
    );
  }
}
