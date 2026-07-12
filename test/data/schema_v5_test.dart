import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/weight_repository.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('WeightEntries upsert deduplicates on date', () async {
    final repo = WeightRepository(db);
    await repo.upsert('2026-06-01', 80.0);
    await repo.upsert('2026-06-01', 81.5);
    final rows = await db.select(db.weightEntries).get();
    expect(rows.length, 1);
    expect(rows.first.kg, 81.5); // last write wins
    expect(rows.first.date, '2026-06-01');
  });

  test('FoodCache.fibre100 defaults null and round-trips a value', () async {
    // Insert without fibre100 (absent = null).
    await db.into(db.foodCache).insert(FoodCacheCompanion.insert(
          name: 'test-food',
          source: 'usda',
          kcal100: 100,
          protein100: 10,
          carb100: 5,
          fat100: 2,
        ));
    final nullRow = await db.select(db.foodCache).getSingle();
    expect(nullRow.fibre100, isNull);
    expect(nullRow.sodium100, isNull);

    // Insert with fibre100 set.
    await db.into(db.foodCache).insert(FoodCacheCompanion.insert(
          name: 'test-food-fibre',
          source: 'usda',
          kcal100: 200,
          protein100: 8,
          carb100: 30,
          fat100: 3,
          fibre100: const Value(10.6),
          sodium100: const Value(250.0),
        ));
    final fibreRow = await (db.select(db.foodCache)
          ..where((r) => r.name.equals('test-food-fibre')))
        .getSingle();
    expect(fibreRow.fibre100, closeTo(10.6, 0.001));
    expect(fibreRow.sodium100, closeTo(250.0, 0.001));
  });

  test('LogEntries.fibre defaults null and round-trips a value', () async {
    // Insert without fibre.
    await db.into(db.logEntries).insert(LogEntriesCompanion.insert(
          date: '2026-06-01',
          foodName: 'chicken',
          grams: 200,
          kcal: 330,
          protein: 62,
          carb: 0,
          fat: 7.2,
          source: 'usda',
        ));
    final nullEntry =
        await (db.select(db.logEntries)..where((e) => e.foodName.equals('chicken')))
            .getSingle();
    expect(nullEntry.fibre, isNull);

    // Insert with fibre.
    await db.into(db.logEntries).insert(LogEntriesCompanion.insert(
          date: '2026-06-01',
          foodName: 'oats',
          grams: 100,
          kcal: 370,
          protein: 13,
          carb: 66,
          fat: 7,
          source: 'usda',
          fibre: const Value(10.6),
        ));
    final fibreEntry =
        await (db.select(db.logEntries)..where((e) => e.foodName.equals('oats')))
            .getSingle();
    expect(fibreEntry.fibre, closeTo(10.6, 0.001));
  });
}
