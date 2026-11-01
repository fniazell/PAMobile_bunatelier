import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../models/ai_recommendation_models.dart';
import '../providers/ai_recommendation_provider.dart';
import 'widgets/ai_header_app_bar.dart';

class AiPreferenceSelectionScreen extends ConsumerWidget {
  const AiPreferenceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(aiPreferencesProvider);
    final notifier = ref.read(aiPreferencesProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const AiHeaderAppBar(
        title: 'Preference Selection',
        brandTag: 'BUN ATELIER AI',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Matrix Tag
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'CURATION MATRIX / ISSUE NO. 04',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.coral,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Main Heading
              Text(
                'Tell us your cravings.',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forestGreen,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),

              // Supporting Text
              Text(
                "Set your preferences and we'll craft bespoke culinary pairings curated specifically for your palate.",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: AppColors.espresso.withValues(alpha: 0.8),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),

              // ── 01: YOUR BUDGET ───────────────────────────────────────────
              _buildSectionHeader('01', 'YOUR BUDGET', 'IDR / Per Serving'),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: BudgetRange.values.map((range) {
                      final isSelected = prefs.budget == range;
                      return SizedBox(
                        width: cardWidth,
                        child: _buildBudgetCard(
                          range: range,
                          isSelected: isSelected,
                          onTap: () => notifier.setBudget(range),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 22),

              // ── 02: FLAVOR PROFILE ─────────────────────────────────────────
              _buildSectionHeader('02', 'FLAVOR PROFILE', 'Multi-select'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FlavorProfile.values.map((flavor) {
                  final isSelected = prefs.flavors.contains(flavor);
                  return _buildFlavorChip(
                    flavor: flavor,
                    isSelected: isSelected,
                    onTap: () => notifier.toggleFlavor(flavor),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              // ── 03: SPICE INTENSITY ────────────────────────────────────────
              _buildSectionHeader('03', 'SPICE INTENSITY', 'Calibrated Heat'),
              const SizedBox(height: 10),
              Row(
                children: SpiceIntensity.values.map((spice) {
                  final isSelected = prefs.spice == spice;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buildSpiceCard(
                        spice: spice,
                        isSelected: isSelected,
                        onTap: () => notifier.setSpice(spice),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              // ── 04: PROTEIN CANVAS ─────────────────────────────────────────
              _buildSectionHeader('04', 'PROTEIN CANVAS', 'Signature Cuts'),
              const SizedBox(height: 10),
              Column(
                children: ProteinPreference.values.map((prot) {
                  final isSelected = prefs.protein == prot;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildProteinCard(
                      protein: prot,
                      isSelected: isSelected,
                      onTap: () => notifier.setProtein(prot),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Live Atelier Taste Match Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDEEE8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF5D5C8)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF0CBC0)),
                      ),
                      child: const Icon(Icons.psychology_outlined, color: AppColors.coral, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ATELIER TASTE MATCH',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: AppColors.coral,
                            ),
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              text: 'Based on ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: AppColors.espresso,
                                height: 1.35,
                              ),
                              children: [
                                TextSpan(
                                  text: prefs.budget.label,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F3D2E)),
                                ),
                                const TextSpan(text: ' & '),
                                TextSpan(
                                  text: prefs.protein.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F3D2E)),
                                ),
                                const TextSpan(text: ', our neural chef has locked 3 signature matches.'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Primary CTA Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Screen 3: AI Processing
                    context.push('/ai-recommendation/processing');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA62B2B),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'FIND MY BURGER',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Footer guarantee
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 13, color: AppColors.mutedText),
                    const SizedBox(width: 5),
                    Text(
                      'Calculated over 42 artisanal recipe matrices',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String number, String title, String tag) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              number,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.coral,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.forestGreen,
              ),
            ),
          ],
        ),
        Text(
          tag,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetCard({
    required BudgetRange range,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F3D2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F3D2E) : const Color(0xFFEADBCE),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    range.tier,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF6EE7B7) : AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    range.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.espresso,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFF6EE7B7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Color(0xFF0F3D2E)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlavorChip({
    required FlavorProfile flavor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F3D2E) : const Color(0xFFFFF9F5),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F3D2E) : const Color(0xFFEADBCE),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 13, color: Color(0xFF6EE7B7)),
              const SizedBox(width: 5),
            ],
            Text(
              flavor.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.espresso,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpiceCard({
    required SpiceIntensity spice,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    IconData icon;
    Color iconColor;
    switch (spice) {
      case SpiceIntensity.none:
        icon = Icons.sentiment_satisfied_rounded;
        iconColor = isSelected ? Colors.white : AppColors.mutedText;
        break;
      case SpiceIntensity.mild:
        icon = Icons.local_fire_department_rounded;
        iconColor = isSelected ? const Color(0xFFFDE68A) : const Color(0xFFF59E0B);
        break;
      case SpiceIntensity.medium:
        icon = Icons.local_fire_department_rounded;
        iconColor = isSelected ? const Color(0xFFF97316) : const Color(0xFFEA580C);
        break;
      case SpiceIntensity.hot:
        icon = Icons.local_fire_department_rounded;
        iconColor = isSelected ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F3D2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F3D2E) : const Color(0xFFEADBCE),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(height: 4),
            Text(
              spice.label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.espresso,
              ),
              maxLines: 1,
            ),
            Text(
              spice.subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8.5,
                color: isSelected ? const Color(0xFF6EE7B7) : AppColors.mutedText,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProteinCard({
    required ProteinPreference protein,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    IconData icon;
    switch (protein) {
      case ProteinPreference.beef:
        icon = Icons.restaurant_rounded;
        break;
      case ProteinPreference.chicken:
        icon = Icons.lunch_dining_rounded;
        break;
      case ProteinPreference.noPreference:
        icon = Icons.auto_awesome_rounded;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F3D2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F3D2E) : const Color(0xFFEADBCE),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF7EFE6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF6EE7B7) : AppColors.forestGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    protein.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    protein.subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFF6EE7B7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Color(0xFF0F3D2E)),
              ),
          ],
        ),
      ),
    );
  }
}
