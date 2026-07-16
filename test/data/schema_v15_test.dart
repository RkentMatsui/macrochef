import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('v16 exposes provenance, physical basis, and target history', () async {
    expect(db.schemaVersion, 16);
    await db
        .into(db.foodCache)
        .insert(
          FoodCacheCompanion.insert(
            name: 'food',
            source: 'ai',
            kcal100: 100,
            protein100: 5,
            carb100: 10,
            fat100: 2,
            sourceUrl: const Value('https://example.com/food'),
            sourceTitle: const Value('Source title'),
            sourceRetrievedAt: Value(DateTime.utc(2026, 7, 15)),
            sourceInferredFields: const Value('["fibre"]'),
            basisPhysicalGrams: const Value(240),
          ),
        );
    final food = await db.select(db.foodCache).getSingle();
    expect(food.sourceUrl, 'https://example.com/food');
    expect(food.basisPhysicalGrams, 240);

    await db
        .into(db.adaptiveTargets)
        .insert(
          AdaptiveTargetsCompanion.insert(
            effectiveFrom: '2026-07-16',
            calculatedThrough: '2026-07-15',
            kcal: 2200,
            protein: 150,
            carb: 225,
            fat: 65,
            windowStart: '2026-06-18',
            qualifiedIntakeDays: 18,
            weightObservationCount: 12,
            estimatedMaintenanceKcal: 2400,
            appliedAdjustmentKcal: -100,
            reason: 'lose',
          ),
        );
    expect(
      (await db.select(db.adaptiveTargets).getSingle()).effectiveFrom,
      '2026-07-16',
    );
  });

  test('migration from v14 preserves rows and adds v15/v16 data', () async {
    final dir = await Directory.systemTemp.createTemp('macrochef-v14-');
    final path = '${dir.path}${Platform.pathSeparator}database.sqlite';
    final raw = sqlite.sqlite3.open(path);
    raw.execute('''
      CREATE TABLE food_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL, source TEXT NOT NULL,
        kcal100 REAL NOT NULL, protein100 REAL NOT NULL,
        carb100 REAL NOT NULL, fat100 REAL NOT NULL,
        is_estimate INTEGER NOT NULL DEFAULT 0,
        user_override INTEGER NOT NULL DEFAULT 0,
        grams_per_piece REAL, fibre100 REAL, sodium100 REAL,
        basis_quantity REAL, basis_unit TEXT, basis_kcal REAL,
        basis_protein REAL, basis_carb REAL, basis_fat REAL,
        basis_needs_review INTEGER NOT NULL DEFAULT 0
      );
    ''');
    raw.execute('''
      CREATE TABLE daily_targets (
        scope TEXT NOT NULL PRIMARY KEY, kcal REAL NOT NULL,
        protein REAL NOT NULL, carb REAL NOT NULL, fat REAL NOT NULL
      );
    ''');
    raw.execute('''
      INSERT INTO food_cache (name, source, kcal100, protein100, carb100, fat100)
      VALUES ('legacy food', 'usda', 100, 5, 10, 2);
    ''');
    raw.execute('''
      INSERT INTO daily_targets (scope, kcal, protein, carb, fat)
      VALUES ('default', 2200, 150, 225, 65);
    ''');
    raw.execute('PRAGMA user_version = 14');
    raw.dispose();

    final migrated = AppDatabase(NativeDatabase(File(path)));
    addTearDown(() async {
      await migrated.close();
      await dir.delete(recursive: true);
    });
    final food = await migrated.select(migrated.foodCache).getSingle();
    expect(food.name, 'legacy food');
    expect(food.sourceUrl, isNull);
    expect(food.basisPhysicalGrams, isNull);
    final target = await migrated
        .select(migrated.dailyTargetsTable)
        .getSingle();
    expect(target.kcal, 2200);
    expect(await migrated.select(migrated.adaptiveTargets).get(), isEmpty);
  });

  test('installed v15 food data upgrades to v16 without data loss', () async {
    final dir = await Directory.systemTemp.createTemp('macrochef-v15-');
    final path = '${dir.path}${Platform.pathSeparator}database.sqlite';
    final raw = sqlite.sqlite3.open(path);
    raw.execute('''
      CREATE TABLE food_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL, source TEXT NOT NULL,
        kcal100 REAL NOT NULL, protein100 REAL NOT NULL,
        carb100 REAL NOT NULL, fat100 REAL NOT NULL,
        is_estimate INTEGER NOT NULL DEFAULT 0,
        user_override INTEGER NOT NULL DEFAULT 0,
        grams_per_piece REAL, fibre100 REAL, sodium100 REAL,
        basis_quantity REAL, basis_unit TEXT, basis_kcal REAL,
        basis_protein REAL, basis_carb REAL, basis_fat REAL,
        basis_needs_review INTEGER NOT NULL DEFAULT 0,
        source_url TEXT, source_title TEXT, source_retrieved_at INTEGER,
        source_inferred_fields TEXT
      );
    ''');
    raw.execute('''
      INSERT INTO food_cache (
        name, source, kcal100, protein100, carb100, fat100,
        basis_quantity, basis_unit, basis_kcal, basis_protein,
        basis_carb, basis_fat, user_override
      ) VALUES ('saved serving', 'manual', 0, 0, 0, 0,
        1, 'serving', 420, 30, 40, 15, 1);
    ''');
    raw.execute('PRAGMA user_version = 15');
    raw.dispose();

    final migrated = AppDatabase(NativeDatabase(File(path)));
    addTearDown(() async {
      await migrated.close();
      await dir.delete(recursive: true);
    });
    final food = await migrated.select(migrated.foodCache).getSingle();
    expect(food.name, 'saved serving');
    expect(food.basisQuantity, 1);
    expect(food.basisUnit, 'serving');
    expect(food.basisKcal, 420);
    expect(food.userOverride, isTrue);
    expect(food.basisPhysicalGrams, isNull);
  });
}
