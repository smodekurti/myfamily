// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myfamily/main.dart';

/// Basic app launch test
/// 
/// This test verifies that the app can launch without errors.
/// Note: This is a minimal test. For comprehensive testing,
/// see test/widget/ and test/unit/ directories.
void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope (required for Riverpod)
    await tester.pumpWidget(
      const ProviderScope(
        child: MyFamilyApp(),
      ),
    );

    // Wait for initial frame
    await tester.pumpAndSettle();
    
    // Verify app is running (should show splash or auth screen)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
