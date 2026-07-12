import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/settings_repository.dart';
import 'package:macrochef/data/repositories/training_repository.dart';
import 'package:macrochef/services/exercise_library.dart';
import 'package:macrochef/services/recovery/local_data_classifier.dart';
import 'package:macrochef/services/template_seed.dart';

void main() {
  late Directory tempDir;
  late File candidate;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('macrochef-classifier-');
    candidate = File('${tempDir.path}${Platform.pathSeparator}local.db');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  const classifier = LocalDataClassifier();

  Future<AppDatabase> createDatabase() async {
    final db = AppDatabase(NativeDatabase(candidate));
    await db.customSelect('SELECT 1').getSingle();
    return db;
  }

  Future<AppDatabase> createSeededDatabase() async {
    final db = await createDatabase();
    final training = TrainingRepository(db);
    await seedExercises(training);
    await seedStarterPrograms(training, SettingsRepository(db));
    return db;
  }

  test('classifies a missing database as absent', () async {
    expect(await classifier.classify(candidate), LocalDataState.absent);
  });

  test('classifies a schema-only database as empty', () async {
    final db = await createDatabase();
    await db.close();
    expect(await classifier.classify(candidate), LocalDataState.empty);
  });

  test('classifies exact built-in and starter seeds as seeded-only', () async {
    final db = await createSeededDatabase();
    await db.close();
    expect(await classifier.classify(candidate), LocalDataState.seededOnly);
  });

  test('classifies a user recipe as meaningful', () async {
    final db = await createSeededDatabase();
    await db.into(db.recipes).insert(RecipesCompanion.insert(title: 'Dinner'));
    await db.close();
    expect(await classifier.classify(candidate), LocalDataState.meaningful);
  });

  test('classifies a custom exercise as meaningful', () async {
    final db = await createSeededDatabase();
    await db.customStatement(
      "INSERT INTO exercises (name, category, is_custom) "
      "VALUES ('My Lift', 'strength', 1)",
    );
    await db.close();
    expect(await classifier.classify(candidate), LocalDataState.meaningful);
  });

  test('classifies an edited starter program as meaningful', () async {
    final db = await createSeededDatabase();
    await db.customStatement(
      "UPDATE workout_templates SET name = 'My Edited Plan' "
      'WHERE id = (SELECT MIN(id) FROM workout_templates)',
    );
    await db.close();
    expect(await classifier.classify(candidate), LocalDataState.meaningful);
  });

  test('classifies an unknown setting as meaningful', () async {
    final db = await createSeededDatabase();
    await SettingsRepository(db).set('user_preference', 'enabled');
    await db.close();
    expect(await classifier.classify(candidate), LocalDataState.meaningful);
  });

  test('classifies malformed local data as ambiguous', () async {
    await candidate.writeAsString('not sqlite');
    expect(await classifier.classify(candidate), LocalDataState.ambiguous);
  });
}
