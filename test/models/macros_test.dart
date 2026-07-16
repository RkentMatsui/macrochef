import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/services/food_web_grounder.dart';

void main() {
  test('MacroValues addition sums each field', () {
    const a = MacroValues(kcal: 100, protein: 10, carb: 5, fat: 2);
    const b = MacroValues(kcal: 50, protein: 4, carb: 3, fat: 1);
    final sum = a + b;
    expect(sum.kcal, 150);
    expect(sum.protein, 14);
    expect(sum.carb, 8);
    expect(sum.fat, 3);
  });

  test('MacroValues.zero is all zeros', () {
    expect(MacroValues.zero.kcal, 0);
    expect(MacroValues.zero.protein, 0);
  });

  test('grounded mass basis derives per-100g without changing its basis', () {
    final result = GroundedFoodResult(
      name: 'Chicken curry',
      basis: const NutritionBasis(
        quantity: 240,
        unit: 'g',
        macros: MacroValues(kcal: 510, protein: 35, carb: 48, fat: 19),
      ),
      physicalGrams: 240,
      fibre: null,
      sodium: null,
      provenance: FoodProvenance(
        url: Uri.parse('https://example.com/nutrition'),
        title: 'Nutrition facts',
        retrievedAt: DateTime(2026, 7, 15),
      ),
    );

    expect(result.isValid, isTrue);
    expect(result.basis.quantity, 240);
    expect(result.basis.macros.kcal, 510);
    expect(result.derivedPerHundred.kcal, closeTo(212.5, 0.001));
  });

  test('non-mass basis has no fabricated per-100g value', () {
    final result = GroundedFoodResult(
      name: 'Soup',
      basis: const NutritionBasis(
        quantity: 1,
        unit: 'serving',
        macros: MacroValues(kcal: 200, protein: 8, carb: 30, fat: 5),
      ),
      physicalGrams: null,
      fibre: null,
      sodium: null,
      provenance: FoodProvenance(
        url: Uri.parse('https://example.com/soup'),
        title: 'Soup facts',
        retrievedAt: DateTime(2026, 7, 15),
      ),
    );

    expect(result.isValid, isTrue);
    expect(result.derivedPerHundred, PerHundred.zero);
  });
}
