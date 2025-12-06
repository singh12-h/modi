// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:modi/main.dart';

void main() {
  testWidgets('Login page displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the login page title is displayed.
    expect(find.text('Staff Portal Login'), findsOneWidget);

    // Verify that the login button is present.
    expect(find.text('Login'), findsOneWidget);

    // Verify that the switch to doctor login button is present.
    expect(find.text('Switch to Doctor Login'), findsOneWidget);
  });
}
