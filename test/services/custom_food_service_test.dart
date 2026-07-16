import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/food_cache_repository.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/services/custom_food_service.dart';

void main() {
  late AppDatabase db;
  late FoodCacheRepository foods;
  late CustomFoodService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    foods = FoodCacheRepository(db);
    service = CustomFoodService(foods);
  });
  tearDown(() => db.close());

  const macros = MacroValues(kcal: 510, protein: 35, carb: 48, fat: 19);

  test('remembers a gram portion with absolute macros as its basis', () async {
    await service.remember(
      name: 'Chicken curry',
      basis: const NutritionBasis(quantity: 240, unit: 'g', macros: macros),
    );

    final saved = await foods.find('chicken curry');
    expect(saved!.basis!.quantity, 240);
    expect(saved.basis!.unit, 'g');
    expect(saved.basis!.macros.kcal, 510);
    expect(saved.perHundred.kcal, closeTo(212.5, 0.001));
  });

  test('preserves a serving basis without a physical weight', () async {
    await service.remember(
      name: 'Cafe bowl',
      basis: const NutritionBasis(quantity: 1, unit: 'serving', macros: macros),
    );

    final saved = await foods.find('Cafe bowl');
    expect(saved!.basis!.unit, 'serving');
    expect(saved.basis!.quantity, 1);
    expect(saved.perHundred.kcal, 0);
    expect(saved.perHundred.protein, 0);
    expect(saved.perHundred.carb, 0);
    expect(saved.perHundred.fat, 0);
    expect(saved.gramsPerPiece, isNull);
  });

  test('re-saving a name replaces the remembered portion', () async {
    await service.remember(
      name: 'Chicken curry',
      basis: const NutritionBasis(quantity: 240, unit: 'g', macros: macros),
    );
    await service.remember(
      name: 'Chicken curry',
      basis: const NutritionBasis(
        quantity: 350,
        unit: 'g',
        macros: MacroValues(kcal: 700, protein: 48, carb: 66, fat: 26),
      ),
    );

    final saved = await foods.find('Chicken curry');
    expect(saved!.basis!.quantity, 350);
    expect(saved.basis!.macros.kcal, 700);
    expect((await db.select(db.foodCache).get()).length, 1);
  });

  test('preserves grounded provenance and estimate state', () async {
    final provenance = FoodProvenance(
      url: Uri.parse('https://example.com/label'),
      title: 'Official label',
      retrievedAt: DateTime.utc(2026, 7, 15),
      inferredFields: {'fibre'},
    );
    await service.remember(
      name: 'Grounded curry',
      basis: const NutritionBasis(quantity: 240, unit: 'g', macros: macros),
      provenance: provenance,
    );

    final saved = await foods.find('Grounded curry');
    expect(saved!.provenance!.url, provenance.url);
    expect(saved.isEstimate, isTrue);
  });

  test('a manual re-save clears stale provenance', () async {
    final provenance = FoodProvenance(
      url: Uri.parse('https://example.com/label'),
      title: 'Official label',
      retrievedAt: DateTime.utc(2026, 7, 15),
    );
    await service.remember(
      name: 'Curry',
      basis: const NutritionBasis(quantity: 240, unit: 'g', macros: macros),
      provenance: provenance,
    );
    await service.remember(
      name: 'Curry',
      basis: const NutritionBasis(
        quantity: 350,
        unit: 'g',
        macros: MacroValues(kcal: 700, protein: 48, carb: 66, fat: 26),
      ),
    );

    final saved = await foods.find('Curry');
    expect(saved!.provenance, isNull);
    expect(saved.isEstimate, isFalse);
  });

  test('rejects invalid values before mutating storage', () async {
    final invalid = const NutritionBasis(
      quantity: 0,
      unit: 'g',
      macros: MacroValues(kcal: 10, protein: 0, carb: 0, fat: 0),
    );
    await expectLater(
      service.remember(name: 'Invalid', basis: invalid),
      throwsArgumentError,
    );
    expect(await foods.find('Invalid'), isNull);
  });
}
