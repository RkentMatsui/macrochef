import '../models/macros.dart';
import 'food_units.dart';

class CustomFoodBasis {
  final NutritionBasis basis;
  final PerHundred perHundred;
  final double? gramsPerPiece;
  const CustomFoodBasis(this.basis, this.perHundred, this.gramsPerPiece);
}

CustomFoodBasis customFoodBasis({
  required double qty,
  required FoodUnit unit,
  required double kcal,
  required double protein,
  required double carb,
  required double fat,
}) {
  final q = qty <= 0 ? 1.0 : qty;
  final basis = NutritionBasis(
    quantity: q,
    unit: unit.label,
    macros: MacroValues(kcal: kcal, protein: protein, carb: carb, fat: fat),
  );
  if (unit.family == FoodUnitFamily.mass) {
    final grams = q * unit.canonicalFactor;
    final f = 100 / grams;
    return CustomFoodBasis(
      basis,
      PerHundred(
        kcal: kcal * f,
        protein: protein * f,
        carb: carb * f,
        fat: fat * f,
      ),
      null,
    );
  }
  return CustomFoodBasis(basis, PerHundred.zero, null);
}

/// Derives compatibility values for an already-authored nutrition basis.
///
/// The [NutritionBasis] remains authoritative.  The per-100g values returned
/// here are only for older callers that still need normalized values.  An
/// explicit [physicalGrams] is used when a non-mass published basis (such as a
/// serving) has a cited weight; it is never inferred from the unit label.
CustomFoodBasis customFoodBasisFromNutritionBasis({
  required NutritionBasis basis,
  double? physicalGrams,
}) {
  final unit = foodUnitByLabel(basis.unit);
  final massGrams = unit?.family == FoodUnitFamily.mass
      ? basis.quantity * unit!.canonicalFactor
      : null;
  final grams = physicalGrams ?? massGrams;
  final macros = basis.macros;

  final perHundred = grams != null && grams.isFinite && grams > 0
      ? PerHundred(
          kcal: macros.kcal * 100 / grams,
          protein: macros.protein * 100 / grams,
          carb: macros.carb * 100 / grams,
          fat: macros.fat * 100 / grams,
          fibre: macros.fibre == null ? null : macros.fibre! * 100 / grams,
        )
      : PerHundred.zero;

  // This legacy column represents the weight of one count unit.  Preserve an
  // explicitly supplied physical weight only when it can be expressed that
  // way; a volume basis and a multi-serving basis must not be misrepresented.
  final gramsPerPiece =
      physicalGrams != null &&
          physicalGrams.isFinite &&
          physicalGrams > 0 &&
          unit?.family == FoodUnitFamily.count &&
          basis.quantity > 0
      ? physicalGrams / basis.quantity
      : null;
  return CustomFoodBasis(basis, perHundred, gramsPerPiece);
}
