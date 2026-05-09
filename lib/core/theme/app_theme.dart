import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF10B981);
  static const Color darkBackground = Color(0xFF061A17);
  static const Color darkSurface = Color(0xFF0F2A25);

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF064E3B),
      elevation: 0,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      surface: darkSurface,
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: darkBackground),
    cardColor: darkSurface,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primary,
      unselectedItemColor: Color(0xFF94A3B8),
    ),
  );
}
