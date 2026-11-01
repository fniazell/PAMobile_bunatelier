import 'package:flutter/material.dart';

class AppColors {
  // Brand Palette exactly matching Bun Atelier editorial magazine design
  static const Color cream = Color(0xFFFBF6EE);          // Warm paper cream background
  static const Color coral = Color(0xFFE85D43);          // Warm coral / terracotta
  static const Color forestGreen = Color(0xFF1C3B2B);    // Deep vintage forest green
  static const Color espresso = Color(0xFF2C1E1A);       // Dark roasted espresso
  static const Color butterYellow = Color(0xFFF5D98B);    // Warm vintage butter yellow

  // Bun Atelier Identity Colors
  static const Color burgundy = Color(0xFF702D3A);       // Deep elegant burgundy
  static const Color sandBeige = Color(0xFFE8D9C5);      // Soft sand beige
  static const Color warmWhite = Color(0xFFF8F4EC);      // Warm paper white
  static const Color darkBrown = Color(0xFF302421);      // Deep roasted dark brown

  // Supporting Neutrals & Surfaces
  static const Color creamDarker = Color(0xFFF3E8D8);
  static const Color white = Color(0xFFFFFFFF);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE6DCce);
  static const Color mutedText = Color(0xFF7A6E65);
  static const Color darkTile = Color(0xFF2B1D19);
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);

  // Dark Theme Palette
  static const Color darkScaffold = Color(0xFF15100E);
  static const Color darkCard = Color(0xFF231916);
  static const Color darkBorder = Color(0xFF382A24);
  static const Color darkMuted = Color(0xFFA5978F);
  static const Color forestGreenLight = Color(0xFF3E755B);

  // Dynamic Theme-Aware Helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkCard : white;

  static Color background(BuildContext context) =>
      isDark(context) ? darkScaffold : cream;

  static Color text(BuildContext context) =>
      isDark(context) ? cream : espresso;

  static Color subtext(BuildContext context) =>
      isDark(context) ? darkMuted : mutedText;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : borderLight;
}
