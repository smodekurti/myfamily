import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Responsive helper class for consistent sizing across the app
/// Following user preferences for responsive design without hardcoded values
class ResponsiveHelper {
  static const double designWidth = 390.0;
  static const double designHeight = 844.0;

  /// Breakpoints as per architecture.mdc
  static const double mobileBreakpoint = 450.0;
  static const double tabletBreakpoint = 800.0;
  static const double desktopBreakpoint = 1024.0;

  /// Get responsive width
  static double w(double width) => width.w;

  /// Get responsive height
  static double h(double height) => height.h;

  /// Get responsive font size
  static double sp(double fontSize) => fontSize.sp;

  /// Get responsive radius
  static double r(double radius) => radius.r;

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width <= mobileBreakpoint;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > mobileBreakpoint && width <= tabletBreakpoint;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > tabletBreakpoint;
  }

  /// Get screen width percentage
  static double sw(BuildContext context, double percentage) => percentage.sw;

  /// Get screen height percentage
  static double sh(BuildContext context, double percentage) => percentage.sh;

  /// Get responsive padding
  static EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    if (all != null) {
      return EdgeInsets.all(all);
    }
    return EdgeInsets.only(
      top: (top ?? vertical ?? 0).h,
      bottom: (bottom ?? vertical ?? 0).h,
      left: (left ?? horizontal ?? 0).w,
      right: (right ?? horizontal ?? 0).w,
    );
  }

  /// Get responsive margin - same as padding
  static EdgeInsets margin({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) => padding(
    all: all,
    horizontal: horizontal,
    vertical: vertical,
    top: top,
    bottom: bottom,
    left: left,
    right: right,
  );

  /// Get responsive spacing
  static double spacing(double value) => value.w;

  /// Get responsive gap
  static double gap(double value) => value.w;

  /// Get responsive icon size
  static double iconSize(double size) => size.w;

  /// Get responsive border radius
  static BorderRadius borderRadius(double radius) =>
      BorderRadius.circular(radius.r);

  /// Get responsive border radius for specific corners
  static BorderRadius borderRadiusOnly({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft.r),
      topRight: Radius.circular(topRight.r),
      bottomLeft: Radius.circular(bottomLeft.r),
      bottomRight: Radius.circular(bottomRight.r),
    );
  }

  /// Get responsive box constraints
  static BoxConstraints constraints({
    double? maxWidth,
    double? maxHeight,
    double? minWidth,
    double? minHeight,
  }) {
    return BoxConstraints(
      maxWidth: maxWidth != null ? maxWidth.w : double.infinity,
      maxHeight: maxHeight != null ? maxHeight.h : double.infinity,
      minWidth: minWidth != null ? minWidth.w : 0,
      minHeight: minHeight != null ? minHeight.h : 0,
    );
  }

  /// Get responsive box shadow
  static List<BoxShadow> boxShadow({
    Color color = Colors.black12,
    double blurRadius = 4,
    double spreadRadius = 0,
    Offset offset = const Offset(0, 2),
  }) {
    return [
      BoxShadow(
        color: color,
        blurRadius: blurRadius.r,
        spreadRadius: spreadRadius.r,
        offset: offset,
      ),
    ];
  }

  /// Get responsive button height
  static double buttonHeight(double height) => height.h;

  /// Get responsive app bar height
  static double appBarHeight() => 56.h;

  /// Get responsive bottom navigation height
  static double bottomNavHeight() => 60.h;

  /// Get responsive screen width percentage (Duplicate method signature match, keeping one)
  static double screenWidth(BuildContext context, double percentage) {
    return percentage.sw;
  }

  /// Get responsive screen height percentage
  static double screenHeight(BuildContext context, double percentage) {
    return percentage.sh;
  }
}

/// Responsive breakpoints for the app
class AppBreakpoints {
  static const double phone = 450;
  static const double largePhone = 600;
  static const double tablet = 800;
  static const double desktop = 1024;

  /// Get responsive breakpoint configuration
  static List<ResponsiveBreakpoint> get breakpoints => [
    ResponsiveBreakpoint.resize(phone, name: mobileName),
    ResponsiveBreakpoint.resize(largePhone, name: largePhoneName),
    ResponsiveBreakpoint.resize(tablet, name: tabletName),
    ResponsiveBreakpoint.autoScale(desktop, name: desktopName),
  ];

  static const String mobileName = 'mobile';
  static const String largePhoneName = 'largePhone';
  static const String tabletName = 'tablet';
  static const String desktopName = 'desktop';
}

/// Simple responsive breakpoint class
class ResponsiveBreakpoint {
  final double breakpoint;
  final String name;
  final bool autoScale;

  const ResponsiveBreakpoint.resize(this.breakpoint, {required this.name})
    : autoScale = false;

  const ResponsiveBreakpoint.autoScale(this.breakpoint, {required this.name})
    : autoScale = true;
}
