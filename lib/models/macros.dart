enum MacroSource { off, usda, ai, manual, localDb }

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
}

class FoodMacros {
  final String name;
  final PerHundred perHundred;
  final MacroSource source;
  final bool isEstimate;

  /// Typical grams of one piece/unit of this food (e.g. 1 tortilla ≈ 49 g).
  /// Null until estimated or set; used to convert count/piece quantities.
  final double? gramsPerPiece;

  const FoodMacros({
    required this.name,
    required this.perHundred,
    required this.source,
    required this.isEstimate,
    this.gramsPerPiece,
  });
}

class RecipeMacros {
  final MacroValues total;
  final MacroValues perServing; // equals total until UI exposes servingCount
  final double totalGrams; // sum of grams for resolved ingredients only
  final double
  gramsPerServing; // totalGrams / servings, computed at construction

  const RecipeMacros({
    required this.total,
    required this.perServing,
    required this.totalGrams,
    required this.gramsPerServing,
  });
}
