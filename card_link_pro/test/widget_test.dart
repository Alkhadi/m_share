// title=test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke widget test', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Text('CardLink Pro')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('CardLink Pro'), findsOneWidget);
  });
}
