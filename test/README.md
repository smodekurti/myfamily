# Testing Guide for MyFamily App

This directory contains all tests for the MyFamily Flutter application.

## Test Structure

```
test/
├── README.md                    # This file
├── widget_test.dart             # Basic app launch test
├── unit/                        # Unit tests for business logic
│   └── repositories/           # Repository unit tests
├── widget/                      # Widget tests for UI components
│   ├── settings_page_test.dart
│   └── help_page_test.dart
└── golden/                      # Golden tests for visual regression
```

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test Files
```bash
# Unit tests
flutter test test/unit/

# Widget tests
flutter test test/widget/

# Golden tests
flutter test test/golden/
```

### Run Tests with Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Types

### Unit Tests
Unit tests verify business logic in isolation, typically testing:
- Repository methods
- Service classes
- Utility functions
- Data transformations

**Location:** `test/unit/`

**Example:**
```dart
test('Task points should default to 10', () {
  // Test implementation
});
```

### Widget Tests
Widget tests verify UI components render correctly and handle user interactions:
- Page rendering
- User interactions (taps, scrolls)
- State changes
- Navigation

**Location:** `test/widget/`

**Example:**
```dart
testWidgets('Settings page displays all sections', (WidgetTester tester) async {
  await tester.pumpWidget(MyWidget());
  expect(find.text('Settings'), findsOneWidget);
});
```

### Golden Tests
Golden tests capture widget snapshots for visual regression testing:
- UI consistency across changes
- Responsive design at different breakpoints
- Theme variations (light/dark)

**Location:** `test/golden/`

**Breakpoints to test:**
- 320px (small mobile)
- 390px (standard mobile)
- 480px (large mobile)
- 600px (tablet)
- 840px (desktop)

## Writing Tests

### Best Practices

1. **Test Structure**
   - Use `group()` to organize related tests
   - Use descriptive test names
   - Follow AAA pattern (Arrange, Act, Assert)

2. **Mocking**
   - Use `mockito` for mocking dependencies
   - Mock Supabase client for repository tests
   - Mock providers for widget tests

3. **Test Data**
   - Create test fixtures for common data structures
   - Use factories for generating test models
   - Keep test data realistic but minimal

4. **Async Testing**
   - Use `await tester.pumpAndSettle()` for animations
   - Use `await tester.pump()` for specific timing
   - Handle async operations properly

### Example Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('FeatureName', () {
    testWidgets('should display correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: MyWidget()),
        ),
      );

      // Act
      await tester.tap(find.byKey(Key('button')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Expected Text'), findsOneWidget);
    });
  });
}
```

## Continuous Integration

Tests should be run automatically in CI/CD pipeline:
- On every pull request
- Before merging to main
- On every commit to main

## Coverage Goals

- **Unit Tests:** 80%+ coverage for repositories and services
- **Widget Tests:** All major pages and reusable widgets
- **Golden Tests:** All responsive breakpoints for key screens

## Troubleshooting

### Tests Failing Due to Supabase
- Use mocks instead of real Supabase client
- Set up test environment variables
- Use dependency injection for testability

### Widget Tests Timing Out
- Increase timeout: `testWidgets(..., timeout: Timeout(Duration(seconds: 30)))`
- Use `pumpAndSettle()` instead of multiple `pump()` calls
- Check for infinite animations

### Golden Tests Failing
- Update goldens: `flutter test --update-goldens`
- Verify test environment matches CI
- Check for platform-specific rendering differences

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Widget Testing Guide](https://docs.flutter.dev/cookbook/testing/widget)
- [Golden Toolkit Documentation](https://pub.dev/packages/golden_toolkit)

