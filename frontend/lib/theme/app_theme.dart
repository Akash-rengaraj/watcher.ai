import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Define Core Colors (Stitch Light Mode)
  static const Color primary = Color(0xFF1A2A47); // Navy Blue
  static const Color background = Color(0xFFF6F7F8); // Light Grey
  static const Color surface = Color(0xFFFFFFFF); // White Cards
  static const Color mistyGreen = Color(0xFF81C784); // Healthy/Stable
  static const Color harshAmber = Color(0xFFFFB300); // Warning
  static const Color neonRed = Color(0xFFFF1744); // Critical

  static const Color textPrimary = Color(0xFF0F172A); // slate-900 (Dark text on light bg)
  static const Color textSecondary = Color(0xFF64748B); // slate-500 (Muted text)

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: background,
    primaryColor: primary,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: mistyGreen,
      error: neonRed,
      surface: surface,
      onPrimary: Colors.white,
      onSurface: textPrimary,
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.light().textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 64, fontWeight: FontWeight.bold, color: textPrimary, height: 1.0),
      displayMedium: GoogleFonts.inter(fontSize: 48, fontWeight: FontWeight.bold, color: textPrimary),
      headlineLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w600, color: textPrimary),
      titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
      titleMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: textPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondary),
      labelSmall: GoogleFonts.inter(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500),
    ),
    cardColor: surface,
    cardTheme: CardThemeData(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Stitch ROUND_TWELVE
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1), // slate-200 border
      ),
      elevation: 0, // Flat cards in this design
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      iconTheme: IconThemeData(color: primary),
      titleTextStyle: TextStyle(color: primary, fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}
