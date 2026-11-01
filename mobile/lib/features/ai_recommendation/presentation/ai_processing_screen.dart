import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../providers/ai_recommendation_provider.dart';
import 'widgets/ai_header_app_bar.dart';

class AiProcessingScreen extends ConsumerStatefulWidget {
  const AiProcessingScreen({super.key});

  @override
  ConsumerState<AiProcessingScreen> createState() => _AiProcessingScreenState();
}

class _AiProcessingScreenState extends ConsumerState<AiProcessingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  Timer? _stepTimer;
  Timer? _completeTimer;

  int _currentStep = 0;
  final List<String> _tickerMessages = [
    'Matching smoked bone-marrow glaze to your palate...',
    'Verifying dry-aged sear index & brioche moisture...',
    'Calibrating 42 artisanal recipe matrices...',
    'Curating bespoke pairing with signature condiments...',
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();

    _stepTimer = Timer.periodic(const Duration(milliseconds: 650), (timer) {
      if (mounted && _currentStep < _tickerMessages.length - 1) {
        setState(() => _currentStep++);
      }
    });

    // Automatically navigate to Screen 4 (Results) after processing completes
    _completeTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        // Re-evaluate recommendations
        final prefs = ref.read(aiPreferencesProvider);
        ref.read(aiRecommendationResultProvider.notifier).state =
            AiRecommendationEngine.evaluate(prefs);

        context.pushReplacement('/ai-recommendation/results');
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _stepTimer?.cancel();
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const AiHeaderAppBar(
        title: 'Ai Processing',
        brandTag: 'BUN ATELIER AI',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Engine Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8DF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF3C7B6)),
                  ),
                  child: Text(
                    'SOMMELIER ENGINE V2.4',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.coral,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Center Mascot Illustration Frame
              Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: 170,
                    height: 170,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EFE6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE8DACB), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        'assets/images/splash/splash_frame_1.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA62B2B),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'NO. 07 ATELIER',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Main Heading
              Text(
                'Our AI is finding your\nperfect bun...',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forestGreen,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),

              // Supporting Text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Analyzing menu cuts, brioche moisture, and your taste profile to craft the ultimate bespoke order.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.espresso.withValues(alpha: 0.75),
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4 Progress Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isActive = index <= _currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFA62B2B) : const Color(0xFFE5D5C5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Ticker Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF1E6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEEDBCC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.soup_kitchen_outlined, size: 16, color: Color(0xFFA62B2B)),
                            const SizedBox(width: 8),
                            Text(
                              'SENOPATI GRILL & LARDER TICKER',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: const Color(0xFFA62B2B),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${((_currentStep + 1) * 23 + 6).clamp(0, 98)}%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFA62B2B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (_currentStep + 1) / 4,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFEADBCE),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFA62B2B)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.coral),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _tickerMessages[_currentStep],
                              key: ValueKey<int>(_currentStep),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.espresso,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Two Stat Cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.local_fire_department_outlined,
                      label: 'SEAR INDEX',
                      title: 'Caramelized',
                      subtitle: 'Dry-aged crust lock',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricTile(
                      icon: Icons.bakery_dining_outlined,
                      label: 'BUN TEXTURE',
                      title: 'Ultra-Pillowy',
                      subtitle: 'Triple-fermented butter',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bottom Quote
              Text(
                '"Every millimeter weighed. Worth every drop of mess."',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 12.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADBCE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.coral),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppColors.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppColors.forestGreen,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
