import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrikTheme {
  // Brand Color Palette — Warm Apricot Coral (#EB935C) & Mitrai Navy (#063B5C)
  static const Color canvasBackground = Color(0xFFF7F4EC); // Warm luxury cream canvas
  static const Color cardSurface = Color(0xFFEB935C);      // Brand Apricot Coral #EB935C
  static const Color cardSurfaceSecondary = Color(0xFFD97E45); // Deeper apricot coral
  static const Color cardBorder = Color(0xFFF4A776);       // Warm coral stroke
  static const Color brandNavy = Color(0xFF063B5C);        // Mitrai Deep Navy #063B5C
  static const Color brandNavyLight = Color(0xFF135882);   // Muted Navy Accent
  static const Color brandMint = Color(0xFF063B5C);        // Fallback pointing to Brand Navy

  // Accents
  static const Color accentLavender = Color(0xFF063B5C);   // Mitrai Navy for contrast highlights
  static const Color accentLavenderLight = Color(0xFFEAF2F7); // Soft slate cream tint
  static const Color accentGreen = Color(0xFF063B5C);      // Brand Navy for success & verification
  static const Color accentCoral = Color(0xFFEB935C);      // Brand warm coral highlight

  // Mixed Text Colors on #EB935C
  static const Color textPrimaryOnDark = Color(0xFF063B5C);   // Mitrai Navy for prominent headlines & labels
  static const Color textSecondaryOnDark = Color(0xFF205273); // Muted slate navy for subtitles
  static const Color textWhiteOnDark = Color(0xFFFFFFFF);     // Crisp white for numbers, prices & badges
  static const Color textPrimaryOnLight = Color(0xFF063B5C);  // Deep navy on cream canvas
  static const Color textSecondaryOnLight = Color(0xFF5A7990);// Muted Slate

  // ThemeData
  static ThemeData get themeData {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      scaffoldBackgroundColor: canvasBackground,
      primaryColor: cardSurface,
      colorScheme: const ColorScheme.light(
        primary: cardSurface,
        secondary: brandNavy,
        surface: canvasBackground,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textPrimaryOnDark,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: textPrimaryOnDark,
          letterSpacing: -0.5,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryOnDark,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryOnDark,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: textPrimaryOnDark,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondaryOnDark,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: cardSurface),
      ),
    );
  }
}
