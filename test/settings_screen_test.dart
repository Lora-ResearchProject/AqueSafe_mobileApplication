import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_safe/screens/settings.dart';

void main() {
  testWidgets('SettingsScreen renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('SettingsScreen shows settings title and options', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pump(const Duration(seconds: 1)); // Give it time to render

    // Check for the title
    expect(find.text('Settings'), findsOneWidget);

    // Check for some settings options
    expect(find.text('Edit Account'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('Tapping Logout opens confirmation dialog', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure you want to Logout?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Logout'), findsNWidgets(2)); // One in list, one in dialog
  });
}
