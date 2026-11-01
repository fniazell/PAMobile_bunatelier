import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'menu_tokens.dart';

class AtelierSecretCard extends StatelessWidget {
  const AtelierSecretCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 24),
      decoration: BoxDecoration(
        color: MenuTokens.deepGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: MenuTokens.deepGreen.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Subtle radial glow in bottom-right corner
            Positioned(
              right: -30,
              bottom: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1B634C).withValues(alpha: 0.6),
                      MenuTokens.deepGreen.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Eyebrow
                  Text(
                    'ATELIER SECRET',
                    style: MenuTokens.sansUI(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: MenuTokens.butterYellow,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Headline
                  Text(
                    'Laminated Buns,\nZero Compromises.',
                    style: MenuTokens.serifHeading(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.18,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    'Crafted daily with French cultured butter and a 36-hour slow fermentation technique.',
                    style: MenuTokens.sansUI(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Coral Pill Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => context.push('/custom-burger'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: MenuTokens.coral,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: MenuTokens.coral.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'DISCOVER HOW →',
                              style: MenuTokens.sansUI(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
