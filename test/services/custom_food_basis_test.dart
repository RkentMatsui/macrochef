import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/services/custom_food_basis.dart';
import 'package:macrochef/services/food_units.dart';

FoodUnit u(String label) => foodUnitByLabel(label)!;
void main() {
  test('mass basis derives per-100g and no piece weight', () {
    final r = customFoodBasis(
      qty: 4,
      unit: u('oz'),
      kcal: 200,
      protein: 20,
      carb: 0,
      fat: 13,
    );
    expect(r.basis.unit, 'oz');
    expect(r.perHundred.kcal, closeTo(200 * 100 / (4 * 28.3495), 1e-3));
    expect(r.gramsPerPiece, isNull);
  });
  test(
    'volume and count bases preserve explicit macros without sentinel grams',
    () {
      final r = customFoodBasis(
        qty: 2,
        unit: u('serving'),
        kcal: 300,
        protein: 20,
        carb: 30,
        fat: 10,
      );
      expect(r.basis.quantity, 2);
      expect(r.perHundred, PerHundred.zero);
      expect(r.gramsPerPiece, isNull);
    },
  );

  test(
    'explicit physical grams derive compatibility values without rewriting basis',
    () {
      const basis = NutritionBasis(
        quantity: 1,
        unit: 'serving',
        macros: MacroValues(kcal: 240, protein: 20, carb: 24, fat: 8),
      );
      final r = customFoodBasisFromNutritionBasis(
        basis: basis,
        physicalGrams: 240,
      );
      expect(r.basis, same(basis));
      expect(r.perHundred.kcal, 100);
      expect(r.gramsPerPiece, 240);
    },
  );
}
