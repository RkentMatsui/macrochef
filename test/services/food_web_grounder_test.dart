import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/daily.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/services/food_web_grounder.dart';

GroundedFoodResult result({
  Uri? url,
  String title = 'Nutrition facts',
  double quantity = 1,
  double kcal = 100,
  Set<String> inferredFields = const {},
}) => GroundedFoodResult(
  name: 'Example food',
  basis: NutritionBasis(
    quantity: quantity,
    unit: 'serving',
    macros: MacroValues(kcal: kcal, protein: 1, carb: 2, fat: 3),
  ),
  physicalGrams: null,
  fibre: null,
  sodium: null,
  provenance: FoodProvenance(
    url: url ?? Uri.parse('https://example.com/food'),
    title: title,
    retrievedAt: DateTime(2026, 7, 15),
    inferredFields: inferredFields,
  ),
);

void main() {
  test('grounded result rejects missing citation and invalid nutrition', () {
    expect(result(url: Uri()).isValid, isFalse);
    expect(result(title: ' ').isValid, isFalse);
    expect(result(quantity: 0).isValid, isFalse);
    expect(result(kcal: -1).isValid, isFalse);
    expect(result(kcal: double.nan).isValid, isFalse);
    expect(result(kcal: double.infinity).isValid, isFalse);
  });

  test('inferred fields make a grounded result an estimate', () {
    final grounded = result(inferredFields: {'carb'});
    expect(grounded.isValid, isTrue);
    expect(grounded.isEstimate, isTrue);
    expect(grounded.provenance.isEstimate, isTrue);
  });

  test('adaptive applied result retains dated audit statistics', () {
    final record = AdaptiveTargetRecord(
      target: const DailyTarget(kcal: 2250, protein: 160, carb: 230, fat: 75),
      calculatedThrough: '2026-07-14',
      effectiveFrom: '2026-07-15',
      windowStart: '2026-06-17',
      qualifiedIntakeDays: 18,
      weightObservationCount: 12,
      estimatedMaintenanceKcal: 2400,
      appliedAdjustmentKcal: -150,
      reason: 'lose',
      createdAt: DateTime(2026, 7, 15),
    );
    final outcome = AdaptiveApplied(record);

    expect(outcome.target.kcal, 2250);
    expect(outcome.record.calculatedThrough, '2026-07-14');
    expect(outcome.record.effectiveFrom, '2026-07-15');
    expect(outcome.record.qualifiedIntakeDays, 18);
    expect(outcome.record.weightObservationCount, 12);
    expect(outcome.record.estimatedMaintenanceKcal, 2400);
    expect(outcome.record.appliedAdjustmentKcal, -150);
    expect(outcome.record.reason, 'lose');
  });
}
