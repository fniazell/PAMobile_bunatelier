import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/theme/app_colors.dart';
import '../models/ai_recommendation_models.dart';
import '../providers/ai_recommendation_provider.dart';
import 'widgets/ai_header_app_bar.dart';

class AiEditPreferencesScreen extends ConsumerStatefulWidget {
  const AiEditPreferencesScreen({super.key});

  @override
  ConsumerState<AiEditPreferencesScreen> createState() => _AiEditPreferencesScreenState();
}

class _AiEditPreferencesScreenState extends ConsumerState<AiEditPreferencesScreen> {
  late BudgetRange _selectedBudget;
  late Set<FlavorProfile> _selectedFlavors;
  late SpiceIntensity _selectedSpice;
  late ProteinPreference _selectedProtein;

  @override
  void initState() {
    super.initState();
    final current = ref.read(aiPreferencesProvider);
    _selectedBudget = current.budget;
    _selectedFlavors = Set.from(current.flavors);
    _selectedSpice = current.spice;
    _selectedProtein = current.protein;
  }

  void _showBudgetPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Budget Maksimal', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...BudgetRange.values.map((range) => ListTile(
              title: Text(range.displayRange, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              subtitle: Text(range.tier),
              trailing: _selectedBudget == range ? const Icon(Icons.check, color: AppColors.coral) : null,
              onTap: () {
                setState(() => _selectedBudget = range);
                Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showFlavorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pilih Karakter Rasa (Bisa Lebih dari 1)', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FlavorProfile.values.map((flavor) {
                  final isSelected = _selectedFlavors.contains(flavor);
                  return FilterChip(
                    label: Text(flavor.label),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0F3D2E),
                    checkmarkColor: const Color(0xFF6EE7B7),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.espresso,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      setModalState(() {
                        if (val) {
                          _selectedFlavors.add(flavor);
                        } else if (_selectedFlavors.length > 1) {
                          _selectedFlavors.remove(flavor);
                        }
                      });
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA62B2B)),
                  child: const Text('Simpan Pilihan', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSpicePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Level Pedas', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...SpiceIntensity.values.map((spice) => ListTile(
              title: Text(spice.label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              subtitle: Text(spice.tag),
              trailing: _selectedSpice == spice ? const Icon(Icons.check, color: AppColors.coral) : null,
              onTap: () {
                setState(() => _selectedSpice = spice);
                Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showProteinPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Tipe Daging', style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...ProteinPreference.values.map((prot) => ListTile(
              title: Text(prot.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              subtitle: Text(prot.subtitle),
              trailing: _selectedProtein == prot ? const Icon(Icons.check, color: AppColors.coral) : null,
              onTap: () {
                setState(() => _selectedProtein = prot);
                Navigator.pop(ctx);
              },
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const AiHeaderAppBar(
        title: 'Edit Preferences',
        brandTag: 'BUN ATELIER AI',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Configuration tag
              Text(
                'CONFIGURATION • FOLIO 07',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(height: 4),

              // Heading
              Text(
                'Ubah Preferensi',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 6),

              // Supporting Text
              Text(
                'Kamu bisa mengubah preferensi kulinermu untuk kurasi atelier rekomendasi yang paling tepat hari ini.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  color: AppColors.espresso.withValues(alpha: 0.8),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),

              // ── 4 Selection Rows / Cards ──────────────────────────────────
              // Card 1: Budget
              _buildPreferenceSelectionCard(
                icon: Icons.account_balance_wallet_outlined,
                iconBg: const Color(0xFFF3ECE0),
                label: 'BUDGET MAKSIMAL',
                value: _selectedBudget.displayRange,
                onTap: _showBudgetPicker,
              ),
              const SizedBox(height: 12),

              // Card 2: Flavor
              _buildPreferenceSelectionCard(
                icon: Icons.lunch_dining_outlined,
                iconBg: const Color(0xFFFDE68A),
                label: 'PREFERENSI RASA',
                value: _selectedFlavors.map((f) => f.tag).join(', '),
                onTap: _showFlavorPicker,
              ),
              const SizedBox(height: 12),

              // Card 3: Spice
              _buildPreferenceSelectionCard(
                icon: Icons.local_fire_department_outlined,
                iconBg: const Color(0xFFFEE2E2),
                label: 'LEVEL PEDAS',
                value: '${_selectedSpice.label} (${_selectedSpice.subtitle})',
                onTap: _showSpicePicker,
              ),
              const SizedBox(height: 12),

              // Card 4: Protein
              _buildPreferenceSelectionCard(
                icon: Icons.restaurant_outlined,
                iconBg: const Color(0xFFE5E7EB),
                label: 'PROTEIN PILIHAN',
                value: _selectedProtein.title,
                onTap: _showProteinPicker,
              ),
              const SizedBox(height: 16),

              // Sommelier AI Engine Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDEEE8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF5D5C8)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SOMMELIER AI ENGINE',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: const Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Resep brioche dipanggang fresh tiap 40 menit disesuaikan dengan tingkat umami & saus pilihanmu.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: AppColors.espresso,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Primary CTA: CARI REKOMENDASI
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Update riverpod preferences
                    ref.read(aiPreferencesProvider.notifier).updateAll(
                      budget: _selectedBudget,
                      flavors: _selectedFlavors,
                      spice: _selectedSpice,
                      protein: _selectedProtein,
                    );

                    // Re-route into Processing Screen -> Results Screen
                    context.pushReplacement('/ai-recommendation/processing');
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                  label: Text(
                    'CARI REKOMENDASI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA62B2B),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, size: 14, color: AppColors.coral),
                    const SizedBox(width: 4),
                    Text(
                      '4 preferensi siap disaring secara instan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceSelectionCard({
    required IconData icon,
    required Color iconBg,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF1E6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEADBCE)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.espresso),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: AppColors.mutedText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forestGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.espresso),
          ],
        ),
      ),
    );
  }
}
