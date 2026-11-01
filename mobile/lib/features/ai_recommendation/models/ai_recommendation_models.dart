import '../../../data/mock/catalog_data.dart';

enum BudgetRange {
  under30k(
    tier: 'Tier I',
    label: 'Under Rp 30k',
    displayRange: 'Di bawah Rp 30.000',
    minPrice: 0,
    maxPrice: 30000,
  ),
  between30kAnd50k(
    tier: 'Tier II • Optimal',
    label: 'Rp 30k – 50k',
    displayRange: 'Rp 30.000 – Rp 50.000',
    minPrice: 30000,
    maxPrice: 50000,
  ),
  between50kAnd75k(
    tier: 'Tier III',
    label: 'Rp 50k – 75k',
    displayRange: 'Rp 50.000 – Rp 75.000',
    minPrice: 50000,
    maxPrice: 75000,
  ),
  above75k(
    tier: 'Tier IV • Reserve',
    label: 'Above Rp 75k',
    displayRange: 'Di atas Rp 75.000',
    minPrice: 75000,
    maxPrice: 300000,
  );

  final String tier;
  final String label;
  final String displayRange;
  final int minPrice;
  final int maxPrice;

  const BudgetRange({
    required this.tier,
    required this.label,
    required this.displayRange,
    required this.minPrice,
    required this.maxPrice,
  });
}

enum FlavorProfile {
  smokySavory(
    id: 'smoky',
    label: 'Smoky & Savory',
    tag: 'Smoky & Gurih',
    description: 'Aroma arang kayu bakar, saus barbekyu artisanal, dan karamelisasi kaya rasa.',
  ),
  cheesy(
    id: 'cheesy',
    label: 'Cheesy Indulgence',
    tag: 'Extra Cheesy',
    description: 'Lelehan keju gouda, red cheddar tua, dan sentuhan parmesan gurih.',
  ),
  fieryPepper(
    id: 'fiery',
    label: 'Fiery Pepper',
    tag: 'Pedas Lada & Cabai',
    description: 'Sengatan habanero segar, ghost pepper aioli, dan rempah pedas membara.',
  ),
  sweetTangy(
    id: 'tangy',
    label: 'Sweet & Tangy Slaw',
    tag: 'Manis & Segar',
    description: 'Kombinasi glaze madu, coleslaw segar renyah, dan saus mustard asam seimbang.',
  ),
  classic(
    id: 'classic',
    label: 'Classic Brioche Umami',
    tag: 'Klasik Gurih',
    description: 'Cita rasa murni daging sapi pilihan, mentega Prancis, dan saus rahasia Atelier.',
  );

  final String id;
  final String label;
  final String tag;
  final String description;

  const FlavorProfile({
    required this.id,
    required this.label,
    required this.tag,
    required this.description,
  });
}

enum SpiceIntensity {
  none(
    label: 'None',
    subtitle: 'Zero',
    tag: 'Bebas Pedas (Heat 0/4)',
    level: 0,
  ),
  mild(
    label: 'Mild',
    subtitle: 'Gentle',
    tag: 'Pedas Lembut (Heat 1/4)',
    level: 1,
  ),
  medium(
    label: 'Medium',
    subtitle: 'Piquant',
    tag: 'Sedang (Heat 2/4)',
    level: 2,
  ),
  hot(
    label: 'Hot',
    subtitle: 'Bold',
    tag: 'Ekstra Pedas (Heat 4/4)',
    level: 3,
  );

  final String label;
  final String subtitle;
  final String tag;
  final int level;

  const SpiceIntensity({
    required this.label,
    required this.subtitle,
    required this.tag,
    required this.level,
  });
}

enum ProteinPreference {
  beef(
    title: 'Beef Smash',
    subtitle: 'Aged Black Angus, crisped lace edges',
    tag: 'Prime Beef',
  ),
  chicken(
    title: 'Crispy Chicken',
    subtitle: 'Buttermilk soaked, twice-fried thigh',
    tag: 'Crispy Chicken',
  ),
  noPreference(
    title: 'No Preference',
    subtitle: 'Surprise me with atelier specials',
    tag: 'Chef Choice',
  );

  final String title;
  final String subtitle;
  final String tag;

  const ProteinPreference({
    required this.title,
    required this.subtitle,
    required this.tag,
  });
}

class AiUserPreferences {
  final BudgetRange budget;
  final Set<FlavorProfile> flavors;
  final SpiceIntensity spice;
  final ProteinPreference protein;

  const AiUserPreferences({
    this.budget = BudgetRange.between30kAnd50k,
    this.flavors = const {FlavorProfile.smokySavory, FlavorProfile.fieryPepper},
    this.spice = SpiceIntensity.medium,
    this.protein = ProteinPreference.beef,
  });

  AiUserPreferences copyWith({
    BudgetRange? budget,
    Set<FlavorProfile>? flavors,
    SpiceIntensity? spice,
    ProteinPreference? protein,
  }) {
    return AiUserPreferences(
      budget: budget ?? this.budget,
      flavors: flavors ?? this.flavors,
      spice: spice ?? this.spice,
      protein: protein ?? this.protein,
    );
  }
}

class BurgerRecommendation {
  final ProductItem product;
  final double matchScore;
  final bool isBestMatch;
  final String editionTag;
  final String smokehouseCode;
  final String heatBadge;
  final String subtitle;
  final String whyThisMatches;
  final Map<String, String> specs;
  final String recommendedSideName;
  final int recommendedSidePrice;
  final String? originalPriceText;

  const BurgerRecommendation({
    required this.product,
    required this.matchScore,
    this.isBestMatch = false,
    this.editionTag = 'EDITION 04 / CURATED PAIR',
    this.smokehouseCode = 'ATELIER SMOKEHOUSE #09',
    this.heatBadge = 'MEDIUM HEAT',
    this.subtitle = 'MASTER SIGNATURE',
    required this.whyThisMatches,
    required this.specs,
    this.recommendedSideName = 'Cold Brew Cascara Float',
    this.recommendedSidePrice = 18000,
    this.originalPriceText,
  });
}

class RecommendationResultSet {
  final AiUserPreferences preferences;
  final BurgerRecommendation bestMatch;
  final List<BurgerRecommendation> alternatives;
  final DateTime generatedAt;

  const RecommendationResultSet({
    required this.preferences,
    required this.bestMatch,
    required this.alternatives,
    required this.generatedAt,
  });
}
