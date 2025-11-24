import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// App theme configuration with Material 3 design
/// Includes light, dark, and system theme modes with text scaling clamp
class AppTheme {
  // Color scheme based on the UI screenshot (teal/cyan accent for dark theme)
  static const Color primaryColor = Color(0xFF14B8A6); // Teal/Cyan (from screenshot)
  static const Color secondaryColor = Color(0xFF06B6D4); // Cyan
  static const Color surfaceColor = Color(0xFF102121); // Main background color
  static const Color lightTealBackground = Color(0xFFE0F2F1); // Light teal background
  static const Color errorColor = Color(0xFFEF4444); // Red for errors
  static const Color cardColor = Color(0xFF1A2C2C); // Card and list item color
  static const Color textColor = Color(0xFFF7FAFC); // White text
  
  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      // fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: lightTealBackground,
        error: errorColor,
      ),
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: _buildAppBarTheme(Brightness.light),
      cardTheme: _buildCardTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(Brightness.light),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(Brightness.light),
      floatingActionButtonTheme: _buildFloatingActionButtonTheme(),
      dividerTheme: _buildDividerTheme(Brightness.light),
      scaffoldBackgroundColor: lightTealBackground, // Light teal background
    );
  }
  
  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      // fontFamily: 'Inter',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ).copyWith(
        primary: primaryColor, // Teal
        onPrimary: textColor, // White on teal
        secondary: secondaryColor, // Cyan
        onSecondary: textColor,
        error: errorColor,
        onError: textColor,
        surface: surfaceColor, // Main background color
        onSurface: textColor, // White text
        surfaceContainerHighest: cardColor, // Card and list item color
      ),
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: _buildAppBarTheme(Brightness.dark),
      cardTheme: _buildCardTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(Brightness.dark),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(Brightness.dark),
      floatingActionButtonTheme: _buildFloatingActionButtonTheme(),
      dividerTheme: _buildDividerTheme(Brightness.dark),
      scaffoldBackgroundColor: surfaceColor, // Dark teal background
      cardColor: cardColor, // Dark gray cards
    );
  }
  
  /// Build text theme with responsive sizing
  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseTextColor = brightness == Brightness.light 
        ? const Color(0xFF2D3748) 
        : const Color(0xFFF7FAFC);
    
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32.sp,
        fontWeight: FontWeight.bold,
        color: baseTextColor,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.bold,
        color: baseTextColor,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        color: baseTextColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.w600,
        color: baseTextColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.w600,
        color: baseTextColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: baseTextColor,
      ),
      titleLarge: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: baseTextColor,
      ),
      titleMedium: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: baseTextColor,
      ),
      titleSmall: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: baseTextColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.normal,
        color: baseTextColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.normal,
        color: baseTextColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.normal,
        color: baseTextColor.withOpacity(0.7),
      ),
      labelLarge: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: baseTextColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
        color: baseTextColor,
      ),
      labelSmall: TextStyle(
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        color: baseTextColor.withOpacity(0.7),
      ),
    );
  }
  
  /// Build app bar theme
  static AppBarTheme _buildAppBarTheme(Brightness brightness) {
    return AppBarTheme(
      backgroundColor: brightness == Brightness.light 
          ? lightTealBackground 
          : surfaceColor, // Teal background
      foregroundColor: brightness == Brightness.light 
          ? const Color(0xFF2D3748) 
          : textColor, // White text
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18.sp,
        fontWeight: FontWeight.w600,
        color: brightness == Brightness.light 
            ? const Color(0xFF2D3748) 
            : textColor, // White text
      ),
      systemOverlayStyle: brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
    );
  }
  
  /// Build card theme
  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      color: cardColor, // Dark gray cards
      margin: EdgeInsets.zero,
    );
  }
  
  /// Build elevated button theme
  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: EdgeInsets.symmetric(
          horizontal: 24.w,
          vertical: 12.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        textStyle: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  /// Build outlined button theme
  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor, width: 1.5),
        padding: EdgeInsets.symmetric(
          horizontal: 24.w,
          vertical: 12.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.r),
        ),
        textStyle: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  /// Build text button theme
  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 8.h,
        ),
        textStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  /// Build input decoration theme
  static InputDecorationTheme _buildInputDecorationTheme(Brightness brightness) {
    return InputDecorationTheme(
      filled: true,
      fillColor: brightness == Brightness.light 
          ? const Color(0xFFF7FAFC) 
          : const Color(0xFF2D3748),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(
          color: brightness == Brightness.light 
              ? const Color(0xFFE2E8F0) 
              : const Color(0xFF4A5568),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(
          color: brightness == Brightness.light 
              ? const Color(0xFFE2E8F0) 
              : const Color(0xFF4A5568),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(
          color: primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.r),
        borderSide: BorderSide(
          color: errorColor,
          width: 1.5,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 12.h,
      ),
      labelStyle: TextStyle(
        fontSize: 14.sp,
        color: brightness == Brightness.light 
            ? const Color(0xFF4A5568) 
            : const Color(0xFFA0AEC0),
      ),
      hintStyle: TextStyle(
        fontSize: 14.sp,
        color: brightness == Brightness.light 
            ? const Color(0xFFA0AEC0) 
            : const Color(0xFF718096),
      ),
    );
  }
  
  /// Build bottom navigation bar theme
  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme(Brightness brightness) {
    return BottomNavigationBarThemeData(
      backgroundColor: brightness == Brightness.light 
          ? lightTealBackground 
          : surfaceColor, // Teal background
      selectedItemColor: primaryColor, // Teal
      unselectedItemColor: brightness == Brightness.light 
          ? const Color(0xFF718096) 
          : const Color(0xFFA0AEC0), // Light gray
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.normal,
      ),
    );
  }
  
  /// Build floating action button theme
  static FloatingActionButtonThemeData _buildFloatingActionButtonTheme() {
    return FloatingActionButtonThemeData(
      backgroundColor: primaryColor, // Teal
      foregroundColor: textColor, // White
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
    );
  }
  
  /// Build divider theme
  static DividerThemeData _buildDividerTheme(Brightness brightness) {
    return DividerThemeData(
      color: brightness == Brightness.light 
          ? const Color(0xFFE2E8F0) 
          : const Color(0xFF4A5568),
      thickness: 1,
      space: 1,
    );
  }
}

/// Text scaling clamp configuration
class TextScalingClamp {
  static const double minScale = 0.9;
  static const double maxScale = 1.3;
  
  /// Clamp text scale factor
  static double clamp(double scaleFactor) {
    return scaleFactor.clamp(minScale, maxScale);
  }
}
