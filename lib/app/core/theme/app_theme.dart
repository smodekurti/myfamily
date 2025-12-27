import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

/// App theme configuration with Material 3 design
/// Includes light, dark, and system theme modes with text scaling clamp
class AppTheme {
  // Color scheme based on the UI screenshot (teal/cyan accent for dark theme)
  static const Color primaryColor = Color(
    0xFF14B8A6,
  ); // Teal/Cyan (from screenshot)
  static const Color secondaryColor = Color(0xFF06B6D4); // Cyan
  static const Color surfaceColor = Color(
    0xFF102121,
  ); // Main background color (dark theme)
  static const Color lightTealBackground = Color(
    0xFFF0F9F8,
  ); // Lighter, cleaner background for light theme
  static const Color errorColor = Color(0xFFEF4444); // Red for errors
  static const Color cardColor = Color(
    0xFF1A2C2C,
  ); // Card and list item color (dark theme)
  static const Color lightCardColor = Color(
    0xFFFFFFFF,
  ); // White cards for light theme
  static const Color textColor = Color(0xFFF7FAFC); // White text (dark theme)
  static const Color lightTextColor = Color(
    0xFF1A202C,
  ); // Dark text for light theme

  // Global text scaler for slight font increase (10% larger than base)
  static const TextScaler globalTextScale = TextScaler.linear(1.1);

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      // fontFamily: 'Inter',
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: primaryColor,
            brightness: Brightness.light,
          ).copyWith(
            primary: primaryColor,
            onPrimary: Colors.white,
            secondary: secondaryColor,
            onSecondary: Colors.white,
            error: errorColor,
            onError: Colors.white,
            surface: lightCardColor, // White surface
            onSurface: lightTextColor, // Dark text on light surface
            surfaceContainerHighest: const Color(
              0xFFF7FAFC,
            ), // Very light gray for elevated surfaces
            surfaceContainer: const Color(
              0xFFEDF2F7,
            ), // Light gray for containers
            outline: const Color(
              0xFFCBD5E0,
            ), // Darker border color for better visibility
            outlineVariant: const Color(0xFFA0AEC0), // Darker border variant
          ),
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: _buildAppBarTheme(Brightness.light),
      cardTheme: _buildCardTheme(Brightness.light),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(Brightness.light),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(
        Brightness.light,
      ),
      floatingActionButtonTheme: _buildFloatingActionButtonTheme(),
      dividerTheme: _buildDividerTheme(Brightness.light),
      scaffoldBackgroundColor: lightTealBackground, // Light teal background
      cardColor: lightCardColor, // White cards for light theme
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      // fontFamily: 'Inter',
      colorScheme:
          ColorScheme.fromSeed(
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
      cardTheme: _buildCardTheme(Brightness.dark),
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
        ? lightTextColor // Use defined light text color for better contrast
        : textColor;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
        color: baseTextColor,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: baseTextColor,
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.w600,
        color: baseTextColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.w600,
        color: baseTextColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        color: baseTextColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        color: baseTextColor,
      ),
      titleLarge: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        color: baseTextColor,
      ),
      titleMedium: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        color: baseTextColor,
      ),
      titleSmall: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        color: baseTextColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.normal,
        color: baseTextColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
        color: baseTextColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.normal,
        color: baseTextColor.withOpacity(0.7),
      ),
      labelLarge: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        color: baseTextColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        color: baseTextColor,
      ),
      labelSmall: TextStyle(
        fontSize: 10.0,
        fontWeight: FontWeight.w500,
        color: baseTextColor.withOpacity(0.7),
      ),
    );
  }

  /// Build app bar theme
  static AppBarTheme _buildAppBarTheme(Brightness brightness) {
    return AppBarTheme(
      backgroundColor: brightness == Brightness.light
          ? Colors
                .white // White app bar for better contrast
          : surfaceColor, // Teal background for dark theme
      foregroundColor: brightness == Brightness.light
          ? lightTextColor // Dark text for light theme
          : textColor, // White text for dark theme
      elevation: brightness == Brightness.light
          ? 1
          : 0, // Subtle shadow for light theme
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w600,
        color: brightness == Brightness.light
            ? lightTextColor // Dark text for better contrast
            : textColor, // White text for dark theme
      ),
      systemOverlayStyle: brightness == Brightness.light
          ? SystemUiOverlayStyle
                .dark // Dark icons for light theme
          : SystemUiOverlayStyle.light, // Light icons for dark theme
      shadowColor: brightness == Brightness.light
          ? Colors.black.withOpacity(0.05)
          : Colors.transparent,
    );
  }

  /// Build card theme
  static CardThemeData _buildCardTheme(Brightness brightness) {
    return CardThemeData(
      elevation: brightness == Brightness.light ? 1 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: brightness == Brightness.light
            ? BorderSide(
                color: const Color(0xFFE2E8F0), // Subtle border for cards
                width: 1,
              )
            : BorderSide.none,
      ),
      color: brightness == Brightness.light ? lightCardColor : cardColor,
      margin: EdgeInsets.zero,
      shadowColor: brightness == Brightness.light
          ? Colors.black.withOpacity(0.05)
          : Colors.transparent,
    );
  }

  /// Build elevated button theme
  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Build outlined button theme
  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: BorderSide(color: primaryColor, width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Build text button theme
  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        textStyle: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// Build input decoration theme
  static InputDecorationTheme _buildInputDecorationTheme(
    Brightness brightness,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: brightness == Brightness.light
          ? const Color(0xFFF7FAFC)
          : const Color(0xFF2D3748),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: brightness == Brightness.light
              ? const Color(0xFFCBD5E0) // Darker border for better visibility
              : const Color(0xFF4A5568),
          width: brightness == Brightness.light ? 1.5 : 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: brightness == Brightness.light
              ? const Color(0xFFCBD5E0) // Darker border for better visibility
              : const Color(0xFF4A5568),
          width: brightness == Brightness.light ? 1.5 : 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: errorColor, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      labelStyle: TextStyle(
        fontSize: 14.0,
        color: brightness == Brightness.light
            ? const Color(0xFF4A5568)
            : const Color(0xFFA0AEC0),
      ),
      hintStyle: TextStyle(
        fontSize: 14.0,
        color: brightness == Brightness.light
            ? const Color(0xFFA0AEC0)
            : const Color(0xFF718096),
      ),
    );
  }

  /// Build bottom navigation bar theme
  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme(
    Brightness brightness,
  ) {
    return BottomNavigationBarThemeData(
      backgroundColor: brightness == Brightness.light
          ? Colors
                .white // White nav bar for better contrast
          : surfaceColor, // Teal background for dark theme
      selectedItemColor: primaryColor, // Teal
      unselectedItemColor: brightness == Brightness.light
          ? const Color(0xFF718096) // Medium gray for better visibility
          : const Color(0xFFA0AEC0), // Light gray for dark theme
      type: BottomNavigationBarType.fixed,
      elevation: brightness == Brightness.light ? 8 : 0,
      selectedLabelStyle: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12.0,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    );
  }

  /// Build divider theme
  static DividerThemeData _buildDividerTheme(Brightness brightness) {
    return DividerThemeData(
      color: brightness == Brightness.light
          ? const Color(0xFFCBD5E0) // Darker divider for better visibility
          : const Color(0xFF4A5568),
      thickness: brightness == Brightness.light ? 1.5 : 1,
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
