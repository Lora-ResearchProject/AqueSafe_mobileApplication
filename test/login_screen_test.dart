import 'package:aqua_safe/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  testWidgets('LoginScreen displays email and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginScreen()),
    );

    expect(find.text('Login'), findsOneWidget);

    // Check for Email TextField with hint
    expect(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.decoration?.hintText == 'Email'),
      findsOneWidget,
    );

    // Check for Password TextField with hint
    expect(
      find.byWidgetPredicate((widget) =>
          widget is TextField && widget.decoration?.hintText == 'Password'),
      findsOneWidget,
    );

    // Check for login button
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
