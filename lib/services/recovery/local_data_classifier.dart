import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

import '../exercise_library.dart';
import '../template_seed.dart';

enum LocalDataState { absent, empty, seededOnly, meaningful, ambiguous }

const seedOnlySettingKeys = <String>{
  'starter_templates_seeded',
  'seeded_program_keys',
  'last_auto_backup_ms',
};

const _userTables = <String>{
  'recipes',
  'recipe_ingredients',
  'recipe_steps',
  'recipe_nutrition_cache',
  'food_cache',
  'log_entries',
  'daily_targets',
  'grocery_items',
  'weight_entries',
  'workout_sessions',
  'set_entries',
  'schedule_entries',
  'daily_activity',
};

class LocalDataClassifier {
  const LocalDataClassifier();

  Future<LocalDataState> classify(File file) async {
    if (!await file.exists()) return LocalDataState.absent;

    Database? database;
    try {
      database = sqlite3.open(file.path, mode: OpenMode.readOnly);

      for (final table in _userTables) {
        if (_rowCount(database, table) > 0) return LocalDataState.meaningful;
      }

      final exerciseRows = database.select(
        'SELECT slug, is_custom FROM exercises',
      );
      final builtInSlugs = kBuiltInExercises.map((seed) => seed.slug).toSet();
      for (final row in exerciseRows) {
        final slug = row['slug'] as String?;
        final isCustom = row['is_custom'] as int;
        if (isCustom == 1 || slug == null || !builtInSlugs.contains(slug)) {
          return LocalDataState.meaningful;
        }
      }

      final settingRows = database.select('SELECT key FROM settings');
      for (final row in settingRows) {
        if (!seedOnlySettingKeys.contains(row['key'])) {
          return LocalDataState.meaningful;
        }
      }

      final programCount = _rowCount(database, 'workout_templates');
      final dayCount = _rowCount(database, 'template_days');
      final templateExerciseCount = _rowCount(database, 'template_exercises');
      if (exerciseRows.isEmpty &&
          settingRows.isEmpty &&
          programCount == 0 &&
          dayCount == 0 &&
          templateExerciseCount == 0) {
        return LocalDataState.empty;
      }

      final actualGraph = _databaseStarterGraph(database);
      final expectedGraph = _expectedStarterGraph();
      return actualGraph == expectedGraph
          ? LocalDataState.seededOnly
          : LocalDataState.meaningful;
    } catch (_) {
      return LocalDataState.ambiguous;
    } finally {
      database?.dispose();
    }
  }
}

int _rowCount(Database database, String table) {
  return database.select('SELECT COUNT(*) AS count FROM $table').single['count']
      as int;
}

String _databaseStarterGraph(Database database) {
  final programs = <Map<String, Object?>>[];
  final programRows = database.select(
    'SELECT id, name, notes, position FROM workout_templates '
    'ORDER BY position, id',
  );

  for (final program in programRows) {
    final days = <Map<String, Object?>>[];
    final dayRows = database.select(
      'SELECT id, name, position, notes FROM template_days '
      'WHERE template_id = ? ORDER BY position, id',
      [program['id']],
    );
    for (final day in dayRows) {
      final exercises = <Map<String, Object?>>[];
      final exerciseRows = database.select(
        'SELECT e.slug, te.target_sets, te.target_reps, '
        'te.target_duration_sec, te.target_weight_kg, '
        'te.target_distance_m, te.notes '
        'FROM template_exercises te '
        'JOIN exercises e ON e.id = te.exercise_id '
        'WHERE te.day_id = ? ORDER BY te.position, te.id',
        [day['id']],
      );
      for (final exercise in exerciseRows) {
        exercises.add({
          'slug': exercise['slug'],
          'targetSets': exercise['target_sets'],
          'targetReps': exercise['target_reps'],
          'targetDurationSec': exercise['target_duration_sec'],
          'targetWeightKg': exercise['target_weight_kg'],
          'targetDistanceM': exercise['target_distance_m'],
          'notes': exercise['notes'],
        });
      }
      days.add({
        'name': day['name'],
        'position': day['position'],
        'notes': day['notes'],
        'exercises': exercises,
      });
    }
    programs.add({
      'name': program['name'],
      'notes': program['notes'],
      'position': program['position'],
      'days': days,
    });
  }
  return jsonEncode(programs);
}

String _expectedStarterGraph() {
  final programs = <Map<String, Object?>>[];
  for (
    var programPosition = 0;
    programPosition < kStarterPrograms.length;
    programPosition++
  ) {
    final program = kStarterPrograms[programPosition];
    final days = <Map<String, Object?>>[];
    for (
      var dayPosition = 0;
      dayPosition < program.days.length;
      dayPosition++
    ) {
      final day = program.days[dayPosition];
      days.add({
        'name': day.name,
        'position': dayPosition,
        'notes': null,
        'exercises': [
          for (final exercise in day.exercises)
            {
              'slug': exercise.slug,
              'targetSets': exercise.sets,
              'targetReps': exercise.reps,
              'targetDurationSec': exercise.durationSec,
              'targetWeightKg': null,
              'targetDistanceM': null,
              'notes': null,
            },
        ],
      });
    }
    programs.add({
      'name': program.name,
      'notes': program.notes,
      'position': programPosition,
      'days': days,
    });
  }
  return jsonEncode(programs);
}
