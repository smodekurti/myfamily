# Responsive Design Rules & Best Practices

To ensure the "MyFamily" app runs flawlessly on all devices (mobile, tablet, desktop) and provides a premium user experience, follow these responsive design rules.

## 1. Core Principles
- **No Hardcoded Pixels**: Never use raw double values for layout dimensions (padding, margin, width, height, radius, font size).
- **Use `ResponsiveHelper`**: Always route size definitions through the `ResponsiveHelper` utility, which wraps `flutter_screenutil`.
- **Safe Area Awareness**: Always respect device safe areas (notch, home indicator) using `SafeArea` or `MediaQuery` padding.
- **Scrollability**: Every screen must handle potential overflow. Never assume content fits on one screen.

## 2. Using `ResponsiveHelper`
The project uses `flutter_screenutil` via `ResponsiveHelper`. Use the following standardized methods:

| Property | Rule | Usage Example |
| :--- | :--- | :--- |
| **Width/Horizontal** | Use `.w` or `ResponsiveHelper.w()` | `width: ResponsiveHelper.w(24)` or `width: 24.w` |
| **Height/Vertical** | Use `.h` or `ResponsiveHelper.h()` | `height: ResponsiveHelper.h(50)` or `height: 50.h` |
| **Font Size** | Use `.sp` or `ResponsiveHelper.sp()` | `fontSize: ResponsiveHelper.sp(16)` or `fontSize: 16.sp` |
| **Radius** | Use `.r` or `ResponsiveHelper.r()` | `radius: ResponsiveHelper.r(12)` or `radius: 12.r` |
| **Padding** | Use `ResponsiveHelper.padding` | `padding: ResponsiveHelper.padding(horizontal: 16, vertical: 8)` |

### Why?
- Ensures UI scales proportionally across different screen sizes (e.g., iPhone SE vs iPhone 15 Pro Max).
- Maintains the intended design density and readability.

## 3. Layout Best Practices

### Flexible Layouts
- **Use `Flex` Widgets**: Use `Expanded`, `Flexible`, and `Spacer` within `Column` and `Row` to let widgets fill available space rather than setting fixed sizes.
  ```dart
  Row(
    children: [
      Expanded(child: Text('This text can expand safely')),
      SizedBox(width: 8.w),
      Icon(Icons.arrow_forward),
    ],
  )
  ```
- **Avoid Fixed Heights in Lists**: Allow list items to determine their own height based on content.

### Handling Text Overflow
- **Text Safety**: Always specify `overflow` behavior and `maxLines` for text that might be long.
  ```dart
  Text(
    longString,
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  )
  ```
- **Scale Text**: Use `.sp` for font sizes so text respects user system accessibility settings (text scaling).

### Safe Areas
- **Bottom Navigation**: Ensure bottom sheets and floating buttons account for the system home indicator (bottom safe area).
- **Status Bar**: Use `SafeArea` for the body of your `Scaffold` if you don't have a custom app bar that handles it.

## 4. Device Type Adaptation
Use `ResponsiveHelper` boolean checks to fundamentally alter layout structure when moving between Phone and Tablet.

| Helper | Purpose |
| :--- | :--- |
| `ResponsiveHelper.isMobile(context)` | Default layout (List views, vertical stacks). |
| `ResponsiveHelper.isTablet(context)` | Use wide layouts (Grid views, side-by-side columns). |
| `ResponsiveHelper.isDesktop(context)` | Full screen layouts, persistent side navigation. |

**Example:**
```dart
if (ResponsiveHelper.isTablet(context)) {
  return GridView.count(crossAxisCount: 3, ...);
} else {
  return ListView(...);
}
```

## 5. Orientation Support
- **Scroll Views**: Always wrap your main content in a scrollable widget (like `SingleChildScrollView` or `CustomScrollView`).
- **Why?**: A layout that fits in Portrait might overflow in Landscape mode because vertical height is significantly reduced.

## 6. Testing Checklist
Before marking a UI task as done, verify:
- [ ] Does it look good on a small screen (e.g., iPhone SE)?
- [ ] Does it look good on a large screen (e.g., iPhone 14 Pro Max)?
- [ ] Does text scaling break the layout?
- [ ] Is content reachable (not hidden behind notches or nav bars)?
- [ ] Does rotating the device cause a "RenderFlex overflowed" error?
