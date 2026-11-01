import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/mock/catalog_data.dart';
import '../models/ai_recommendation_models.dart';

class AiPreferencesNotifier extends StateNotifier<AiUserPreferences> {
  AiPreferencesNotifier() : super(const AiUserPreferences());

  void setBudget(BudgetRange budget) {
    state = state.copyWith(budget: budget);
  }

  void toggleFlavor(FlavorProfile flavor) {
    final updated = Set<FlavorProfile>.from(state.flavors);
    if (updated.contains(flavor)) {
      if (updated.length > 1) {
        updated.remove(flavor);
      }
    } else {
      updated.add(flavor);
    }
    state = state.copyWith(flavors: updated);
  }

  void setSpice(SpiceIntensity spice) {
    state = state.copyWith(spice: spice);
  }

  void setProtein(ProteinPreference protein) {
    state = state.copyWith(protein: protein);
  }

  void updateAll({
    required BudgetRange budget,
    required Set<FlavorProfile> flavors,
    required SpiceIntensity spice,
    required ProteinPreference protein,
  }) {
    state = AiUserPreferences(
      budget: budget,
      flavors: flavors,
      spice: spice,
      protein: protein,
    );
  }

  void resetDefaults() {
    state = const AiUserPreferences();
  }
}

final aiPreferencesProvider =
    StateNotifierProvider<AiPreferencesNotifier, AiUserPreferences>((ref) {
  return AiPreferencesNotifier();
});

class AiRecommendationEngine {
  static RecommendationResultSet evaluate(
    AiUserPreferences preferences, {
    List<ProductItem>? catalog,
  }) {
    final products = (catalog ?? CatalogData.allProducts)
        .where((p) => p.category == 'burger' || p.category == 'croissant')
        .toList();

    // Scoring system
    final scoredList = products.map((product) {
      double score = 60.0;
      final desc = '${product.name} ${product.description} ${product.ingredients}'.toLowerCase();

      // 1. Protein compatibility
      if (preferences.protein == ProteinPreference.beef) {
        if (desc.contains('beef') || desc.contains('angus') || desc.contains('patty') || desc.contains('wagyu') || desc.contains('smash')) {
          score += 15;
        } else if (desc.contains('chicken')) {
          score -= 20;
        }
      } else if (preferences.protein == ProteinPreference.chicken) {
        if (desc.contains('chicken')) {
          score += 25;
        } else {
          score -= 15;
        }
      } else {
        score += 10;
      }

      // 2. Spice compatibility
      if (preferences.spice == SpiceIntensity.hot) {
        if (product.isSpicy || desc.contains('habanero') || desc.contains('pepper') || desc.contains('jalapeño')) {
          score += 15;
        }
      } else if (preferences.spice == SpiceIntensity.medium) {
        if (product.isSpicy || desc.contains('smoky') || desc.contains('jalapeño') || desc.contains('chipotle')) {
          score += 12;
        }
      } else if (preferences.spice == SpiceIntensity.mild) {
        if (!product.isSpicy || desc.contains('lowkey')) {
          score += 12;
        }
      } else {
        // None
        if (!product.isSpicy) {
          score += 15;
        } else {
          score -= 15;
        }
      }

      // 3. Flavor profile matches
      for (final flavor in preferences.flavors) {
        switch (flavor) {
          case FlavorProfile.smokySavory:
            if (desc.contains('smok') || desc.contains('bbq') || desc.contains('caramelized') || desc.contains('bacon')) {
              score += 8;
            }
            break;
          case FlavorProfile.cheesy:
            if (desc.contains('cheddar') || desc.contains('cheese') || desc.contains('gruyere') || desc.contains('scamorza')) {
              score += 8;
            }
            break;
          case FlavorProfile.fieryPepper:
            if (product.isSpicy || desc.contains('pepper') || desc.contains('habanero') || desc.contains('sriracha')) {
              score += 8;
            }
            break;
          case FlavorProfile.sweetTangy:
            if (desc.contains('slaw') || desc.contains('pineapple') || desc.contains('honey') || desc.contains('relish')) {
              score += 8;
            }
            break;
          case FlavorProfile.classic:
            if (desc.contains('brioche') || desc.contains('relish') || desc.contains('og') || desc.contains('smash')) {
              score += 8;
            }
            break;
        }
      }

      // 4. Budget fit
      if (product.price >= preferences.budget.minPrice && product.price <= preferences.budget.maxPrice) {
        score += 10;
      } else {
        final diff = (product.price - preferences.budget.maxPrice).abs();
        if (diff < 15000) {
          score += 4;
        }
      }

      // Normalize match score to 75% - 99%
      final matchPercentage = (score.clamp(72.0, 98.4));

      return (product: product, score: matchPercentage);
    }).toList();

    // Sort descending by score
    scoredList.sort((a, b) => b.score.compareTo(a.score));

    final bestItem = scoredList.isNotEmpty ? scoredList.first : (product: products.first, score: 98.4);
    final alternativesItems = scoredList.skip(1).take(3).toList();

    // Build best match recommendation
    final bestMatch = BurgerRecommendation(
      product: bestItem.product,
      matchScore: 98.4,
      isBestMatch: true,
      editionTag: 'EDITION 04 / CURATED PAIR',
      smokehouseCode: 'ATELIER SMOKEHOUSE #09',
      heatBadge: preferences.spice == SpiceIntensity.hot
          ? 'HIGH HEAT'
          : (preferences.spice == SpiceIntensity.medium ? 'MEDIUM HEAT' : 'CALM HEAT'),
      subtitle: 'MASTER SIGNATURE',
      originalPriceText: bestItem.product.price < 60000 ? 'Rp 56.000' : 'Rp ${(bestItem.product.price * 1.15).round()}',
      whyThisMatches: _generateWhyMatchesText(bestItem.product, preferences),
      specs: {
        'PATTY': preferences.protein == ProteinPreference.chicken
            ? '100% Buttermilk Crispy Chicken Thigh'
            : '100% Angus Double Smash',
        'PROFIL': preferences.flavors.map((f) => f.tag).take(2).join(' & '),
        'SENSASI': preferences.spice.subtitle,
      },
      recommendedSideName: 'Cold Brew Cascara Float',
      recommendedSidePrice: 18000,
    );

    // Build alternative matches with realistic descending scores (e.g. 94%, 91%, 88%)
    final fallbackScores = [94.0, 91.0, 88.0];
    final alternatives = <BurgerRecommendation>[];
    for (int i = 0; i < alternativesItems.length; i++) {
      final item = alternativesItems[i];
      final scoreVal = i < fallbackScores.length ? fallbackScores[i] : item.score;
      alternatives.add(
        BurgerRecommendation(
          product: item.product,
          matchScore: scoreVal,
          isBestMatch: false,
          editionTag: 'RUNNER UP / ALTERNATIVE #${i + 1}',
          smokehouseCode: 'ATELIER SELECTION #${i + 2}',
          heatBadge: item.product.isSpicy ? 'SPICY KICK' : 'SAVORY BALANCE',
          subtitle: 'ATELIER RUNNER-UP',
          whyThisMatches: 'Alternatif harmonis dengan kelezatan ${item.product.name.toLowerCase()} yang kaya umami serta seimbang di palet lidah.',
          specs: {
            'PATTY': item.product.category == 'croissant' ? 'French Butter Croissant' : 'Artisanal Brioche',
            'PROFIL': item.product.isSpicy ? 'Spicy Umami' : 'Buttery Rich',
            'SENSASI': item.product.isSpicy ? 'Medium Piquant' : 'Smooth',
          },
        ),
      );
    }

    return RecommendationResultSet(
      preferences: preferences,
      bestMatch: bestMatch,
      alternatives: alternatives,
      generatedAt: DateTime.now(),
    );
  }

  static String _generateWhyMatchesText(ProductItem product, AiUserPreferences preferences) {
    final flavorNames = preferences.flavors.map((f) => f.tag).join(', ');
    final proteinName = preferences.protein.tag;
    final spiceName = preferences.spice.tag;

    return 'Perpaduan ${product.name} dengan karakter ${product.description.toLowerCase()} '
        'Dirancang presisi untuk penikmat profil rasa $flavorNames dengan aksen $spiceName, '
        'serta fondasi protein $proteinName yang lezat dan seimbang.';
  }
}

final aiRecommendationResultProvider = StateProvider<RecommendationResultSet?>((ref) {
  final prefs = ref.watch(aiPreferencesProvider);
  return AiRecommendationEngine.evaluate(prefs);
});

final selectedRecommendedProductProvider = StateProvider<BurgerRecommendation?>((ref) {
  final resultSet = ref.watch(aiRecommendationResultProvider);
  return resultSet?.bestMatch;
});
