enum FoodUnitFamily { mass, volume, count }

class FoodUnit {
  final String label;
  final FoodUnitFamily family;
  final double canonicalFactor;
  const FoodUnit(this.label, this.family, this.canonicalFactor);
  @override
  String toString() => label;
}

const List<FoodUnit> kFoodUnits = [
  FoodUnit('g', FoodUnitFamily.mass, 1),
  FoodUnit('kg', FoodUnitFamily.mass, 1000),
  FoodUnit('oz', FoodUnitFamily.mass, 28.3495),
  FoodUnit('ml', FoodUnitFamily.volume, 1),
  FoodUnit('tsp', FoodUnitFamily.volume, 5),
  FoodUnit('tbsp', FoodUnitFamily.volume, 15),
  FoodUnit('cup', FoodUnitFamily.volume, 240),
  FoodUnit('piece', FoodUnitFamily.count, 1),
  FoodUnit('slice', FoodUnitFamily.count, 1),
  FoodUnit('stick', FoodUnitFamily.count, 1),
  FoodUnit('item', FoodUnitFamily.count, 1),
  FoodUnit('serving', FoodUnitFamily.count, 1),
];

FoodUnit? foodUnitByLabel(String raw) {
  final label = raw.trim().toLowerCase();
  for (final unit in kFoodUnits) {
    if (unit.label == label) return unit;
  }
  return null;
}

double? convertFoodQuantity(double quantity, FoodUnit from, FoodUnit to) {
  if (!quantity.isFinite || quantity <= 0 || from.family != to.family) {
    return null;
  }
  if (from.family == FoodUnitFamily.count && from.label != to.label) {
    return null;
  }
  return quantity * from.canonicalFactor / to.canonicalFactor;
}
