import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_safe/screens/edit_account.dart';

void main() {
  testWidgets('EditAccountScreen renders and contains Update button', (WidgetTester tester) async {
    // Build the EditAccountScreen inside a MaterialApp
    await tester.pumpWidget(const MaterialApp(
      home: EditAccountScreen(),
    ));

    // Wait for frames to settle (helps with initState async)
    await tester.pumpAndSettle();

    // Check if title and input fields are present
    expect(find.text('Edit Account'), findsOneWidget);
    expect(find.text('Vessel Name'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
  });
}
