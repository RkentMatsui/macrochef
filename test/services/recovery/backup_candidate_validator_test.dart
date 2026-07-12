import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/services/recovery/backup_candidate_validator.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory tempDir;
  late File candidate;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('macrochef-validator-');
    candidate = File('${tempDir.path}${Platform.pathSeparator}candidate.db');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  const validator = BackupCandidateValidator();

  test('reports a missing candidate', () async {
    final result = await validator.validate(candidate);
    expect(result.code, BackupValidationCode.missing);
    expect(result.isValid, isFalse);
  });

  test('rejects bytes without the SQLite header', () async {
    await candidate.writeAsString('this is not a sqlite database');
    final result = await validator.validate(candidate);
    expect(result.code, BackupValidationCode.notSqlite);
  });

  test('rejects a SQLite file that fails integrity checking', () async {
    final db = sqlite3.open(candidate.path);
    db.execute('CREATE TABLE payload (value TEXT)');
    db.execute("INSERT INTO payload VALUES (zeroblob(16000))");
    db.dispose();

    final bytes = await candidate.readAsBytes();
    final pageSize = (bytes[16] << 8) | bytes[17];
    final corruptAt = pageSize == 1 ? 65536 : pageSize;
    bytes.setRange(corruptAt, corruptAt + 32, Uint8List(32));
    await candidate.writeAsBytes(bytes, flush: true);

    final result = await validator.validate(candidate);
    expect(result.code, BackupValidationCode.corrupt);
  });

  test('rejects a healthy database missing MacroChef core tables', () async {
    final db = sqlite3.open(candidate.path);
    db.execute('CREATE TABLE unrelated (id INTEGER PRIMARY KEY)');
    db.execute('PRAGMA user_version = 1');
    db.dispose();

    final result = await validator.validate(candidate);
    expect(result.code, BackupValidationCode.wrongSchema);
    expect(result.detail, contains('recipes'));
  });

  test('rejects databases from a future schema version', () async {
    final db = sqlite3.open(candidate.path);
    for (final table in requiredMacroChefTables) {
      db.execute('CREATE TABLE $table (id INTEGER)');
    }
    final driftDb = AppDatabase(NativeDatabase.memory());
    final futureVersion = driftDb.schemaVersion + 1;
    await driftDb.close();
    db.execute('PRAGMA user_version = $futureVersion');
    db.dispose();

    final result = await validator.validate(candidate);
    expect(result.code, BackupValidationCode.unsupportedVersion);
  });

  test('accepts a version 1 MacroChef database without later tables', () async {
    final db = sqlite3.open(candidate.path);
    for (final table in const {
      'recipes',
      'recipe_ingredients',
      'recipe_steps',
      'food_cache',
      'log_entries',
      'daily_targets',
      'settings',
    }) {
      db.execute('CREATE TABLE $table (id INTEGER)');
    }
    db.execute('PRAGMA user_version = 1');
    db.dispose();

    final result = await validator.validate(candidate);
    expect(result.code, BackupValidationCode.valid);
  });

  test(
    'version 6 requires the workout tables introduced in version 6',
    () async {
      final db = sqlite3.open(candidate.path);
      for (final table in requiredMacroChefTablesForVersion(5)) {
        db.execute('CREATE TABLE $table (id INTEGER)');
      }
      db.execute('PRAGMA user_version = 6');
      db.dispose();

      final result = await validator.validate(candidate);
      expect(result.code, BackupValidationCode.wrongSchema);
      expect(result.detail, contains('exercises'));
    },
  );

  test('accepts a valid MacroChef database', () async {
    final db = AppDatabase(NativeDatabase(candidate));
    await db.customSelect('SELECT 1').getSingle();
    await db.close();

    final result = await validator.validate(candidate);
    expect(result.code, BackupValidationCode.valid);
    expect(result.isValid, isTrue);
  });
}
