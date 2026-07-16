import 'macros.dart';
import '../services/portion_calculator.dart';

/// Why an ingredient did or didn't contribute to the recipe total.
enum ContributionStatus {
  counted, // grams parsed AND food resolved
  unknownUnit, // GramParser returned null (non-gram unit / unparseable qty)
  noMatch, // grams parsed but food lookup returned null
}

/// One ingredient's contribution to a recipe's macros.
/// [grams] is null when [status] is unknownUnit; [macros] is null unless counted.
class IngredientContribution {
  final String name;
  final double? quantity;
  final double? grams;
  final MacroValues? macros;
  final ContributionStatus status;

  /// Where this ingredient's nutrition came from (usda/off/ai/manual). Null when
  /// the ingredient wasn't resolved (noMatch/unknownUnit).
  final MacroSource? source;

  /// When the ingredient was counted by converting a piece/count unit to grams,
  /// the grams-per-piece used and the original unit label. Null for plain-gram
  /// ingredients. Lets the UI show "2 × ≈49 g (tortilla)" and offer an adjust.
  final double? gramsPerPiece;
  final String? unit;
  final PortionUnresolvedReason? unresolvedReason;

  const IngredientContribution({
    required this.name,
    this.quantity,
    required this.grams,
    required this.macros,
    required this.status,
    this.source,
    this.gramsPerPiece,
    this.unit,
    this.unresolvedReason,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'grams': grams,
    'macros': macros?.toJson(),
    'status': status.name,
    'source': source?.name,
    'gramsPerPiece': gramsPerPiece,
    'unit': unit,
    'unresolvedReason': unresolvedReason?.name,
  };

  factory IngredientContribution.fromJson(Map<String, dynamic> j) =>
      IngredientContribution(
        name: j['name'] as String,
        quantity: (j['quantity'] as num?)?.toDouble(),
        grams: (j['grams'] as num?)?.toDouble(),
        macros: j['macros'] == null
            ? null
            : MacroValues.fromJson(j['macros'] as Map<String, dynamic>),
        status: ContributionStatus.values.byName(j['status'] as String),
        source: j['source'] == null
            ? null
            : MacroSource.values.byName(j['source'] as String),
        gramsPerPiece: (j['gramsPerPiece'] as num?)?.toDouble(),
        unit: j['unit'] as String?,
        unresolvedReason: j['unresolvedReason'] == null
            ? null
            : PortionUnresolvedReason.values.byName(
                j['unresolvedReason'] as String,
              ),
      );
}

/// Full per-ingredient breakdown of a recipe, plus the counted totals.
class RecipeBreakdown {
  final List<IngredientContribution> ingredients; // recipe order
  final MacroValues total; // sum of counted ingredients
  final double totalGrams; // sum of counted grams
  final int countedCount;
  final int totalCount;
  final bool allPhysicalGramsKnown;

  const RecipeBreakdown({
    required this.ingredients,
    required this.total,
    required this.totalGrams,
    required this.countedCount,
    required this.totalCount,
    required this.allPhysicalGramsKnown,
  });

  Map<String, dynamic> toJson() => {
    'ingredients': ingredients.map((e) => e.toJson()).toList(),
    'total': total.toJson(),
    'totalGrams': totalGrams,
    'countedCount': countedCount,
    'totalCount': totalCount,
    'allPhysicalGramsKnown': allPhysicalGramsKnown,
  };

  factory RecipeBreakdown.fromJson(Map<String, dynamic> j) => RecipeBreakdown(
    ingredients: (j['ingredients'] as List)
        .map((e) => IngredientContribution.fromJson(e as Map<String, dynamic>))
        .toList(),
    total: MacroValues.fromJson(j['total'] as Map<String, dynamic>),
    totalGrams: (j['totalGrams'] as num).toDouble(),
    countedCount: j['countedCount'] as int,
    totalCount: j['totalCount'] as int,
    allPhysicalGramsKnown: j['allPhysicalGramsKnown'] as bool? ?? true,
  );
}
