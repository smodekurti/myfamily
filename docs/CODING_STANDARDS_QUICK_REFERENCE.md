# 🎯 Coding Standards Quick Reference

## ✅ DO's

### Dimensions
```dart
✅ ResponsiveHelper.w(100)        // Width
✅ ResponsiveHelper.h(50)          // Height
✅ ResponsiveHelper.sp(16)         // Font size
✅ ResponsiveHelper.r(12)         // Border radius
✅ ResponsiveHelper.padding(all: 16)
✅ ResponsiveHelper.iconSize(24)
✅ ResponsiveHelper.buttonHeight(56)
```

### Colors
```dart
✅ Theme.of(context).colorScheme.primary
✅ Theme.of(context).colorScheme.onSurface
✅ Theme.of(context).colorScheme.error
✅ Theme.of(context).scaffoldBackgroundColor
```

### Typography
```dart
✅ Theme.of(context).textTheme.headlineLarge
✅ Theme.of(context).textTheme.bodyMedium
✅ Theme.of(context).textTheme.titleSmall
```

### Constants
```dart
✅ AppConstants.maxImageUploadSize
✅ AppConstants.defaultAnimationDuration
✅ AppConstants.minPasswordLength
✅ AppConstants.routeHome
```

### Responsive Checks
```dart
✅ ResponsiveHelper.isMobile(context)
✅ ResponsiveHelper.isTablet(context)
✅ ResponsiveHelper.isDesktop(context)
✅ LayoutBuilder for complex layouts
```

## ❌ DON'Ts

```dart
❌ width: 100                    // Use ResponsiveHelper.w(100)
❌ height: 50                    // Use ResponsiveHelper.h(50)
❌ fontSize: 16                  // Use ResponsiveHelper.sp(16)
❌ Colors.red                    // Use Theme colors
❌ Color(0xFF000000)             // Use Theme colors
❌ EdgeInsets.all(16)            // Use ResponsiveHelper.padding()
❌ 'Welcome'                     // Use localization or constants
❌ 'https://api.example.com'    // Use AppConstants
❌ if (value > 100)              // Use named constants
```

## 📋 Common Patterns

### Responsive Container
```dart
Container(
  width: ResponsiveHelper.w(100),
  height: ResponsiveHelper.h(50),
  padding: ResponsiveHelper.padding(all: 16),
  margin: ResponsiveHelper.padding(horizontal: 20),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.primary,
    borderRadius: BorderRadius.circular(ResponsiveHelper.r(12)),
  ),
)
```

### Responsive Text
```dart
Text(
  'Hello',
  style: Theme.of(context).textTheme.titleLarge?.copyWith(
    fontSize: ResponsiveHelper.sp(18),
    color: Theme.of(context).colorScheme.onSurface,
  ),
)
```

### Responsive Button
```dart
SizedBox(
  width: double.infinity,
  height: ResponsiveHelper.buttonHeight(56),
  child: ElevatedButton(
    onPressed: () {},
    style: ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveHelper.r(12)),
      ),
    ),
    child: Text('Button'),
  ),
)
```

### Responsive Layout
```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isMobile = ResponsiveHelper.isMobile(context);
    return isMobile ? MobileLayout() : TabletLayout();
  },
)
```

### Responsive Grid
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: ResponsiveHelper.isMobile(context) ? 2 : 3,
    childAspectRatio: ResponsiveHelper.isMobile(context) ? 0.8 : 1.0,
    crossAxisSpacing: ResponsiveHelper.w(16),
    mainAxisSpacing: ResponsiveHelper.h(16),
  ),
  itemBuilder: (context, index) => ItemWidget(),
)
```

## 🔍 Before Committing Checklist

- [ ] No hardcoded dimensions
- [ ] No hardcoded colors
- [ ] No hardcoded strings (user-facing)
- [ ] All UI uses ResponsiveHelper
- [ ] All colors use Theme
- [ ] Layouts adapt to screen size
- [ ] Error handling implemented
- [ ] Loading states shown
- [ ] Accessibility labels added

## 📚 File Locations

- **Constants**: `lib/app/core/constants/app_constants.dart`
- **Responsive Helper**: `lib/app/common/responsive/responsive_helper.dart`
- **Theme**: `lib/app/core/theme/app_theme.dart`
- **Rules**: `.cursorrules`

## 🎨 Theme Colors Reference

```dart
Theme.of(context).colorScheme.primary          // Primary brand color
Theme.of(context).colorScheme.secondary        // Secondary color
Theme.of(context).colorScheme.tertiary         // Tertiary color
Theme.of(context).colorScheme.error            // Error color
Theme.of(context).colorScheme.surface          // Surface color
Theme.of(context).colorScheme.onSurface        // Text on surface
Theme.of(context).colorScheme.onPrimary        // Text on primary
Theme.of(context).scaffoldBackgroundColor      // Background color
```

## 📏 Responsive Breakpoints

- **Mobile**: ≤ 450px width
- **Tablet**: 451px - 800px width
- **Desktop**: > 800px width

Use `ResponsiveHelper.isMobile(context)` etc. to check.

---

**Remember: If you're about to hardcode something, STOP and use a helper/constant/theme instead!** 🚫

