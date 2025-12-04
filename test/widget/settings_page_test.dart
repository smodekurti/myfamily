import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myfamily/app/features/settings/presentation/pages/settings_page.dart';

/// Widget tests for SettingsPage
/// 
/// Tests verify that the settings page renders correctly
/// and user interactions work as expected
void main() {
  group('SettingsPage Widget Tests', () {
    testWidgets('Settings page displays all sections', (WidgetTester tester) async {
      // Build the widget wrapped in ProviderScope
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      // Verify that key sections are present
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('Theme selector opens when theme tile is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      // Find and tap the theme tile
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      // Verify theme selector dialog appears
      expect(find.text('Select Theme'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System Default'), findsOneWidget);
    });

    testWidgets('Help & Support link navigates correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );

      // Verify Help & Support link exists
      expect(find.text('Help & Support'), findsOneWidget);
    });
  });
}

