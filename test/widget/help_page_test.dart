import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myfamily/app/features/settings/presentation/pages/help_page.dart';

/// Widget tests for HelpPage
/// 
/// Tests verify that the help page displays FAQ, common questions,
/// and support contact information
void main() {
  group('HelpPage Widget Tests', () {
    testWidgets('Help page displays all sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpPage(),
          ),
        ),
      );

      // Verify main sections are present
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Getting Started'), findsOneWidget);
      expect(find.text('Common Questions'), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);
    });

    testWidgets('FAQ questions are expandable', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpPage(),
          ),
        ),
      );

      // Find FAQ question
      expect(find.text('How do I create a family?'), findsOneWidget);
      
      // Tap to expand
      await tester.tap(find.text('How do I create a family?'));
      await tester.pumpAndSettle();

      // Verify answer is displayed
      expect(find.textContaining('To create a family'), findsOneWidget);
    });

    testWidgets('Common questions are displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpPage(),
          ),
        ),
      );

      // Verify common questions are present
      expect(find.text('How do I add tasks?'), findsOneWidget);
      expect(find.text('How do I create a shopping list?'), findsOneWidget);
      expect(find.text('How do points work?'), findsOneWidget);
    });

    testWidgets('Support contact information is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HelpPage(),
          ),
        ),
      );

      // Verify support options
      expect(find.text('Email Support'), findsOneWidget);
      expect(find.text('Report a Bug'), findsOneWidget);
      expect(find.text('App Version'), findsOneWidget);
    });
  });
}

