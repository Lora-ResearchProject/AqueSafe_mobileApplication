import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_safe/screens/help_screen.dart'; // Update this import path based on your project structure

void main() {
  group('HelpScreen Tests', () {
    testWidgets('renders HelpScreen with all HelpTile titles',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpScreen(),
        ),
      );

      // Verify app bar title
      expect(find.text('Help & Support'), findsOneWidget);

      // Verify all HelpTile titles are present
      expect(find.text('How to use AquaSafe?'), findsOneWidget);
      expect(find.text('How to report an emergency?'), findsOneWidget);
      expect(find.text('Viewing and using Weather Info'), findsOneWidget);
      expect(find.text('Changing account details'), findsOneWidget);
      expect(find.text('Still need help?'), findsOneWidget);
    });

    testWidgets('expands a HelpTile and reveals its content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HelpScreen(),
        ),
      );

      // Tap to expand the first HelpTile
      await tester.tap(find.text('How to use AquaSafe?'));
      await tester.pumpAndSettle();

      // Verify the expanded content is visible
      expect(
        find.textContaining(
            'Navigate to the Hotspots section to see suggested fishing locations.'),
        findsOneWidget,
      );
    });
  });
}
