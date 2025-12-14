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
  static const Color _darkBackgroundColor = Color(0xFF18191A); // Facebook Dark Gray
  static const Color _darkSurfaceColor = Color(0xFF242526); // Facebook Card Dark
  static const Color _darkErrorColor = Color(0xFFE4405F); // Facebook Red/Pink

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
          borderRadius: BorderRadius.circular(8),
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
            borderRadius: BorderRadius.circular(6), // Facebook button radius
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
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: Colors.grey.shade800,
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
            borderRadius: BorderRadius.circular(6),
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
        fillColor: const Color(0xFF3A3B3C), // Facebook dark input
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
      // Text Theme for dark mode
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFE4E6EB)),
        bodyMedium: TextStyle(color: Color(0xFFE4E6EB)),
        bodySmall: TextStyle(color: Color(0xFFB0B3B8)),
      ),
    );
  }
}
