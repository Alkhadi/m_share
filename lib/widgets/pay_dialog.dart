import 'package:flutter/material.dart';

import '../models/profile.dart';
import 'bank_buttons.dart';

class PayDialog extends StatelessWidget {
  final Profile profile;
  const PayDialog({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Send/Receive Money'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profile.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Account: ${profile.bankAccountNumber}'),
            Text('Sort: ${profile.bankSortCode}'),
            const SizedBox(height: 12),
            const Text('Open your bank app:'),
            const SizedBox(height: 8),
            BankButtons(profile: profile),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Close'))
      ],
    );
  }
}
