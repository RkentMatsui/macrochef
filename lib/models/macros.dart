enum MacroSource { off, usda, ai, manual, localDb }

/// Identifies the public source used to ground nutrition information.
///
/// [inferredFields] contains field names whose values were inferred instead of
/// directly published by the source. It deliberately lives with the food
/// record, rather than an LLM provider response, so it can survive caching.
class FoodProvenance {
  final Uri url;
  final String title;
  final DateTime retrievedAt;
  final Set<String> inferredFields;

  FoodProvenance({
    required this.url,
    required this.title,
    required this.retrievedAt,
    Set<String> inferredFields = const {},
  }) : inferredFields = Set.unmodifiable(inferredFields);

  bool get isValid =>
      (url.scheme == 'https' || url.scheme == 'http') &&
      url.host.isNotEmpty &&
      title.trim().isNotEmpty;

  bool get isEstimate => inferredFields.isNotEmpty;

  FoodProvenance copyWith({Set<String>? inferredFields}) => FoodProvenance(
    url: url,
    title: title,
    retrievedAt: retrievedAt,
    inferredFields: inferredFields ?? this.inferredFields,
  );
}

class PerHundred {
  final double kcal, protein, carb, fat; // per 100g
  final double? fibre; // g per 100g; null = not known
  final double? sodium; // mg per 100g; null = not known
  const PerHundred({
    required this.kcal,
    required this.protein,
    required this.carb,
    required this.fat,
    this.fibre,
    this.sodium,
  });
  static const zero = PerHundred(kcal: 0, protein: 0, carb: 0, fat: 0);
}

class MacroValues {
  final double kcal, protein, carb, fat; // absolute for a serving
  final double? fibre; // absolute g; null = not tracked
  const MacroValues({
    required this.kcal,
    required this.protein,
    required this.carb,
    required this.fat,
    this.fibre,
  });

  MacroValues operator +(MacroValues o) => MacroValues(
    kcal: kcal + o.kcal,
    protein: protein + o.protein,
    carb: carb + o.carb,
    fat: fat + o.fat,
    fibre: (fibre == null && o.fibre == null)
        ? null
        : (fibre ?? 0) + (o.fibre ?? 0),
  );

  Map<String, dynamic> toJson() => {
    'kcal': kcal,
    'protein': protein,
    'carb': carb,
    'fat': fat,
    if (fibre != null) 'fibre': fibre,
  };

  factory MacroValues.fromJson(Map<String, dynamic> j) => MacroValues(
    kcal: (j['kcal'] as num).toDouble(),
    protein: (j['protein'] as num).toDouble(),
    carb: (j['carb'] as num).toDouble(),
    fat: (j['fat'] as num).toDouble(),
    fibre: (j['fibre'] as num?)?.toDouble(),
  );

  static const zero = MacroValues(kcal: 0, protein: 0, carb: 0, fat: 0);
  MacroValues scaled(double factor) => MacroValues(
    kcal: kcal * factor,
    protein: protein * factor,
    carb: carb * factor,
    fat: fat * factor,
    fibre: fibre == null ? null : fibre! * factor,
  );
}

class NutritionBasis {
  final double quantity;
  final String unit;
  final MacroValues macros;
  const NutritionBasis({
    required this.quantity,
    required this.unit,
    required this.macros,
  });
}

class FoodMacros {
  final String name;
  final PerHundred perHundred;
  final MacroSource source;
  final bool isEstimate;
  final NutritionBasis? basis;
  final bool basisNeedsReview;

  /// Optional provenance for a result grounded by a public web source.
  final FoodProvenance? provenance;

  /// Physical grams represented by [basis], when explicitly supplied by a
  /// source or the user. This is kept separate from [gramsPerPiece]: a basis
  /// can describe multiple servings or a volume and must still round-trip its
  /// exact authored weight.
  final double? basisPhysicalGrams;

  /// Typical grams of one piece/unit of this food (e.g. 1 tortilla ≈ 49 g).
  /// Null until estimated or set; used to convert count/piece quantities.
  final double? gramsPerPiece;

  const FoodMacros({
    required this.name,
    required this.perHundred,
    required this.source,
    required this.isEstimate,
    this.gramsPerPiece,
    this.basis,
    this.basisNeedsReview = false,
    this.provenance,
    this.basisPhysicalGrams,
  });
}

class RecipeMacros {
  final MacroValues total;
  final MacroValues perServing; // equals total until UI exposes servingCount
  final double? totalGrams; // sum of grams for resolved ingredients only
  final double?
  gramsPerServing; // totalGrams / servings, computed at construction

  const RecipeMacros({
    required this.total,
    required this.perServing,
    required this.totalGrams,
    required this.gramsPerServing,
  });
}
