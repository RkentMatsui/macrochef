import '../services/food_units.dart';
import 'macros.dart';

/// Whether a unit weight was published for the named food or inferred as a
/// generic average.
enum FoodUnitWeightKind { published, average }

/// Cited evidence for the physical weight of exactly one named [unit].
///
/// The unit remains a label rather than being converted to another count unit:
/// a slice is not interchangeable with a piece. Volume evidence likewise
/// records grams for one requested volume unit and never assumes a density.
class FoodUnitWeight {
  final String foodName;
  final String unit;
  final double gramsPerUnit;
  final FoodUnitWeightKind kind;
  final FoodProvenance provenance;

  FoodUnitWeight({
    required this.foodName,
    required this.unit,
    required this.gramsPerUnit,
    required this.kind,
    required FoodProvenance provenance,
  }) : provenance = _provenanceFor(kind, provenance);

  /// Generic-average evidence is useful but must remain visibly approximate.
  bool get isEstimate => kind == FoodUnitWeightKind.average;

  /// Matches spelling differences only; it intentionally never aliases labels.
  bool matchesUnit(String requestedUnit) =>
      _normalUnit(unit) == _normalUnit(requestedUnit);

  /// Returns null when this cited unit-weight evidence is safe to accept.
  String? validate() {
    if (foodName.trim().isEmpty) return 'Food name is required.';
    if (!provenance.isValid) return 'A valid cited source is required.';
    return validateFoodUnitWeight(unit: unit, gramsPerUnit: gramsPerUnit);
  }

  bool get isValid => validate() == null;
}

/// Applies the same conservative bounds at every unit-weight boundary.
///
/// The limits intentionally cover unusually dense, large, and prepared foods
/// while rejecting malformed provider output. A null return means valid.
String? validateFoodUnitWeight({
  required String unit,
  required double gramsPerUnit,
}) {
  final parsedUnit = foodUnitByLabel(unit);
  if (parsedUnit == null || parsedUnit.family == FoodUnitFamily.mass) {
    return 'A supported non-mass unit is required.';
  }
  if (!gramsPerUnit.isFinite || gramsPerUnit <= 0) {
    return 'Grams per unit must be positive and finite.';
  }

  final maximumGrams = switch (parsedUnit.label) {
    'tsp' || 'tbsp' => 1000.0,
    _ => 5000.0,
  };
  if (gramsPerUnit > maximumGrams) {
    return 'Grams per unit is outside the plausible range.';
  }
  return null;
}

String _normalUnit(String value) => value.trim().toLowerCase();

FoodProvenance _provenanceFor(
  FoodUnitWeightKind kind,
  FoodProvenance provenance,
) {
  final inferredFields = {...provenance.inferredFields};
  if (kind == FoodUnitWeightKind.average) {
    inferredFields.add('gramsPerUnit');
  } else {
    inferredFields.remove('gramsPerUnit');
  }
  return provenance.copyWith(inferredFields: inferredFields);
}
