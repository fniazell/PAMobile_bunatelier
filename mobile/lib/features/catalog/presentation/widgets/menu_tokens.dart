import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuTokens {
  // Brand palette matching target editorial design
  static const Color background = Color(0xFFFFF5F0);     // Warm blush cream background
  static const Color cardSurface = Color(0xFFFFF9F6);    // Lighter cream card surface
  static const Color deepGreen = Color(0xFF0F3D2E);      // Primary deep forest green
  static const Color coral = Color(0xFFFF6B57);          // Vibrant coral accent
  static const Color butterYellow = Color(0xFFFBDF8A);   // Warm vintage butter yellow
  static const Color pricePillBg = Color(0xFFFFE3DA);    // Light peach price pill background
  static const Color borderLight = Color(0xFFEADBCE);    // Light warm border
  static const Color mutedText = Color(0xFF6B5E55);      // Muted brown text
  static const Color activeNavHalo = Color(0xFFFFE5DE);  // Soft coral halo for active tab

  // Typography - Playfair Display (Serif)
  static TextStyle serifHeading({
    double fontSize = 20,
    FontWeight fontWeight = FontWeight.bold,
    Color color = deepGreen,
    FontStyle fontStyle = FontStyle.normal,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontStyle: fontStyle,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Typography - Plus Jakarta Sans (UI & Body)
  static TextStyle sansUI({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.normal,
    Color color = mutedText,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
