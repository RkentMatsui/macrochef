import '../models/macros.dart';
import 'food_units.dart';

/// Result of reducing a custom food's "macros per quantity-of-unit" entry to
/// the stored model: per-100g macros plus an optional grams-per-serving.
class CustomFoodBasis {
  final PerHundred perHundred;

  /// Grams of one serving/piece. Null for a mass-based food (entered in g/kg/oz);
  /// for a count/volume unit with no known weight it is the reference sentinel
  /// [kRefServingGrams] so the food always logs/scales by the unit.
  final double? gramsPerPiece;

  const CustomFoodBasis(this.perHundred, this.gramsPerPiece);
}

/// One serving of a count/volume unit (piece/cup/…) with no known gram weight is
/// treated as this many "reference grams", so the stored per-100g values reduce
/// to the per-serving macros and logging "N units" yields N × that serving.
const double kRefServingGrams = 100.0;

/// Converts macros entered for [qty] of [unit] into the stored per-100g model
/// (+ optional grams-per-serving). Mass units (g/kg/oz) convert exactly via the
/// unit's gram factor; count/volume units (piece/cup/…) use the reference-gram
/// sentinel so the food logs by that unit without any weighing.
CustomFoodBasis customFoodBasis({
  required double qty,
  required FoodUnit unit,
  required double kcal,
  required double protein,
  required double carb,
  required double fat,
}) {
  final q = qty <= 0 ? 1.0 : qty;
  final gpu = unit.gramsPerUnit;
  if (gpu != null) {
    // Mass unit — exact grams for the entered serving.
    final grams = q * gpu;
    final f = grams <= 0 ? 0.0 : 100.0 / grams;
    return CustomFoodBasis(
      PerHundred(kcal: kcal * f, protein: protein * f, carb: carb * f, fat: fat * f),
      null,
    );
  }
  // Count/volume unit — 1 unit = kRefServingGrams; per-100g == per-serving / q.
  return CustomFoodBasis(
    PerHundred(kcal: kcal / q, protein: protein / q, carb: carb / q, fat: fat / q),
    kRefServingGrams,
  );
}
