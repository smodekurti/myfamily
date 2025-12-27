---
description: How to run tests for the MyFamily app
---

# Testing the MyFamily App

This project contains unit tests and widget tests.

## Running All Tests
To run all tests in the project:
```bash
flutter test
```

## Running Specific Tests

### Unit Tests
Unit tests are located in `test/unit/`. To run them:
```bash
flutter test test/unit
```

### Widget Tests
Widget tests are located in `test/widget/`. To run them:
```bash
flutter test test/widget
```

### App Launch Test
To verify the app launches successfully:
```bash
flutter test test/widget_test.dart
```

## Running with Coverage
To generate a coverage report:
```bash
flutter test --coverage
```
The report will be generated in `coverage/lcov.info`. You can visualize it using:
```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Goldens
This project uses `golden_toolkit`. To update golden files:
```bash
flutter test --update-goldens
```
