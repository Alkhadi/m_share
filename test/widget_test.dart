import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:m_share/main.dart';

void main() {
  testWidgets('App builds and shows ProfileScreen', (
    WidgetTester tester,
  ) async {
    // Build the app
    await tester.pumpWidget(const MShareApp());

    // Verify the app starts and renders MaterialApp + Scaffold
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);

    // Optional: check for something specific on ProfileScreen
    // e.g. if ProfileScreen has a "Share" button
    // expect(find.text('Share'), findsOneWidget);
  });
}
