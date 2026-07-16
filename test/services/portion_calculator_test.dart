import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/services/portion_calculator.dart';

const basis = NutritionBasis(
  quantity: 250,
  unit: 'ml',
  macros: MacroValues(kcal: 180, protein: 20, carb: 8, fat: 6),
);
const food = FoodMacros(
  name: 'shake',
  perHundred: PerHundred.zero,
  source: MacroSource.manual,
  isEstimate: false,
  basis: basis,
);
void main() {
  test('scales explicit volume basis and has no physical grams', () {
    final half =
        PortionCalculator.calculate(food: food, quantity: 125, unit: 'ml')
            as ResolvedPortion;
    expect(half.macros.kcal, 90);
    expect(half.macros.protein, 10);
    expect(half.physicalGrams, isNull);
    final cup =
        PortionCalculator.calculate(food: food, quantity: 1, unit: 'cup')
            as ResolvedPortion;
    expect(cup.macros.kcal, closeTo(172.8, 0.001));
    expect(cup.physicalGrams, isNull);
  });
  test('rejects incompatible count labels and resolves real stored weight', () {
    expect(
      PortionCalculator.calculate(food: food, quantity: 1, unit: 'slice'),
      isA<UnresolvedPortion>(),
    );
    const tortilla = FoodMacros(
      name: 't',
      perHundred: PerHundred(kcal: 200, protein: 5, carb: 30, fat: 5),
      source: MacroSource.manual,
      isEstimate: false,
      gramsPerPiece: 50,
    );
    final result =
        PortionCalculator.calculate(food: tortilla, quantity: 2, unit: 'piece')
            as ResolvedPortion;
    expect(result.physicalGrams, 100);
  });
  test('non-mass input without weight is unresolved', () {
    const plain = FoodMacros(
      name: 'x',
      perHundred: PerHundred.zero,
      source: MacroSource.manual,
      isEstimate: false,
    );
    final result =
        PortionCalculator.calculate(food: plain, quantity: 1, unit: 'piece')
            as UnresolvedPortion;
    expect(result.reason, PortionUnresolvedReason.missingPhysicalWeight);
  });

  test('logs a label-provided serving without a fabricated gram weight', () {
    const labelledServing = FoodMacros(
      name: 'instant coffee stick',
      perHundred: PerHundred.zero,
      source: MacroSource.off,
      isEstimate: false,
      basis: NutritionBasis(
        quantity: 1,
        unit: 'serving',
        macros: MacroValues(kcal: 70, protein: 0, carb: 14, fat: 1.5),
      ),
    );

    final result =
        PortionCalculator.calculate(
              food: labelledServing,
              quantity: 1,
              unit: 'serving',
            )
            as ResolvedPortion;
    expect(result.macros.kcal, 70);
    expect(result.physicalGrams, isNull);
  });

  test('scales an explicitly cited physical weight with its basis', () {
    const labelledServing = FoodMacros(
      name: 'meal',
      perHundred: PerHundred(kcal: 200, protein: 10, carb: 20, fat: 5),
      source: MacroSource.ai,
      isEstimate: false,
      basis: NutritionBasis(
        quantity: 2,
        unit: 'serving',
        macros: MacroValues(kcal: 400, protein: 20, carb: 40, fat: 10),
      ),
      basisPhysicalGrams: 200,
    );

    final result =
        PortionCalculator.calculate(
              food: labelledServing,
              quantity: 1,
              unit: 'serving',
            )
            as ResolvedPortion;
    expect(result.macros.kcal, 200);
    expect(result.physicalGrams, 100);
  });

  test('logs an unsaved label-provided stick without assuming grams', () {
    const labelledStick = FoodMacros(
      name: 'instant coffee stick',
      perHundred: PerHundred.zero,
      source: MacroSource.off,
      isEstimate: false,
      basis: NutritionBasis(
        quantity: 1,
        unit: 'stick',
        macros: MacroValues(kcal: 70, protein: 0, carb: 14, fat: 1.5),
      ),
    );

    final result =
        PortionCalculator.calculate(
              food: labelledStick,
              quantity: 1,
              unit: 'stick',
            )
            as ResolvedPortion;
    expect(result.macros.kcal, 70);
    expect(result.physicalGrams, isNull);
  });
}
