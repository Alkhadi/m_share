// lib/main.dart
import 'package:flutter/material.dart';

import 'models/profile_data.dart';
import 'pages/profile_page.dart';

/// The root app class.
/// Accepts a [ProfileData] so tests can inject dummy data.
/// Falls back to [ProfileData.defaultProfile()] if none is provided.
class MShareApp extends StatelessWidget {
  final ProfileData data;
  const MShareApp({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'M Share',
      theme: ThemeData.dark(useMaterial3: true),
      home: ProfilePage(data: data),
    );
  }
}

/// Entry point for the real app.
/// Runs with a default profile when launched via `flutter run`.
void main() {
  runApp(
    MShareApp(
      data: ProfileData(
        name: 'Alkhadi Koroma',
        title: 'Flutter Developer',
        ref: 'M SHARE',
        addr: 'Flat 72 Priory Court, 1 Cheltenham Road, London SE15 3BG',
        email: 'ngummariato@gmail.com',
        phone: '07736806367',
        site: 'https://mindpaylink.com',
      ),
    ),
  );
}
