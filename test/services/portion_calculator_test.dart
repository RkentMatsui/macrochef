import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/food_unit_weight.dart';
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

FoodUnitWeight unitWeight(String unit, double gramsPerUnit) => FoodUnitWeight(
  foodName: 'test food',
  unit: unit,
  gramsPerUnit: gramsPerUnit,
  kind: FoodUnitWeightKind.published,
  provenance: FoodProvenance(
    url: Uri.parse('https://example.com/nutrition'),
    title: 'Nutrition label',
    retrievedAt: DateTime.utc(2026),
  ),
);

void main() {
  test('unknown basis does not block usable per-hundred mass fallback', () {
    const malformedBasisFood = FoodMacros(
      name: 'meal',
      perHundred: PerHundred(kcal: 200, protein: 10, carb: 20, fat: 5),
      source: MacroSource.manual,
      isEstimate: false,
      basis: NutritionBasis(
        quantity: 1,
        unit: 'package',
        macros: MacroValues(kcal: 400, protein: 20, carb: 40, fat: 10),
      ),
    );

    final result =
        PortionCalculator.calculate(
              food: malformedBasisFood,
              quantity: 60,
              unit: 'g',
            )
            as ResolvedPortion;

    expect(result.macros.kcal, 120);
    expect(result.physicalGrams, 60);
  });

  test('unknown basis does not block exact requested-unit evidence', () {
    const malformedBasisFood = FoodMacros(
      name: 'soup',
      perHundred: PerHundred(kcal: 80, protein: 4, carb: 10, fat: 2),
      source: MacroSource.manual,
      isEstimate: false,
      basis: NutritionBasis(
        quantity: 1,
        unit: 'package',
        macros: MacroValues(kcal: 400, protein: 20, carb: 40, fat: 10),
      ),
    );

    final result =
        PortionCalculator.calculate(
              food: malformedBasisFood,
              quantity: 1,
              unit: 'cup',
              unitWeight: unitWeight('cup', 150),
            )
            as ResolvedPortion;

    expect(result.macros.kcal, 120);
    expect(result.physicalGrams, 150);
  });

  test(
    'mass request uses usable per-hundred nutrition before serving basis',
    () {
      const servingFood = FoodMacros(
        name: 'meal',
        perHundred: PerHundred(kcal: 200, protein: 10, carb: 20, fat: 5),
        source: MacroSource.manual,
        isEstimate: false,
        basis: NutritionBasis(
          quantity: 1,
          unit: 'serving',
          macros: MacroValues(kcal: 400, protein: 20, carb: 40, fat: 10),
        ),
      );

      final result =
          PortionCalculator.calculate(
                food: servingFood,
                quantity: 60,
                unit: 'g',
              )
              as ResolvedPortion;

      expect(result.macros.kcal, 120);
      expect(result.physicalGrams, 60);
    },
  );

  test('mass request scales serving basis through authored physical grams', () {
    const servingFood = FoodMacros(
      name: 'meal',
      perHundred: PerHundred.zero,
      source: MacroSource.manual,
      isEstimate: false,
      basis: NutritionBasis(
        quantity: 1,
        unit: 'serving',
        macros: MacroValues(kcal: 280, protein: 14, carb: 28, fat: 7),
      ),
      basisPhysicalGrams: 140,
    );

    final result =
        PortionCalculator.calculate(food: servingFood, quantity: 60, unit: 'g')
            as ResolvedPortion;

    expect(result.macros.kcal, 120);
    expect(result.physicalGrams, 60);
  });

  test('mass request uses recovered total weight for multiple basis units', () {
    const servingFood = FoodMacros(
      name: 'meal',
      perHundred: PerHundred.zero,
      source: MacroSource.manual,
      isEstimate: false,
      basis: NutritionBasis(
        quantity: 2,
        unit: 'serving',
        macros: MacroValues(kcal: 560, protein: 28, carb: 56, fat: 14),
      ),
    );

    final result =
        PortionCalculator.calculate(
              food: servingFood,
              quantity: 60,
              unit: 'g',
              unitWeight: unitWeight('serving', 140),
            )
            as ResolvedPortion;

    expect(result.macros.kcal, 120);
    expect(result.physicalGrams, 60);
    expect(result.acceptedUnitWeight, isNotNull);
  });

  test(
    'piece evidence bridges count quantity to usable per-hundred nutrition',
    () {
      const tortilla = FoodMacros(
        name: 'tortilla',
        perHundred: PerHundred(kcal: 200, protein: 5, carb: 30, fat: 5),
        source: MacroSource.manual,
        isEstimate: false,
      );

      final result =
          PortionCalculator.calculate(
                food: tortilla,
                quantity: 2,
                unit: 'piece',
                unitWeight: unitWeight('piece', 85),
              )
              as ResolvedPortion;

      expect(result.physicalGrams, 170);
      expect(result.macros.kcal, 340);
    },
  );

  test(
    'cup evidence bridges volume quantity to usable per-hundred nutrition',
    () {
      const soup = FoodMacros(
        name: 'soup',
        perHundred: PerHundred(kcal: 80, protein: 4, carb: 10, fat: 2),
        source: MacroSource.manual,
        isEstimate: false,
      );

      final result =
          PortionCalculator.calculate(
                food: soup,
                quantity: 1,
                unit: 'cup',
                unitWeight: unitWeight('cup', 150),
              )
              as ResolvedPortion;

      expect(result.physicalGrams, 150);
      expect(result.macros.kcal, 120);
    },
  );

  test('piece rejects evidence labelled for another count unit', () {
    const snack = FoodMacros(
      name: 'snack',
      perHundred: PerHundred.zero,
      source: MacroSource.manual,
      isEstimate: false,
    );

    for (final label in ['serving', 'slice', 'item']) {
      final result =
          PortionCalculator.calculate(
                food: snack,
                quantity: 1,
                unit: 'piece',
                unitWeight: unitWeight(label, 50),
              )
              as UnresolvedPortion;
      expect(result.reason, PortionUnresolvedReason.missingPhysicalWeight);
    }
  });

  test(
    'gramless serving basis with zero per-hundred nutrition is unresolved',
    () {
      const servingFood = FoodMacros(
        name: 'meal',
        perHundred: PerHundred.zero,
        source: MacroSource.manual,
        isEstimate: false,
        basis: NutritionBasis(
          quantity: 1,
          unit: 'serving',
          macros: MacroValues(kcal: 280, protein: 14, carb: 28, fat: 7),
        ),
      );

      final result =
          PortionCalculator.calculate(
                food: servingFood,
                quantity: 60,
                unit: 'g',
              )
              as UnresolvedPortion;

      expect(result.reason, PortionUnresolvedReason.missingPhysicalWeight);
      expect(result.basisUnit, 'serving');
    },
  );

  test('invalid evidence is ignored like no evidence', () {
    const snack = FoodMacros(
      name: 'snack',
      perHundred: PerHundred.zero,
      source: MacroSource.manual,
      isEstimate: false,
    );
    final noEvidence =
        PortionCalculator.calculate(food: snack, quantity: 1, unit: 'piece')
            as UnresolvedPortion;
    final invalidEvidence =
        PortionCalculator.calculate(
              food: snack,
              quantity: 1,
              unit: 'piece',
              unitWeight: unitWeight('piece', 0),
            )
            as UnresolvedPortion;

    expect(invalidEvidence.reason, noEvidence.reason);
    expect(invalidEvidence.basisUnit, noEvidence.basisUnit);
  });

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
