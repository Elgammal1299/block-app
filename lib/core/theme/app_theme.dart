import 'package:flutter/material.dart';

class AppTheme {
  // Facebook-inspired Light Theme Colors
  static const Color _lightPrimaryColor = Color(0xFF1877F2); // Facebook Blue
  static const Color _lightSecondaryColor = Color(0xFF42B72A); // Facebook Green
  static const Color _lightBackgroundColor = Color(0xFFF0F2F5); // Facebook Light Gray
  static const Color _lightSurfaceColor = Colors.white;
  static const Color _lightErrorColor = Color(0xFFE4405F); // Facebook Red/Pink

  // Facebook-inspired Dark Theme Colors
  static const Color _darkPrimaryColor = Color(0xFF2D88FF); // Lighter Facebook Blue for dark
  static const Color _darkSecondaryColor = Color(0xFF42B72A); // Facebook Green
  static const Color _darkBackgroundColor = Color(0xFF000000); // Pure black for AMOLED
  static const Color _darkSurfaceColor = Color(0xFF1C1C1E); // Better contrast on pure black
  static const Color _darkErrorColor = Color(0xFFE4405F); // Facebook Red/Pink

  // ============================================
  // DESIGN TOKENS - Unified Spacing & Sizing
  // ============================================

  // Spacing Scale
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // Border Radius Scale
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;

  // Elevation Scale
  static const double elevation0 = 0.0;
  static const double elevation1 = 2.0;
  static const double elevation2 = 4.0;
  static const double elevation3 = 8.0;

  // Icon Container Sizing
  static const double iconContainerSmall = 40.0;
  static const double iconContainerMedium = 48.0;
  static const double iconContainerLarge = 56.0;

  // ============================================
  // SEMANTIC COLORS (Limited Palette)
  // ============================================

  static const Color accentSuccess = Color(0xFF42B72A); // Same as secondary
  static const Color accentWarning = Color(0xFFFF9800); // Orange
  static const Color accentInfo = Color(0xFF2D88FF);    // Same as dark primary

  // Light Theme - Facebook Style
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: _lightPrimaryColor,
        secondary: _lightSecondaryColor,
        surface: _lightSurfaceColor,
        error: _lightErrorColor,
      ),
      scaffoldBackgroundColor: _lightBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: _lightSurfaceColor, // White AppBar like Facebook
        foregroundColor: Color(0xFF050505), // Almost black text
        elevation: 0, // Flat design like Facebook
        centerTitle: false, // Facebook style - left aligned
        shadowColor: Color(0x0A000000), // Subtle shadow
      ),
      cardTheme: CardThemeData(
        color: _lightSurfaceColor,
        elevation: 0, // Flat cards like Facebook
        shadowColor: const Color(0x0A000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          side: BorderSide(
            color: Colors.grey.shade300,
            width: 0.5,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _lightPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0, // Flat buttons like Facebook
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _lightPrimaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _lightPrimaryColor;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _lightPrimaryColor.withValues(alpha: 0.5);
          }
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _lightPrimaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 0.5,
        space: 1,
      ),
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lightSurfaceColor,
        selectedItemColor: _lightPrimaryColor,
        unselectedItemColor: Color(0xFF65676B), // Facebook gray
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // Dark Theme - Facebook Dark Mode Style
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: _darkPrimaryColor,
        secondary: _darkSecondaryColor,
        surface: _darkSurfaceColor,
        error: _darkErrorColor,
      ),
      scaffoldBackgroundColor: _darkBackgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkSurfaceColor,
        foregroundColor: Color(0xFFE4E6EB), // Facebook light text
        elevation: 0,
        centerTitle: false,
        shadowColor: Color(0x1A000000),
      ),
      cardTheme: CardThemeData(
        color: _darkSurfaceColor,
        elevation: 0,
        shadowColor: const Color(0x1A000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _darkPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _darkPrimaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _darkPrimaryColor;
          }
          return Colors.grey.shade600;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _darkPrimaryColor.withValues(alpha: 0.5);
          }
          return Colors.grey.withValues(alpha: 0.3);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2E), // Better contrast on pure black
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkPrimaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade800,
        thickness: 0.5,
        space: 1,
      ),
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurfaceColor,
        selectedItemColor: _darkPrimaryColor,
        unselectedItemColor: Color(0xFFB0B3B8), // Facebook light gray
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      // Text Theme for dark mode - Enhanced for pure black background
      textTheme: const TextTheme(
        // Headings - Pure white for maximum contrast
        displayLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w800),
        displayMedium: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w700),
        displaySmall: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600),

        // Titles - Very light gray
        titleLarge: TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: Color(0xFFF5F5F5), fontWeight: FontWeight.w500),

        // Body text - Enhanced for pure black
        bodyLarge: TextStyle(color: Color(0xFFE8E8E8)),
        bodyMedium: TextStyle(color: Color(0xFFE8E8E8)),
        bodySmall: TextStyle(color: Color(0xFFB8B8B8)),

        // Labels
        labelLarge: TextStyle(color: Color(0xFFC8C8C8)),
        labelMedium: TextStyle(color: Color(0xFFC8C8C8)),
        labelSmall: TextStyle(color: Color(0xFFB8B8B8)),
      ),
    );
  }
}
