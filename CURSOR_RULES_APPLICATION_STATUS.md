# Cursor Rules Application Status

## ✅ Files Fixed (Following Cursor Rules)

### Authentication Pages
- ✅ `lib/app/features/auth/presentation/pages/sign_in_page.dart`
  - Replaced hardcoded padding with `ResponsiveHelper.padding()`
  - Replaced hardcoded logo size with `ResponsiveHelper.w()`
  - Replaced `Colors.white` with `Theme.of(context).colorScheme.onPrimary`
  - Replaced hardcoded password length (6) with `AppConstants.minPasswordLength`
  - Replaced hardcoded routes with `AppConstants.route*`

- ✅ `lib/app/features/auth/presentation/pages/sign_up_page.dart`
  - Replaced hardcoded logo size
  - Replaced hardcoded validation lengths with `AppConstants`
  - Replaced `Colors.white` with theme colors
  - Replaced hardcoded dimensions (20x20) with `ResponsiveHelper`
  - Replaced hardcoded routes with `AppConstants.route*`

- ✅ `lib/app/features/auth/presentation/pages/welcome_page.dart`
  - Replaced hardcoded logo size
  - Replaced `Colors.white` with theme colors
  - Replaced hardcoded routes with `AppConstants.route*`

- ✅ `lib/app/features/auth/presentation/pages/splash_page.dart`
  - Replaced hardcoded animation durations with `AppConstants`
  - Replaced hardcoded animation values with `AppConstants`
  - Replaced hardcoded logo size
  - Replaced hardcoded routes with `AppConstants.route*`

### Profile Pages
- ✅ `lib/app/features/profile/presentation/pages/edit_profile_page.dart`
  - Replaced hardcoded image dimensions (800x800) with `AppConstants.profilePictureSize`
  - Replaced hardcoded image quality (85) with `AppConstants.imageCompressionQuality`
  - Replaced `Colors.white`, `Colors.green`, `Colors.black54` with theme colors
  - Added `AppConstants` import

- ✅ `lib/app/features/profile/presentation/pages/profile_page.dart`
  - Replaced `Colors.white`, `Colors.green`, `Colors.red` with theme colors
  - Replaced hardcoded routes with `AppConstants.route*`

### Core Files
- ✅ `lib/app/core/router/app_router.dart`
  - Replaced ALL hardcoded route strings with `AppConstants.route*`
  - Updated redirect logic to use constants
  - Updated MainShell navigation to use constants

- ✅ `lib/app/core/constants/app_constants.dart`
  - Created comprehensive constants file
  - Added all route constants
  - Added animation duration constants
  - Added validation limits
  - Added configuration values

## ⏳ Files That Need Review

### High Priority (User-Facing)
- `lib/app/features/home/presentation/pages/home_page.dart`
- `lib/app/features/tasks/presentation/pages/tasks_page.dart`
- `lib/app/features/tasks/presentation/pages/create_task_page.dart`
- `lib/app/features/groceries/presentation/pages/groceries_page.dart`
- `lib/app/features/calendar/presentation/pages/calendar_page.dart`

### Medium Priority (Family Features)
- `lib/app/features/family/presentation/pages/create_family_page.dart`
- `lib/app/features/family/presentation/pages/join_family_page.dart`
- `lib/app/features/family/presentation/pages/family_setup_page.dart`
- `lib/app/features/family/presentation/pages/family_selection_page.dart`
- `lib/app/features/family/presentation/pages/get_started_page.dart`

### Low Priority (Common Widgets)
- `lib/app/common/widgets/logo_widget.dart`
- `lib/app/common/widgets/background_widget.dart`
- `lib/app/core/theme/app_theme.dart` (may have intentional hardcoded theme values)

## 🔍 Common Issues to Look For

### 1. Hardcoded Colors
```dart
❌ Colors.white
❌ Colors.black
❌ Colors.red
❌ Colors.green
❌ Colors.blue
❌ Color(0xFF...)

✅ Theme.of(context).colorScheme.onPrimary
✅ Theme.of(context).colorScheme.onSurface
✅ Theme.of(context).colorScheme.error
✅ Theme.of(context).colorScheme.primary
```

### 2. Hardcoded Dimensions
```dart
❌ width: 100
❌ height: 50
❌ padding: EdgeInsets.all(16)
❌ margin: EdgeInsets.symmetric(horizontal: 20)
❌ SizedBox(height: 20)
❌ fontSize: 16
❌ borderRadius: 12

✅ ResponsiveHelper.w(100)
✅ ResponsiveHelper.h(50)
✅ ResponsiveHelper.padding(all: 16)
✅ ResponsiveHelper.padding(horizontal: 20)
✅ SizedBox(height: ResponsiveHelper.h(20))
✅ ResponsiveHelper.sp(16)
✅ ResponsiveHelper.r(12)
```

### 3. Hardcoded Routes
```dart
❌ context.go('/home')
❌ context.push('/profile/edit')

✅ context.go(AppConstants.routeHome)
✅ context.push(AppConstants.routeEditProfile)
```

### 4. Hardcoded Validation Values
```dart
❌ if (value.length < 6)
❌ if (value.length < 2)

✅ if (value.length < AppConstants.minPasswordLength)
✅ if (value.length < AppConstants.minDisplayNameLength)
```

### 5. Hardcoded Configuration
```dart
❌ maxWidth: 800
❌ imageQuality: 85
❌ Duration(seconds: 5)

✅ maxWidth: AppConstants.profilePictureSize.toDouble()
✅ imageQuality: (AppConstants.imageCompressionQuality * 100).toInt()
✅ Duration: AppConstants.splashDisplayDuration
```

## 📋 Quick Fix Checklist

For each file, check:
- [ ] No `Colors.*` (except in theme file)
- [ ] No hardcoded `width:`, `height:`, `fontSize:`
- [ ] No hardcoded `EdgeInsets.all()`, `EdgeInsets.symmetric()`
- [ ] No hardcoded `SizedBox(height: X)` or `SizedBox(width: X)`
- [ ] No hardcoded route strings
- [ ] No hardcoded validation numbers
- [ ] No hardcoded configuration values
- [ ] All dimensions use `ResponsiveHelper`
- [ ] All colors use `Theme.of(context).colorScheme.*`
- [ ] All routes use `AppConstants.route*`

## 🚀 Next Steps

1. **Run lint check** on remaining files
2. **Fix high-priority files** (home, tasks, groceries, calendar)
3. **Fix medium-priority files** (family pages)
4. **Review common widgets** for hardcoded values
5. **Final verification** - run app and test responsive behavior

## 📊 Progress

- **Files Fixed**: 7
- **Files Remaining**: ~15
- **Completion**: ~30%

## 💡 Tips

- Use `grep` to find hardcoded values:
  ```bash
  grep -r "Colors\." lib/
  grep -r "width: [0-9]" lib/
  grep -r "context.go('/" lib/
  ```

- Use find/replace carefully:
  - `Colors.white` → `Theme.of(context).colorScheme.onPrimary`
  - `Colors.black` → `Theme.of(context).colorScheme.onSurface`
  - `Colors.red` → `Theme.of(context).colorScheme.error`
  - `Colors.green` → `Theme.of(context).colorScheme.primary` (or appropriate success color)

