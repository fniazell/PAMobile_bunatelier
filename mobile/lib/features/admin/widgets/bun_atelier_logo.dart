import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/admin_colors.dart';

enum LogoVariant {
  horizontal,
  sidebar,
  compact,
  symbol,
}

class BunAtelierLogo extends StatelessWidget {
  final LogoVariant variant;
  final double size;
  final Color? primaryColor;
  final Color? accentColor;
  final Color? textColor;
  final String? customTagline;

  const BunAtelierLogo({
    super.key,
    this.variant = LogoVariant.horizontal,
    this.size = 38,
    this.primaryColor,
    this.accentColor,
    this.textColor,
    this.customTagline,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? AdminColors.burgundy;
    final accent = accentColor ?? AdminColors.sandBeige;
    final text = textColor ?? AdminColors.darkBrown;
    final tagline = customTagline ?? 'CRAFTED TO CRAVE';

    final symbolWidget = _buildArtisanSymbol(primary, accent);

    switch (variant) {
      case LogoVariant.symbol:
        return symbolWidget;

      case LogoVariant.compact:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            symbolWidget,
            const SizedBox(width: 10),
            Text(
              'BUN ATELIER',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: size * 0.48,
                letterSpacing: 1.8,
                color: text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );

      case LogoVariant.sidebar:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                symbolWidget,
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BUN ATELIER',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 16,
                        letterSpacing: 1.8,
                        color: text,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tagline,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AdminColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

      case LogoVariant.horizontal:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            symbolWidget,
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BUN ATELIER',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 17,
                    letterSpacing: 2.0,
                    color: primary,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                Text(
                  'ADMIN CONSOLE • $tagline',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: AdminColors.mutedText,
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildArtisanSymbol(Color primary, Color accent) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Inner subtle border
            Container(
              margin: EdgeInsets.all(size * 0.08),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.2),
                border: Border.all(
                  color: accent.withValues(alpha: 0.35),
                  width: 1.0,
                ),
              ),
            ),
            // Distinct artisan burger icon
            Icon(
              Icons.lunch_dining_rounded,
              color: accent,
              size: size * 0.58,
            ),
          ],
        ),
      ),
    );
  }
}
