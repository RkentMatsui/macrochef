import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('v15 schema retains basis and logged portion columns', () async {
    expect(db.schemaVersion, 18);
    await db
        .into(db.foodCache)
        .insert(
          FoodCacheCompanion.insert(
            name: 'milk',
            source: 'manual',
            kcal100: 48,
            protein100: 3,
            carb100: 5,
            fat100: 2,
            basisQuantity: const Value(250),
            basisUnit: const Value('ml'),
            basisKcal: const Value(120),
            basisProtein: const Value(7.5),
            basisCarb: const Value(12.5),
            basisFat: const Value(5),
          ),
        );
    await db
        .into(db.logEntries)
        .insert(
          LogEntriesCompanion.insert(
            date: '2026-07-14',
            foodName: 'milk',
            grams: 0,
            kcal: 120,
            protein: 7.5,
            carb: 12.5,
            fat: 5,
            source: 'manual',
            portionQuantity: const Value(250),
            portionUnit: const Value('ml'),
          ),
        );
    final food = await db.select(db.foodCache).getSingle();
    final log = await db.select(db.logEntries).getSingle();
    expect(food.basisUnit, 'ml');
    expect(log.portionQuantity, 250);
    expect(log.portionUnit, 'ml');
  });
}
