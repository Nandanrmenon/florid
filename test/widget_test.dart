// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:florid/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MainApp());

    // Wait for the initial frame and some async operations
    // Use a shorter timeout since network calls may be in progress
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }, timeout: const Timeout(Duration(seconds: 30)));
}
