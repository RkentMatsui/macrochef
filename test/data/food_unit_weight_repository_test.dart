import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/food_unit_weight_repository.dart';
import 'package:macrochef/data/repositories/food_cache_repository.dart';
import 'package:macrochef/models/food_unit_weight.dart';
import 'package:macrochef/models/macros.dart';

FoodUnitWeight weight({
  String foodName = 'Whole wheat bread',
  String unit = 'slice',
  double grams = 32,
  FoodUnitWeightKind kind = FoodUnitWeightKind.published,
  String title = 'Nutrition label',
  DateTime? retrievedAt,
}) => FoodUnitWeight(
  foodName: foodName,
  unit: unit,
  gramsPerUnit: grams,
  kind: kind,
  provenance: FoodProvenance(
    url: Uri.parse('https://example.com/$unit'),
    title: title,
    retrievedAt: retrievedAt ?? DateTime.utc(2026, 7, 18),
  ),
);

void main() {
  late AppDatabase db;
  late FoodUnitWeightRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FoodUnitWeightRepository(db);
  });
  tearDown(() => db.close());

  test('round-trips normalized food and exact unit evidence', () async {
    final expected = weight(retrievedAt: DateTime.utc(2026, 7, 17, 12));
    await repo.upsert(expected);

    final actual = await repo.find('  WHOLE WHEAT BREAD  ', 'slice');
    expect(actual, isNotNull);
    expect(actual!.foodName, expected.foodName);
    expect(actual.unit, 'slice');
    expect(actual.gramsPerUnit, 32);
    expect(actual.kind, FoodUnitWeightKind.published);
    expect(actual.provenance.url, Uri.parse('https://example.com/slice'));
    expect(actual.provenance.title, 'Nutrition label');
    expect(
      actual.provenance.retrievedAt,
      DateTime.utc(2026, 7, 17, 12).toLocal(),
    );
    expect(
      (await db.select(db.foodUnitWeights).getSingle()).foodKey,
      'whole wheat bread',
    );
  });

  test('keeps piece and serving evidence as separate rows', () async {
    await repo.upsert(weight(unit: 'piece', grams: 60));
    await repo.upsert(weight(unit: 'serving', grams: 125));

    expect((await repo.find('whole wheat bread', 'piece'))!.gramsPerUnit, 60);
    expect(
      (await repo.find('whole wheat bread', 'serving'))!.gramsPerUnit,
      125,
    );
  });

  test(
    'upsert replaces stale evidence for the same normalized food and unit',
    () async {
      await repo.upsert(weight(grams: 30, title: 'Old label'));
      await repo.upsert(weight(foodName: ' WHOLE WHEAT BREAD ', grams: 34));

      expect(await db.select(db.foodUnitWeights).get(), hasLength(1));
      final actual = await repo.find('whole wheat bread', 'SLICE');
      expect(actual!.gramsPerUnit, 34);
      expect(actual.provenance.title, 'Nutrition label');
    },
  );

  test(
    'clearing auto data clears weights but retains user-owned nutrition',
    () async {
      await repo.upsert(weight());
      await db
          .into(db.foodCache)
          .insert(
            FoodCacheCompanion.insert(
              name: 'Auto food',
              source: 'usda',
              kcal100: 100,
              protein100: 1,
              carb100: 2,
              fat100: 3,
            ),
          );
      await db
          .into(db.foodCache)
          .insert(
            FoodCacheCompanion.insert(
              name: 'User food',
              source: 'manual',
              kcal100: 100,
              protein100: 1,
              carb100: 2,
              fat100: 3,
              userOverride: const Value(true),
            ),
          );

      await FoodCacheRepository(db).clearNonOverrides();

      expect(await db.select(db.foodUnitWeights).get(), isEmpty);
      expect((await db.select(db.foodCache).get()).map((f) => f.name), [
        'User food',
      ]);
    },
  );
}
