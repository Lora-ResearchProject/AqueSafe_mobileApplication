import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_safe/screens/register.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: '.env'); // Load your .env variables
  });

  testWidgets('RegisterScreen displays form fields and buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: RegisterScreen()),
    );

    // Check that the screen title appears
    expect(find.text('Create account'), findsOneWidget);

    // Check for vessel name field
    expect(
      find.byWidgetPredicate((widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Vessel Name'),
      findsOneWidget,
    );

    // Check for email field
    expect(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.decoration?.labelText == 'Email'),
      findsOneWidget,
    );

    // Check for password field
    expect(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.decoration?.labelText == 'Password'),
      findsOneWidget,
    );

    // Check for Create Account button
    expect(find.text('Create Account'), findsOneWidget);

    // Check for 'Already have an account?' text
    expect(find.text('Already have an account?'), findsOneWidget);

    // Check for Log in button
    expect(find.text('Log in'), findsOneWidget);
  });
}
