/// Household measures offered in the food logger.
///
/// A unit with a non-null [gramsPerUnit] converts to grams by a fixed factor
/// (g, kg, oz). The rest ([needsEstimate]) depend on the food — e.g. a cup of
/// rice weighs far more than a cup of lettuce — so they need a per-food AI
/// estimate of grams-per-unit via `FoodLookup.estimateUnitWeight`.
class FoodUnit {
  final String label;
  final double? gramsPerUnit;

  const FoodUnit(this.label, this.gramsPerUnit);

  /// True when this unit's gram weight varies by food and must be estimated.
  bool get needsEstimate => gramsPerUnit == null;

  @override
  String toString() => label;
}

/// The ordered set shown in the "Add food" unit dropdown: grams first (the
/// default and prior behaviour), then weight, volume, then count units.
const List<FoodUnit> kFoodUnits = [
  FoodUnit('g', 1),
  FoodUnit('kg', 1000),
  FoodUnit('oz', 28.3495),
  FoodUnit('cup', null),
  FoodUnit('tbsp', null),
  FoodUnit('tsp', null),
  FoodUnit('ml', null),
  FoodUnit('piece', null),
  FoodUnit('slice', null),
  FoodUnit('serving', null),
];
