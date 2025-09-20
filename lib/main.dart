import 'package:flutter/material.dart';

import 'screens/profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MShareApp());
}

class MShareApp extends StatelessWidget {
  const MShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'M Share',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6A5AE0),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ProfileScreen(),
    );
  }
}
