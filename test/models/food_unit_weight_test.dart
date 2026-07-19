import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/food_unit_weight.dart';
import 'package:macrochef/models/macros.dart';

FoodProvenance citation({Set<String> inferredFields = const {}}) =>
    FoodProvenance(
      url: Uri.parse('https://example.com/weights'),
      title: 'Manufacturer nutrition facts',
      retrievedAt: DateTime(2026, 7, 15),
      inferredFields: inferredFields,
    );

FoodUnitWeight weight({
  String foodName = 'Tortilla',
  String unit = 'piece',
  double gramsPerUnit = 85,
  FoodUnitWeightKind kind = FoodUnitWeightKind.published,
  FoodProvenance? provenance,
}) => FoodUnitWeight(
  foodName: foodName,
  unit: unit,
  gramsPerUnit: gramsPerUnit,
  kind: kind,
  provenance: provenance ?? citation(),
);

void main() {
  test('keeps a directly published count-unit weight with its exact label', () {
    final evidence = weight();

    expect(evidence.isValid, isTrue);
    expect(evidence.gramsPerUnit, 85);
    expect(evidence.unit, 'piece');
    expect(evidence.isEstimate, isFalse);
    expect(evidence.provenance.inferredFields, isNot(contains('gramsPerUnit')));
  });

  test('keeps a directly published cup weight with its exact label', () {
    final evidence = weight(foodName: 'Flour', unit: 'cup', gramsPerUnit: 150);

    expect(evidence.isValid, isTrue);
    expect(evidence.gramsPerUnit, 150);
    expect(evidence.unit, 'cup');
  });

  test('marks a cited generic average as inferred unit-weight evidence', () {
    final evidence = weight(kind: FoodUnitWeightKind.average);

    expect(evidence.isValid, isTrue);
    expect(evidence.isEstimate, isTrue);
    expect(evidence.provenance.inferredFields, contains('gramsPerUnit'));
  });

  test('rejects invalid unit-weight evidence without throwing', () {
    expect(weight(foodName: ' ').isValid, isFalse);
    expect(weight(unit: ' ').isValid, isFalse);
    expect(weight(unit: 'scoop').isValid, isFalse);
    expect(weight(gramsPerUnit: 0).isValid, isFalse);
    expect(weight(gramsPerUnit: -1).isValid, isFalse);
    expect(weight(gramsPerUnit: double.nan).isValid, isFalse);
    expect(weight(gramsPerUnit: double.infinity).isValid, isFalse);
    expect(weight(provenance: citation()).isValid, isTrue);
    expect(
      weight(
        provenance: FoodProvenance(
          url: Uri(),
          title: 'Facts',
          retrievedAt: DateTime(2026, 7, 15),
        ),
      ).isValid,
      isFalse,
    );
    expect(
      weight(
        provenance: FoodProvenance(
          url: Uri.parse('https://example.com/weights'),
          title: ' ',
          retrievedAt: DateTime(2026, 7, 15),
        ),
      ).isValid,
      isFalse,
    );
  });

  test(
    'matches units with normalized spelling but never aliases count labels',
    () {
      final evidence = weight(unit: 'piece');

      expect(evidence.matchesUnit(' PIECE '), isTrue);
      expect(evidence.matchesUnit('slice'), isFalse);
    },
  );

  test('enforces broad unit-aware plausibility bounds', () {
    expect(weight(gramsPerUnit: 5000).isValid, isTrue);
    expect(weight(gramsPerUnit: 5000.1).isValid, isFalse);
    expect(weight(unit: 'ml', gramsPerUnit: 750).isValid, isTrue);
    expect(weight(unit: 'tbsp', gramsPerUnit: 999).isValid, isTrue);
    expect(weight(unit: 'tbsp', gramsPerUnit: 1000.1).isValid, isFalse);
  });
}
