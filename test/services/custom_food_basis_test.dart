import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/custom_food_basis.dart';
import 'package:macrochef/services/food_units.dart';

FoodUnit _unit(String label) => kFoodUnits.firstWhere((u) => u.label == label);

void main() {
  test('per 100 g stores values verbatim, no piece weight', () {
    final r = customFoodBasis(
        qty: 100,
        unit: _unit('g'),
        kcal: 280,
        protein: 8,
        carb: 48,
        fat: 6);
    expect(r.perHundred.kcal, closeTo(280, 1e-6));
    expect(r.perHundred.protein, closeTo(8, 1e-6));
    expect(r.gramsPerPiece, isNull);
  });

  test('per piece (no weight) stores per-serving as per-100g + sentinel', () {
    // 1 tortilla = 140 kcal → logs as 1 piece via the sentinel.
    final r = customFoodBasis(
        qty: 1,
        unit: _unit('piece'),
        kcal: 140,
        protein: 4,
        carb: 24,
        fat: 3);
    expect(r.gramsPerPiece, kRefServingGrams);
    // per-100g equals per-serving when 1 unit == 100 ref grams.
    expect(r.perHundred.kcal, closeTo(140, 1e-6));
    expect(r.perHundred.carb, closeTo(24, 1e-6));
  });

  test('mass unit other than grams converts (4 oz)', () {
    // 4 oz = 113.398 g; 200 kcal for that serving.
    final r = customFoodBasis(
        qty: 4,
        unit: _unit('oz'),
        kcal: 200,
        protein: 20,
        carb: 0,
        fat: 13);
    final grams = 4 * 28.3495;
    expect(r.perHundred.kcal, closeTo(200 * 100 / grams, 1e-3));
    expect(r.gramsPerPiece, isNull);
  });

  test('multi-unit count basis divides per unit (2 servings)', () {
    final r = customFoodBasis(
        qty: 2,
        unit: _unit('serving'),
        kcal: 300,
        protein: 20,
        carb: 30,
        fat: 10);
    expect(r.gramsPerPiece, kRefServingGrams);
    expect(r.perHundred.kcal, closeTo(150, 1e-6)); // per 1 serving
  });
}
