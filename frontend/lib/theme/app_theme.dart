import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Define Core Colors
  static const Color background = Color(0xFF121212); // Deep Charcoal
  static const Color surface = Color(0xFF1E1E1E); // Lighter grey for cards
  static const Color mistyGreen = Color(0xFF81C784); // Healthy/Stable
  static const Color harshAmber = Color(0xFFFFB300); // Warning
  static const Color neonRed = Color(0xFFFF1744); // Critical

  static const Color textPrimary = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFF9E9E9E);

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: mistyGreen,
      secondary: harshAmber,
      error: neonRed,
      surface: surface,
      background: background,
      onPrimary: Colors.black, // contrast color
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 64, fontWeight: FontWeight.bold, color: textPrimary, height: 1.0), // Massive metrics
      displayMedium: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.bold, color: textPrimary),
      headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w600, color: textPrimary),
      titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: textPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondary),
      labelSmall: GoogleFonts.inter(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
    ),
    cardColor: surface,
    cardTheme: CardThemeData(
      color: surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      shadowColor: Colors.black45,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: background,
      selectedItemColor: mistyGreen,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
