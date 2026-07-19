import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/log_repository.dart';
import 'package:macrochef/data/repositories/food_cache_repository.dart';
import 'package:macrochef/data/repositories/target_repository.dart';
import 'package:macrochef/models/daily.dart';
import 'package:macrochef/models/food_unit_weight.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/services/daily_log_service.dart';
import 'package:macrochef/services/custom_food_service.dart';

void main() {
  late AppDatabase db;
  late DailyLogService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    service = DailyLogService(
      logs: LogRepository(db),
      targets: TargetRepository(db),
      customFoods: CustomFoodService(FoodCacheRepository(db)),
    );
  });

  tearDown(() => db.close());

  test('log two foods and totals sums kcal correctly', () async {
    const date = '2026-06-14';

    // chicken: 200g, 330 kcal, 62g protein, 0 carb, 7.2g fat
    await service.log(
      date,
      name: 'chicken breast',
      grams: 200,
      macros: const MacroValues(kcal: 330, protein: 62, carb: 0, fat: 7.2),
      source: MacroSource.off,
    );

    // rice: 150g, 195 kcal, 4.05g protein, 43.35 carb, 0.45g fat
    await service.log(
      date,
      name: 'white rice',
      grams: 150,
      macros: const MacroValues(
        kcal: 195,
        protein: 4.05,
        carb: 43.35,
        fat: 0.45,
      ),
      source: MacroSource.usda,
    );

    final totals = await service.totals(date);
    expect(totals.consumed.kcal, closeTo(525, 0.01));
    expect(totals.consumed.protein, closeTo(66.05, 0.01));
    expect(totals.target, isNull); // no target set
  });

  test('copyDay re-logs every entry with exact unit-weight evidence', () async {
    final evidence = FoodUnitWeight(
      foodName: 'oats',
      unit: 'cup',
      gramsPerUnit: 80,
      kind: FoodUnitWeightKind.published,
      provenance: FoodProvenance(
        url: Uri.parse('https://example.com/oats'),
        title: 'Oat label',
        retrievedAt: DateTime.utc(2026, 7, 18),
      ),
    );
    await service.log(
      '2026-06-13',
      name: 'oats',
      grams: 80,
      macros: const MacroValues(kcal: 300, protein: 10, carb: 50, fat: 6),
      source: MacroSource.usda,
      portionQuantity: 1,
      portionUnit: 'cup',
      unitWeightEvidence: evidence,
    );
    await service.log(
      '2026-06-13',
      name: 'eggs',
      grams: 100,
      macros: const MacroValues(kcal: 155, protein: 13, carb: 1, fat: 11),
      source: MacroSource.manual,
    );

    final n = await service.copyDay('2026-06-13', '2026-06-14');
    expect(n, 2);

    final src = await service.totals('2026-06-13');
    final dst = await service.totals('2026-06-14');
    expect(dst.consumed.kcal, closeTo(src.consumed.kcal, 0.01));
    expect(dst.consumed.protein, closeTo(src.consumed.protein, 0.01));
    final copied = (await service.logs.forDate('2026-06-14')).first;
    expect(copied.portionWeightGramsPerUnit, 80);
    expect(copied.portionWeightIsEstimate, isFalse);
    expect(copied.portionWeightSourceUrl, 'https://example.com/oats');
  });

  test('copyDay preserves serving evidence for a gram-requested portion', () async {
    final evidence = FoodUnitWeight(
      foodName: 'protein powder',
      unit: 'serving',
      gramsPerUnit: 30,
      kind: FoodUnitWeightKind.published,
      provenance: FoodProvenance(
        url: Uri.parse('https://example.com/protein'),
        title: 'Protein label',
        retrievedAt: DateTime.utc(2026, 7, 18),
      ),
    );
    await service.log(
      '2026-06-13',
      name: 'protein powder',
      grams: 30,
      macros: const MacroValues(kcal: 120, protein: 24, carb: 3, fat: 1),
      source: MacroSource.usda,
      portionQuantity: 30,
      portionUnit: 'g',
      unitWeightEvidence: evidence,
    );

    await service.copyDay('2026-06-13', '2026-06-14');

    final copied = (await service.logs.forDate('2026-06-14')).single;
    expect(copied.portionWeightUnit, 'serving');
  });

  test('copyDay returns 0 when the source day is empty', () async {
    expect(await service.copyDay('2026-01-01', '2026-06-14'), 0);
  });

  test('preserves a basis-defined portion without inventing grams', () async {
    await service.log(
      '2026-06-14',
      name: 'Iced milk',
      grams: 0,
      macros: const MacroValues(kcal: 120, protein: 8, carb: 12, fat: 4),
      source: MacroSource.manual,
      portionQuantity: 250,
      portionUnit: 'ml',
    );

    final entry = (await db.select(db.logEntries).getSingle());
    expect(entry.grams, 0);
    expect(entry.portionQuantity, 250);
    expect(entry.portionUnit, 'ml');
    expect(entry.kcal, 120);
    expect(entry.protein, 8);
    expect(entry.carb, 12);
    expect(entry.fat, 4);
    expect(entry.portionWeightGramsPerUnit, isNull);
    expect(entry.portionWeightIsEstimate, isNull);
  });

  test(
    'logs the exact unit-weight evidence used for a converted portion',
    () async {
      final evidence = FoodUnitWeight(
        foodName: 'Bread',
        unit: 'slice',
        gramsPerUnit: 32,
        kind: FoodUnitWeightKind.average,
        provenance: FoodProvenance(
          url: Uri.parse('https://example.com/bread'),
          title: 'Generic bread weight',
          retrievedAt: DateTime.utc(2026, 7, 18),
        ),
      );
      await service.log(
        '2026-07-18',
        name: 'Bread',
        grams: 64,
        macros: const MacroValues(kcal: 160, protein: 8, carb: 30, fat: 2),
        source: MacroSource.usda,
        unitWeightEvidence: evidence,
      );

      final entry = await db.select(db.logEntries).getSingle();
      expect(entry.portionWeightGramsPerUnit, 32);
      expect(entry.portionWeightIsEstimate, isTrue);
      expect(entry.portionWeightSourceUrl, 'https://example.com/bread');
      expect(entry.portionWeightSourceTitle, 'Generic bread weight');
      expect(entry.portionWeightUnit, 'slice');
      expect(
        entry.portionWeightSourceRetrievedAt,
        DateTime.utc(2026, 7, 18).toLocal(),
      );
    },
  );

  test('setTarget persists and is returned in totals', () async {
    const date = '2026-06-14';

    await service.setTarget(
      const DailyTarget(kcal: 2000, protein: 180, carb: 200, fat: 60),
    );

    await service.log(
      date,
      name: 'chicken breast',
      grams: 200,
      macros: const MacroValues(kcal: 330, protein: 62, carb: 0, fat: 7.2),
      source: MacroSource.off,
    );

    final totals = await service.totals(date);
    expect(totals.target, isNotNull);
    expect(totals.target!.protein, closeTo(180, 0.01));
    expect(totals.consumed.kcal, closeTo(330, 0.01));
  });

  test('totals for different date returns only that day entries', () async {
    await service.log(
      '2026-06-14',
      name: 'chicken breast',
      grams: 200,
      macros: const MacroValues(kcal: 330, protein: 62, carb: 0, fat: 7.2),
      source: MacroSource.off,
    );

    await service.log(
      '2026-06-13',
      name: 'oats',
      grams: 100,
      macros: const MacroValues(kcal: 370, protein: 13, carb: 66, fat: 7),
      source: MacroSource.manual,
    );

    final totals = await service.totals('2026-06-14');
    expect(totals.consumed.kcal, closeTo(330, 0.01));
  });

  test('fibre sums across two entries with fibre', () async {
    const date = '2026-06-15';

    await service.log(
      date,
      name: 'oats',
      grams: 100,
      macros: const MacroValues(
        kcal: 370,
        protein: 13,
        carb: 66,
        fat: 7,
        fibre: 10.6,
      ),
      source: MacroSource.usda,
    );

    await service.log(
      date,
      name: 'broccoli',
      grams: 100,
      macros: const MacroValues(
        kcal: 34,
        protein: 2.8,
        carb: 6.6,
        fat: 0.4,
        fibre: 2.4,
      ),
      source: MacroSource.usda,
    );

    final totals = await service.totals(date);
    expect(totals.consumed.fibre, isNotNull);
    expect(totals.consumed.fibre!, closeTo(13.0, 0.01));
  });

  test('fibre is null in totals when no entry carries fibre', () async {
    const date = '2026-06-16';

    await service.log(
      date,
      name: 'chicken breast',
      grams: 200,
      macros: const MacroValues(kcal: 330, protein: 62, carb: 0, fat: 7.2),
      source: MacroSource.off,
    );

    final totals = await service.totals(date);
    expect(totals.consumed.fibre, isNull);
  });

  test(
    'editing remembers the exact gram portion and replaces it on re-edit',
    () async {
      await service.log(
        '2026-06-16',
        name: 'Chicken curry',
        grams: 240,
        macros: const MacroValues(kcal: 510, protein: 35, carb: 48, fat: 19),
        source: MacroSource.manual,
      );
      final entry = await db.select(db.logEntries).getSingle();

      await service.updateAndRemember(
        entry.id,
        name: 'Chicken curry',
        grams: 240,
        macros: const MacroValues(kcal: 510, protein: 35, carb: 48, fat: 19),
        portionQuantity: 240,
        portionUnit: 'g',
        physicalGrams: 240,
      );
      var food = await FoodCacheRepository(db).find('Chicken curry');
      expect(food!.basis!.quantity, 240);
      expect(food.basis!.unit, 'g');
      expect(food.basis!.macros.kcal, 510);

      await service.updateAndRemember(
        entry.id,
        name: 'Chicken curry',
        grams: 350,
        macros: const MacroValues(kcal: 620, protein: 42, carb: 55, fat: 22),
        portionQuantity: 350,
        portionUnit: 'g',
        physicalGrams: 350,
      );
      food = await FoodCacheRepository(db).find('Chicken curry');
      expect(food!.basis!.quantity, 350);
      expect(food.basis!.macros.kcal, 620);
    },
  );

  test('editing a serving basis without grams remembers that basis', () async {
    await service.log(
      '2026-06-16',
      name: 'Cafe bowl',
      grams: 0,
      macros: const MacroValues(kcal: 500, protein: 30, carb: 50, fat: 20),
      source: MacroSource.manual,
      portionQuantity: 1,
      portionUnit: 'serving',
    );
    final entry = await db.select(db.logEntries).getSingle();
    await service.updateAndRemember(
      entry.id,
      name: 'Cafe bowl',
      grams: 0,
      macros: const MacroValues(kcal: 500, protein: 30, carb: 50, fat: 20),
      portionQuantity: 1,
      portionUnit: 'serving',
    );
    final food = await FoodCacheRepository(db).find('Cafe bowl');
    expect(food!.basis!.unit, 'serving');
    expect(food.perHundred.kcal, 0);
  });

  test('editing clears stale unit-weight evidence', () async {
    final evidence = FoodUnitWeight(
      foodName: 'Bread',
      unit: 'slice',
      gramsPerUnit: 32,
      kind: FoodUnitWeightKind.published,
      provenance: FoodProvenance(
        url: Uri.parse('https://example.com/bread'),
        title: 'Bread label',
        retrievedAt: DateTime.utc(2026, 7, 18),
      ),
    );
    await service.log(
      '2026-06-16',
      name: 'Bread',
      grams: 64,
      macros: const MacroValues(kcal: 160, protein: 8, carb: 30, fat: 2),
      source: MacroSource.usda,
      portionQuantity: 2,
      portionUnit: 'slice',
      unitWeightEvidence: evidence,
    );
    final entry = await db.select(db.logEntries).getSingle();

    await service.updateAndRemember(
      entry.id,
      name: 'Bread',
      grams: 100,
      macros: const MacroValues(kcal: 250, protein: 10, carb: 45, fat: 3),
      portionQuantity: 100,
      portionUnit: 'g',
      physicalGrams: 100,
    );

    final updated = await db.select(db.logEntries).getSingle();
    expect(updated.portionWeightGramsPerUnit, isNull);
    expect(updated.portionWeightIsEstimate, isNull);
    expect(updated.portionWeightSourceUrl, isNull);
    expect(updated.portionWeightSourceTitle, isNull);
    expect(updated.portionWeightSourceRetrievedAt, isNull);
  });

  test('editing a recipe entry does not create a custom food', () async {
    await service.log(
      '2026-06-16',
      name: 'Recipe curry',
      grams: 240,
      macros: const MacroValues(kcal: 510, protein: 35, carb: 48, fat: 19),
      source: MacroSource.manual,
      recipeId: 42,
    );
    final entry = await db.select(db.logEntries).getSingle();
    await service.updateAndRemember(
      entry.id,
      name: 'Recipe curry',
      grams: 250,
      macros: const MacroValues(kcal: 530, protein: 36, carb: 50, fat: 20),
      portionQuantity: 250,
      portionUnit: 'g',
      physicalGrams: 250,
    );
    expect(await FoodCacheRepository(db).find('Recipe curry'), isNull);
    expect((await db.select(db.logEntries).getSingle()).grams, 250);
  });

  test('failed custom persistence rolls back the log edit', () async {
    await service.log(
      '2026-06-16',
      name: 'Curry',
      grams: 240,
      macros: const MacroValues(kcal: 510, protein: 35, carb: 48, fat: 19),
      source: MacroSource.manual,
    );
    final entry = await db.select(db.logEntries).getSingle();
    await expectLater(
      service.updateAndRemember(
        entry.id,
        name: 'Curry',
        grams: 350,
        macros: const MacroValues(kcal: -1, protein: 42, carb: 55, fat: 22),
        portionQuantity: 350,
        portionUnit: 'g',
        physicalGrams: 350,
      ),
      throwsArgumentError,
    );
    final after = await db.select(db.logEntries).getSingle();
    expect(after.grams, 240);
    expect(after.kcal, 510);
  });

  group('frequentFoods / relog', () {
    test('ranks by occurrence count, carries last-logged portion', () async {
      // chicken logged 3×, rice 1× — across several days within the window.
      await service.log(
        '2026-06-10',
        name: 'chicken breast',
        grams: 200,
        macros: const MacroValues(kcal: 330, protein: 62, carb: 0, fat: 7.2),
        source: MacroSource.off,
      );
      await service.log(
        '2026-06-11',
        name: 'white rice',
        grams: 150,
        macros: const MacroValues(kcal: 195, protein: 4, carb: 43, fat: 0.5),
        source: MacroSource.usda,
      );
      await service.log(
        '2026-06-12',
        name: 'chicken breast',
        grams: 220,
        macros: const MacroValues(kcal: 363, protein: 68, carb: 0, fat: 7.9),
        source: MacroSource.off,
      );
      // Most-recent chicken portion = 180g — this is the one re-log should use.
      await service.log(
        '2026-06-14',
        name: 'chicken breast',
        grams: 180,
        macros: const MacroValues(kcal: 297, protein: 56, carb: 0, fat: 6.5),
        source: MacroSource.off,
      );

      final freq = await service.frequentFoods('2026-06-15');
      expect(freq.first.name, 'chicken breast');
      expect(freq.first.count, 3);
      // Carries the LAST-logged portion, not the first.
      expect(freq.first.grams, closeTo(180, 0.01));
      expect(freq.first.macros.kcal, closeTo(297, 0.01));
      expect(freq.first.source, MacroSource.off);
      expect(freq[1].name, 'white rice');
      expect(freq[1].count, 1);
    });

    test('excludes foods outside the lookback window', () async {
      await service.log(
        '2026-01-01',
        name: 'old food',
        grams: 100,
        macros: const MacroValues(kcal: 100, protein: 1, carb: 1, fat: 1),
        source: MacroSource.manual,
      );

      final freq = await service.frequentFoods('2026-06-15', windowDays: 60);
      expect(freq.where((f) => f.name == 'old food'), isEmpty);
    });

    test(
      'relog re-inserts the same portion and unit-weight evidence',
      () async {
        final evidence = FoodUnitWeight(
          foodName: 'chicken breast',
          unit: 'serving',
          gramsPerUnit: 200,
          kind: FoodUnitWeightKind.average,
          provenance: FoodProvenance(
            url: Uri.parse('https://example.com/chicken'),
            title: 'Chicken average',
            retrievedAt: DateTime.utc(2026, 7, 18),
          ),
        );
        await service.log(
          '2026-06-10',
          name: 'chicken breast',
          grams: 200,
          macros: const MacroValues(
            kcal: 330,
            protein: 62,
            carb: 0,
            fat: 7.2,
            fibre: 0,
          ),
          source: MacroSource.off,
          portionQuantity: 200,
          portionUnit: 'g',
          unitWeightEvidence: evidence,
        );

        final freq = await service.frequentFoods('2026-06-15');
        await service.relog('2026-06-15', freq.first);

        final totals = await service.totals('2026-06-15');
        expect(totals.consumed.kcal, closeTo(330, 0.01));
        expect(totals.consumed.protein, closeTo(62, 0.01));
        final relogged = (await service.logs.forDate('2026-06-15')).single;
        expect(relogged.portionWeightGramsPerUnit, 200);
        expect(relogged.portionWeightUnit, 'serving');
        expect(relogged.portionWeightIsEstimate, isTrue);
        expect(relogged.portionWeightSourceTitle, 'Chicken average');
      },
    );

    test('limit caps the number of foods returned', () async {
      for (var i = 0; i < 20; i++) {
        await service.log(
          '2026-06-10',
          name: 'food $i',
          grams: 100,
          macros: const MacroValues(kcal: 100, protein: 1, carb: 1, fat: 1),
          source: MacroSource.manual,
        );
      }
      final freq = await service.frequentFoods('2026-06-15', limit: 5);
      expect(freq.length, 5);
    });
  });
}
