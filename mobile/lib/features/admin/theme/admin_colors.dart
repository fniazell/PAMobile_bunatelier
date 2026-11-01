import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminColors {
  // Official Bun Atelier Admin Palette
  static const Color burgundy = Color(0xFF702D3A);   // Primary CTA, active nav, brand emphasis
  static const Color sandBeige = Color(0xFFE8D9C5);  // Stat cards & secondary panels
  static const Color warmWhite = Color(0xFFF8F4EC);  // Scaffold background
  static const Color darkBrown = Color(0xFF302421);  // Primary text & dark accents

  // Supporting Surfaces & Borders
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE4D8C8);
  static const Color mutedText = Color(0xFF7C6E66);
  static const Color divider = Color(0xFFEFE6D9);

  // Status & Alert Colors
  static const Color success = Color(0xFF2E7D32);    // Completed / Stock OK
  static const Color warning = Color(0xFFD97706);    // Low stock / Preparing
  static const Color error = Color(0xFFB91C1C);      // Out of stock / Cancelled
  static const Color info = Color(0xFF2563EB);       // Confirmed / General Info
  static const Color purple = Color(0xFF7C3AED);     // Ready for pickup

  // Operational Status Backgrounds
  static const Color statusPendingBg = Color(0xFFFEF3C7);
  static const Color statusPendingText = Color(0xFF92400E);

  static const Color statusConfirmedBg = Color(0xFFDBEAFE);
  static const Color statusConfirmedText = Color(0xFF1E40AF);

  static const Color statusPreparingBg = Color(0xFFFFEDD5);
  static const Color statusPreparingText = Color(0xFFC2410C);

  static const Color statusReadyBg = Color(0xFFF3E8FF);
  static const Color statusReadyText = Color(0xFF6B21A8);

  static const Color statusCompletedBg = Color(0xFFDCFCE7);
  static const Color statusCompletedText = Color(0xFF166534);

  static const Color statusCancelledBg = Color(0xFFFEE2E2);
  static const Color statusCancelledText = Color(0xFF991B1B);

  // Typography Styles
  static TextStyle serifHeading({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.bold,
    Color color = darkBrown,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.dmSerifDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing ?? 0.5,
    );
  }

  static TextStyle sansUI({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w600,
    Color color = darkBrown,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }
}
