import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'v18 exposes durable weight units and nullable log conversion evidence',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, 18);

      await db
          .into(db.logEntries)
          .insert(
            LogEntriesCompanion.insert(
              date: '2026-07-18',
              foodName: 'bread',
              grams: 64,
              kcal: 160,
              protein: 8,
              carb: 30,
              fat: 2,
              source: 'usda',
              portionWeightGramsPerUnit: const Value(32),
              portionWeightUnit: const Value('slice'),
              portionWeightIsEstimate: const Value(false),
              portionWeightSourceUrl: const Value('https://example.com/bread'),
              portionWeightSourceTitle: const Value('Bread nutrition label'),
              portionWeightSourceRetrievedAt: Value(DateTime.utc(2026, 7, 18)),
            ),
          );
      final log = await db.select(db.logEntries).getSingle();
      expect(log.portionWeightGramsPerUnit, 32);
      expect(log.portionWeightUnit, 'slice');
      expect(log.portionWeightIsEstimate, isFalse);
      expect(log.portionWeightSourceTitle, 'Bread nutrition label');
    },
  );

  test(
    'migration from v16 preserves food, logs, targets, recipes, and training',
    () async {
      final dir = await Directory.systemTemp.createTemp('macrochef-v16-');
      final path = '${dir.path}${Platform.pathSeparator}database.sqlite';
      final raw = sqlite.sqlite3.open(path);
      raw.execute('''
      CREATE TABLE food_cache (id INTEGER PRIMARY KEY, name TEXT NOT NULL,
        source TEXT NOT NULL, kcal100 REAL NOT NULL, protein100 REAL NOT NULL,
        carb100 REAL NOT NULL, fat100 REAL NOT NULL, is_estimate INTEGER NOT NULL DEFAULT 0,
        user_override INTEGER NOT NULL DEFAULT 0, grams_per_piece REAL, fibre100 REAL,
        sodium100 REAL, basis_quantity REAL, basis_unit TEXT, basis_kcal REAL,
        basis_protein REAL, basis_carb REAL, basis_fat REAL,
        basis_needs_review INTEGER NOT NULL DEFAULT 0, source_url TEXT,
        source_title TEXT, source_retrieved_at INTEGER, source_inferred_fields TEXT,
        basis_physical_grams REAL);
      CREATE TABLE log_entries (id INTEGER PRIMARY KEY, date TEXT NOT NULL,
        food_name TEXT NOT NULL, grams REAL NOT NULL, kcal REAL NOT NULL,
        protein REAL NOT NULL, carb REAL NOT NULL, fat REAL NOT NULL, fibre REAL,
        source TEXT NOT NULL, recipe_id INTEGER, portion_quantity REAL, portion_unit TEXT);
      CREATE TABLE daily_targets (scope TEXT NOT NULL PRIMARY KEY, kcal REAL NOT NULL,
        protein REAL NOT NULL, carb REAL NOT NULL, fat REAL NOT NULL);
      CREATE TABLE recipes (id INTEGER PRIMARY KEY, title TEXT NOT NULL,
        created_at INTEGER NOT NULL, servings INTEGER NOT NULL DEFAULT 1);
      CREATE TABLE exercises (id INTEGER PRIMARY KEY, slug TEXT, name TEXT NOT NULL,
        category TEXT NOT NULL, primary_muscle TEXT, secondary_muscles TEXT,
        equipment TEXT, description TEXT, tracks_weight INTEGER NOT NULL DEFAULT 0,
        tracks_reps INTEGER NOT NULL DEFAULT 0, tracks_duration INTEGER NOT NULL DEFAULT 0,
        tracks_distance INTEGER NOT NULL DEFAULT 0, is_custom INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL);
      INSERT INTO food_cache (id,name,source,kcal100,protein100,carb100,fat100)
        VALUES (1,'food','usda',100,1,2,3);
      INSERT INTO log_entries (id,date,food_name,grams,kcal,protein,carb,fat,source)
        VALUES (2,'2026-07-18','food',100,100,1,2,3,'usda');
      INSERT INTO daily_targets (scope,kcal,protein,carb,fat) VALUES ('default',2000,150,200,60);
      INSERT INTO recipes (id,title,created_at,servings) VALUES (4,'recipe',0,1);
      INSERT INTO exercises (id,name,category,created_at) VALUES (5,'squat','strength',0);
      PRAGMA user_version = 16;
    ''');
      raw.dispose();

      final db = AppDatabase(NativeDatabase(File(path)));
      addTearDown(() async {
        await db.close();
        await dir.delete(recursive: true);
      });
      expect((await db.select(db.foodCache).getSingle()).name, 'food');
      expect((await db.select(db.logEntries).getSingle()).foodName, 'food');
      expect((await db.select(db.dailyTargetsTable).getSingle()).kcal, 2000);
      expect((await db.select(db.recipes).getSingle()).title, 'recipe');
      expect((await db.select(db.exercises).getSingle()).name, 'squat');
      expect(await db.select(db.foodUnitWeights).get(), isEmpty);
      final log = await db.select(db.logEntries).getSingle();
      expect(log.portionWeightGramsPerUnit, isNull);
      expect(log.portionWeightIsEstimate, isNull);
    },
  );

  test('migration from v17 retains existing evidence and leaves its unit null',
      () async {
    final dir = await Directory.systemTemp.createTemp('macrochef-v17-');
    final path = '${dir.path}${Platform.pathSeparator}database.sqlite';
    final raw = sqlite.sqlite3.open(path);
    raw.execute('''
      CREATE TABLE log_entries (id INTEGER PRIMARY KEY, date TEXT NOT NULL,
        food_name TEXT NOT NULL, grams REAL NOT NULL, kcal REAL NOT NULL,
        protein REAL NOT NULL, carb REAL NOT NULL, fat REAL NOT NULL, fibre REAL,
        source TEXT NOT NULL, recipe_id INTEGER, portion_quantity REAL, portion_unit TEXT,
        portion_weight_grams_per_unit REAL, portion_weight_is_estimate INTEGER,
        portion_weight_source_url TEXT, portion_weight_source_title TEXT,
        portion_weight_source_retrieved_at INTEGER);
      INSERT INTO log_entries (id,date,food_name,grams,kcal,protein,carb,fat,source,
        portion_quantity,portion_unit,portion_weight_grams_per_unit,
        portion_weight_is_estimate,portion_weight_source_url,portion_weight_source_title,
        portion_weight_source_retrieved_at)
        VALUES (1,'2026-07-18','protein powder',30,120,24,3,1,'usda',30,'g',30,0,
          'https://example.com/protein','Protein label',0);
      PRAGMA user_version = 17;
    ''');
    raw.dispose();

    final db = AppDatabase(NativeDatabase(File(path)));
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });
    final log = await db.select(db.logEntries).getSingle();
    expect(log.foodName, 'protein powder');
    expect(log.portionWeightGramsPerUnit, 30);
    expect(log.portionWeightSourceTitle, 'Protein label');
    expect(log.portionWeightUnit, isNull);
  });
}
