import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_safe/screens/sos_alerts_list.dart';

void main() {
  testWidgets('SOSAlertScreen renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SOSAlertScreen()));
    expect(find.byType(SOSAlertScreen), findsOneWidget);
  });

  testWidgets('SOSAlertScreen displays Refresh button and loading text',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SOSAlertScreen()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Refresh'), findsOneWidget);
    expect(find.textContaining('Last updated on'), findsNothing); // Should not show yet
  });

  testWidgets('SOSAlertScreen shows fallback when no alerts are available',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SOSAlertScreen()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text("No SOS alerts available."), findsOneWidget);
  });
}
