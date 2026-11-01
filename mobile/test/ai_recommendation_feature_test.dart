import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/ai_recommendation/models/ai_recommendation_models.dart';
import 'package:mobile/features/ai_recommendation/providers/ai_recommendation_provider.dart';
import 'package:mobile/features/ai_recommendation/presentation/ai_preference_selection_screen.dart';
import 'package:mobile/features/ai_recommendation/presentation/ai_recommendation_results_screen.dart';

void main() {
  group('AI Recommendation Engine & Models Unit Tests', () {
    test('Default preferences match expected values', () {
      const prefs = AiUserPreferences();
      expect(prefs.budget, BudgetRange.between30kAnd50k);
      expect(prefs.flavors.contains(FlavorProfile.smokySavory), true);
      expect(prefs.spice, SpiceIntensity.medium);
      expect(prefs.protein, ProteinPreference.beef);
    });

    test('AiRecommendationEngine evaluates beef preferences accurately', () {
      const prefs = AiUserPreferences(
        budget: BudgetRange.between50kAnd75k,
        flavors: {FlavorProfile.smokySavory, FlavorProfile.fieryPepper},
        spice: SpiceIntensity.medium,
        protein: ProteinPreference.beef,
      );

      final result = AiRecommendationEngine.evaluate(prefs);

      expect(result.bestMatch.isBestMatch, isTrue);
      expect(result.bestMatch.matchScore, 98.4);
      expect(result.bestMatch.product.name.isNotEmpty, isTrue);
      expect(result.alternatives.length, greaterThanOrEqualTo(2));
      expect(result.alternatives.first.matchScore, greaterThanOrEqualTo(90.0));
    });

    test('AiRecommendationEngine evaluates chicken preferences to chicken product', () {
      const prefs = AiUserPreferences(
        budget: BudgetRange.between50kAnd75k,
        flavors: {FlavorProfile.sweetTangy},
        spice: SpiceIntensity.mild,
        protein: ProteinPreference.chicken,
      );

      final result = AiRecommendationEngine.evaluate(prefs);

      expect(result.bestMatch.product.name, contains('Crunch Culture'));
      expect(result.bestMatch.specs['PATTY'], contains('Chicken'));
    });

    test('AiPreferencesNotifier correctly toggles and updates preferences', () {
      final notifier = AiPreferencesNotifier();

      notifier.setBudget(BudgetRange.above75k);
      expect(notifier.state.budget, BudgetRange.above75k);

      notifier.setSpice(SpiceIntensity.hot);
      expect(notifier.state.spice, SpiceIntensity.hot);

      notifier.setProtein(ProteinPreference.chicken);
      expect(notifier.state.protein, ProteinPreference.chicken);

      notifier.toggleFlavor(FlavorProfile.cheesy);
      expect(notifier.state.flavors.contains(FlavorProfile.cheesy), isTrue);
    });
  });

  group('AI Recommendation UI Widget Tests', () {
    testWidgets('AiPreferenceSelectionScreen renders all 4 sections and CTA', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AiPreferenceSelectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tell us your cravings.'), findsOneWidget);
      expect(find.text('YOUR BUDGET'), findsOneWidget);
      expect(find.text('FLAVOR PROFILE'), findsOneWidget);
      expect(find.text('SPICE INTENSITY'), findsOneWidget);
      expect(find.text('PROTEIN CANVAS'), findsOneWidget);
      expect(find.text('FIND MY BURGER'), findsOneWidget);
      expect(find.text('ATELIER TASTE MATCH'), findsOneWidget);
    });

    testWidgets('AiRecommendationResultsScreen renders Best Match card and CTAs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AiRecommendationResultsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your Perfect Match!'), findsOneWidget);
      expect(find.text('BEST MATCH'), findsOneWidget);
      expect(find.text('LIHAT DETAIL MENU'), findsOneWidget);
      expect(find.text('COBA REKOMENDASI LAIN'), findsOneWidget);
      expect(find.textContaining('ALTERNATIVE BUNS', findRichText: true), findsOneWidget);
    });
  });
}
