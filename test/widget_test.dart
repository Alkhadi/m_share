import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_share/main.dart';
import 'package:m_share/models/profile_data.dart';

void main() {
  testWidgets('App builds and shows ProfilePage', (tester) async {
    const profile = ProfileData(
      name: 'John Doe',
      title: 'Position',
      ref: 'M SHARE',
      addr: '123 Test Street, London',
      email: 'johndoe@example.com',
      phone: '+441234567890',
      site: 'https://example.com',
    );

    await tester.pumpWidget(MShareApp(data: profile));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
  });
}
