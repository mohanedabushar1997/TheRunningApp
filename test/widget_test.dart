// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:running_app/app.dart';
import 'package:running_app/providers/settings_provider.dart';
import 'package:running_app/providers/workout_provider.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          // Mock providers as needed for testing
        ],
        child: const FitStrideApp(),
      ),
    );

    // Verify that the app renders without errors
    expect(find.byType(FitStrideApp), findsOneWidget);
  });
}
