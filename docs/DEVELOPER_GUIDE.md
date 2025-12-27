# MyFamily Developer Guide

This guide helps new developers get started with the MyFamily Flutter application.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project Setup](#project-setup)
3. [Architecture Overview](#architecture-overview)
4. [Development Workflow](#development-workflow)
5. [Code Standards](#code-standards)
6. [Testing](#testing)
7. [Common Tasks](#common-tasks)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software
- **Flutter SDK** (3.9.2 or higher)
  ```bash
  flutter --version
  ```
- **Dart SDK** (included with Flutter)
- **Git** for version control
- **IDE**: VS Code or Android Studio with Flutter plugins

### Required Accounts
- **Supabase Account** - For backend services
- **Firebase Account** - For push notifications (FCM)
- **Apple Developer Account** (for iOS development) - Optional
- **Google Cloud Console** (for Google Sign-In) - Optional

## Project Setup

### 1. Clone the Repository
```bash
git clone <repository-url>
cd myfamily
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Environment

#### Supabase Configuration
1. Create a Supabase project at https://supabase.com
2. Get your project URL and anon key from Settings > API
3. Update `lib/app/core/config/supabase_config.dart`:
   ```dart
   static const String supabaseUrl = 'https://your-project.supabase.co';
   static const String supabaseAnonKey = 'your-anon-key';
   ```
   
   **OR** use environment variables:
   ```bash
   flutter run --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=...
   ```

#### Firebase Configuration
1. Create a Firebase project at https://console.firebase.google.com
2. Add iOS and Android apps to your project
3. Download configuration files:
   - `ios/Runner/GoogleService-Info.plist` (iOS)
   - `android/app/google-services.json` (Android)
4. Place them in the respective directories

#### Database Setup
Run the SQL migration scripts in order:
1. `create_tasks_table.sql`
2. `create_grocery_tables.sql`
3. `create_announcements_table.sql`
4. `add_family_members_points_column.sql`
5. `add_role_permissions_system.sql`
6. `PRODUCTION_RLS_POLICIES.sql`

See `DATABASE_MIGRATIONS.md` for complete migration guide.

### 4. Run the App
```bash
# iOS
flutter run -d ios

# Android
flutter run -d android

# Web (limited support)
flutter run -d chrome
```

## Architecture Overview

### Clean Architecture Pattern

```
lib/app/
├── core/              # Shared infrastructure
│   ├── providers/     # Riverpod providers
│   ├── router/        # Navigation & routing
│   ├── theme/         # App theming
│   ├── services/      # Core services (notifications, auth, etc.)
│   └── constants/     # App-wide constants
│
├── features/          # Feature modules
│   ├── auth/          # Authentication
│   ├── family/        # Family management
│   ├── tasks/         # Task management
│   ├── groceries/     # Grocery lists
│   ├── calendar/      # Events & calendar
│   ├── gamification/  # Points & leaderboards
│   └── profile/       # User profile
│
├── common/            # Shared components
│   ├── widgets/       # Reusable widgets
│   ├── utils/         # Utility functions
│   └── responsive/    # Responsive helpers
│
└── data/              # Data layer
    ├── models/        # Data models (Freezed)
    └── repositories/  # Data access layer
```

### State Management

**Riverpod** is used for state management:
- `Provider` - For singleton services
- `StateProvider` - For simple state
- `StreamProvider` - For real-time data streams
- `FutureProvider` - For async data loading

### Data Flow

1. **UI Layer** (Features) → Watches providers
2. **Providers** → Call repositories
3. **Repositories** → Interact with Supabase
4. **Supabase** → Returns data
5. **Data flows back** through the chain

### Real-time Updates

Supabase Realtime is used for live data synchronization:
- Tasks update in real-time across devices
- Grocery lists sync automatically
- Calendar events appear instantly
- Family member changes propagate immediately

## Development Workflow

### 1. Feature Development

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Follow the feature structure**
   ```
   lib/app/features/your_feature/
   ├── presentation/
   │   ├── pages/       # Screen widgets
   │   └── widgets/     # Feature-specific widgets
   ├── domain/          # Business logic (if needed)
   └── data/            # Feature-specific data (if needed)
   ```

3. **Create providers** in `lib/app/core/providers/providers.dart`

4. **Add routes** in `lib/app/core/router/app_router.dart`

5. **Write tests** in `test/widget/` or `test/unit/`

6. **Commit and push**
   ```bash
   git add .
   git commit -m "feat: Add your feature"
   git push origin feature/your-feature-name
   ```

### 2. Code Generation

After modifying Freezed models:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Or watch for changes:
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### 3. Running Tests

```bash
# All tests
flutter test

# Specific test file
flutter test test/widget/settings_page_test.dart

# With coverage
flutter test --coverage
```

## Code Standards

### Responsive Design

**NEVER use hardcoded values:**
```dart
// ❌ BAD
Container(width: 100, height: 50)

// ✅ GOOD
Container(
  width: ResponsiveHelper.w(100),
  height: ResponsiveHelper.h(50),
)
```

### Colors

**Always use theme colors:**
```dart
// ❌ BAD
Container(color: Colors.blue)

// ✅ GOOD
Container(color: Theme.of(context).colorScheme.primary)
```

### State Management

**Use Riverpod providers:**
```dart
// ✅ GOOD
final currentUser = ref.watch(currentUserProvider);
final tasks = ref.watch(familyTasksProvider(familyId));
```

### Error Handling

**Always handle errors gracefully:**
```dart
try {
  await someOperation();
} catch (e, stackTrace) {
  _logger.e('Operation failed: $e', error: e, stackTrace: stackTrace);
  // Show user-friendly message
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Operation failed. Please try again.')),
    );
  }
}
```

### Logging

**Use logger for errors only:**
```dart
// ✅ GOOD - Error logging
_logger.e('Error message', error: e, stackTrace: stackTrace);

// ❌ BAD - Debug/info logging (removed in production)
_logger.i('Info message');
print('Debug message');
```

## Testing

### Writing Tests

See `test/README.md` for detailed testing guide.

### Test Structure

```dart
group('FeatureName', () {
  testWidgets('should do something', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(MyWidget());
    
    // Act
    await tester.tap(find.byKey(Key('button')));
    await tester.pumpAndSettle();
    
    // Assert
    expect(find.text('Expected'), findsOneWidget);
  });
});
```

## Common Tasks

### Adding a New Feature

1. Create feature directory structure
2. Create data models (if needed)
3. Create repository (if needed)
4. Create providers
5. Create UI pages/widgets
6. Add routes
7. Write tests
8. Update documentation

### Adding a New Repository Method

1. Add method to repository class
2. Add permission checks (if needed)
3. Handle errors
4. Add tests
5. Update providers if needed

### Adding a New Page

1. Create page widget in appropriate feature
2. Add route in `app_router.dart`
3. Add navigation from parent page
4. Write widget tests
5. Test responsive design

### Debugging

**Common Issues:**

1. **Supabase connection errors**
   - Check `supabase_config.dart` has correct URL/key
   - Verify Supabase project is active
   - Check network connectivity

2. **RLS policy errors**
   - Verify user is authenticated
   - Check RLS policies in Supabase dashboard
   - Review `PRODUCTION_RLS_POLICIES.sql`

3. **Build errors**
   - Run `flutter clean`
   - Run `flutter pub get`
   - Run `flutter pub run build_runner build --delete-conflicting-outputs`

4. **Real-time not working**
   - Check Realtime is enabled in Supabase
   - Verify RLS policies allow SELECT
   - Check network connectivity

## Troubleshooting

### App Won't Build

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Tests Failing

```bash
# Update golden files if needed
flutter test --update-goldens

# Run with verbose output
flutter test --verbose
```

### Supabase Connection Issues

1. Check configuration in `supabase_config.dart`
2. Verify project is active in Supabase dashboard
3. Check RLS policies
4. Review error logs in Supabase dashboard

### Push Notifications Not Working

1. Verify Firebase configuration files are present
2. Check FCM token is being saved
3. Verify notification permissions are granted
4. Check device logs for errors

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [Go Router Documentation](https://pub.dev/packages/go_router)
- [Material 3 Design](https://m3.material.io/)

## Getting Help

- Check existing documentation files in the project root
- Review code comments and inline documentation
- Ask questions in team chat or create an issue
- Review similar features in the codebase

---

**Happy Coding! 🚀**

