import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryGreen = Color(0xFF1DB954);
  static const Color darkGreen = Color(0xFF158a3e);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentPink = Color(0xFFEC4899);

  // Dark Theme Colors
  static const Color darkBg = Color(0xFF0A0A0F);
  static const Color darkSurface = Color(0xFF12121A);
  static const Color darkCard = Color(0xFF1A1A25);
  static const Color darkElevated = Color(0xFF222233);
  static const Color darkBorder = Color(0xFF2A2A3D);

  // Light Theme Colors
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0F1F3);

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: primaryGreen,
          secondary: accentPurple,
          surface: darkSurface,
          background: darkBg,
          onBackground: Colors.white,
          onSurface: Colors.white,
          onPrimary: Colors.black,
        ),
        scaffoldBackgroundColor: darkBg,
        cardColor: darkCard,
        fontFamily: 'Circular',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5),
          displayMedium: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3),
          headlineLarge: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600),
          titleLarge: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600),
          titleMedium: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
          bodyMedium: TextStyle(color: Color(0xFF8A8A8A), fontSize: 12),
          labelLarge: TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: darkSurface,
          selectedItemColor: primaryGreen,
          unselectedItemColor: Color(0xFF6B6B6B),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 1.5),
          ),
          hintStyle: const TextStyle(color: Color(0xFF6B6B6B)),
          prefixIconColor: const Color(0xFF6B6B6B),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: primaryGreen,
          inactiveTrackColor: darkBorder,
          thumbColor: Colors.white,
          overlayColor: primaryGreen.withOpacity(0.2),
          trackHeight: 3,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        dividerColor: darkBorder,
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: primaryGreen,
          secondary: accentPurple,
          surface: lightSurface,
          background: lightBg,
        ),
        scaffoldBackgroundColor: lightBg,
        fontFamily: 'Circular',
      );

  // Gradient presets
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGreen, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [darkBg, darkSurface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
