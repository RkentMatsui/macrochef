import 'dart:io';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../data/database.dart';

enum BackupValidationCode {
  valid,
  missing,
  notSqlite,
  corrupt,
  wrongSchema,
  unsupportedVersion,
}

class BackupValidation {
  final BackupValidationCode code;
  final String? detail;

  bool get isValid => code == BackupValidationCode.valid;

  const BackupValidation(this.code, [this.detail]);
}

const requiredMacroChefTables = <String>{
  'recipes',
  'recipe_ingredients',
  'recipe_steps',
  'food_cache',
  'log_entries',
  'daily_targets',
  'settings',
  'grocery_items',
  'weight_entries',
  'exercises',
  'workout_sessions',
  'set_entries',
  'workout_templates',
  'template_days',
  'template_exercises',
  'schedule_entries',
  'daily_activity',
  'recipe_nutrition_cache',
};

Set<String> requiredMacroChefTablesForVersion(int version) => {
  'recipes',
  'recipe_ingredients',
  'recipe_steps',
  'food_cache',
  'log_entries',
  'daily_targets',
  'settings',
  if (version >= 2) 'grocery_items',
  if (version >= 4) 'weight_entries',
  if (version >= 6) ...{'exercises', 'workout_sessions', 'set_entries'},
  if (version >= 7) ...{'workout_templates', 'template_exercises'},
  if (version >= 8) 'schedule_entries',
  if (version >= 9) 'daily_activity',
  if (version >= 10) 'template_days',
  if (version >= 13) 'recipe_nutrition_cache',
};

class BackupCandidateValidator {
  const BackupCandidateValidator();

  Future<BackupValidation> validate(File file) async {
    if (!await file.exists()) {
      return const BackupValidation(BackupValidationCode.missing);
    }

    final header = await file
        .openRead(0, 16)
        .fold<List<int>>(<int>[], (bytes, chunk) => bytes..addAll(chunk));
    const sqliteHeader = <int>[
      0x53,
      0x51,
      0x4c,
      0x69,
      0x74,
      0x65,
      0x20,
      0x66,
      0x6f,
      0x72,
      0x6d,
      0x61,
      0x74,
      0x20,
      0x33,
      0x00,
    ];
    if (header.length != sqliteHeader.length ||
        !_sameBytes(header, sqliteHeader)) {
      return const BackupValidation(BackupValidationCode.notSqlite);
    }

    Database? database;
    try {
      database = sqlite3.open(file.path, mode: OpenMode.readOnly);

      final integrity = database.select('PRAGMA integrity_check');
      if (integrity.isEmpty || integrity.first.values.first != 'ok') {
        final detail = integrity.isEmpty
            ? 'Integrity check returned no result.'
            : integrity.map((row) => row.values.first).join('; ');
        return BackupValidation(BackupValidationCode.corrupt, detail);
      }

      final version =
          database.select('PRAGMA user_version').first.values.first as int;
      final currentVersion = await _currentSchemaVersion();
      if (version > currentVersion) {
        return BackupValidation(
          BackupValidationCode.unsupportedVersion,
          'Database schema $version is newer than supported schema '
          '$currentVersion.',
        );
      }
      if (version < 1) {
        return BackupValidation(
          BackupValidationCode.wrongSchema,
          'Invalid MacroChef schema version: $version.',
        );
      }

      final tableRows = database.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final tables = tableRows.map((row) => row['name'] as String).toSet();
      final missingTables = requiredMacroChefTablesForVersion(
        version,
      ).difference(tables);
      if (missingTables.isNotEmpty) {
        final sorted = missingTables.toList()..sort();
        return BackupValidation(
          BackupValidationCode.wrongSchema,
          'Missing required tables: ${sorted.join(', ')}.',
        );
      }

      return const BackupValidation(BackupValidationCode.valid);
    } on SqliteException catch (error) {
      return BackupValidation(BackupValidationCode.corrupt, error.message);
    } finally {
      database?.dispose();
    }
  }
}

bool _sameBytes(List<int> left, List<int> right) {
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

Future<int> _currentSchemaVersion() async {
  final database = AppDatabase(NativeDatabase.memory());
  try {
    return database.schemaVersion;
  } finally {
    await database.close();
  }
}
