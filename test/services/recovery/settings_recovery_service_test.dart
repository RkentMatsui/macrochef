import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/services/recovery/recovery_bootstrap_store.dart';
import 'package:macrochef/services/shared_storage.dart';
import 'package:macrochef/ui/settings/settings_screen.dart';
import 'package:path/path.dart' as p;

class _Shared implements SharedStorage {
  final List<SharedBackup> backups;
  final Map<String, File> files;
  final Set<String> denied;

  _Shared(this.backups, this.files, {this.denied = const {}});

  @override
  Future<List<SharedBackup>> listDownloads(String prefix) async => backups;

  @override
  Future<File> copyToPrivate(SharedBackup backup, File destination) async {
    if (denied.contains(backup.id)) {
      throw const SharedStorageAccessException('access_required', 'pick it');
    }
    return files[backup.id]!.copy(destination.path);
  }

  @override
  Future<SharedDeleteResult> deleteDownload(String id) async =>
      SharedDeleteResult.notFound;

  @override
  Future<String> saveToDownloads(File source, String fileName) async => '';
}

void main() {
  late Directory temp;
  late RecoveryBootstrapStore store;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('settings-recovery-');
    store = RecoveryBootstrapStore(File(p.join(temp.path, 'bootstrap.json')));
  });

  tearDown(() async => temp.delete(recursive: true));

  Future<File> validDatabase(String name) async {
    final file = File(p.join(temp.path, name));
    final db = AppDatabase(NativeDatabase(file));
    await db.customSelect('SELECT 1').getSingle();
    await db.close();
    return file;
  }

  SharedBackup backup(String id, int hour) => SharedBackup(
    id: id,
    name: '$id.sqlite',
    addedAt: DateTime(2026, 7, 12, hour),
  );

  test('stages the next valid backup when the newest is invalid', () async {
    final newest = backup('newest', 12);
    final older = backup('older', 11);
    final invalid = File(p.join(temp.path, 'invalid.sqlite'))
      ..writeAsStringSync('invalid');
    final valid = await validDatabase('valid.sqlite');
    File? staged;
    final service = DefaultSettingsRecoveryService(
      shared: _Shared([older, newest], {newest.id: invalid, older.id: valid}),
      stageRestore: (file) async {
        staged = File(p.join(temp.path, 'staged.sqlite'));
        await file.copy(staged!.path);
        return true;
      },
      bootstrapStore: store,
      workingDirectory: Directory(p.join(temp.path, 'work')),
    );

    final result = await service.recoverLatest();

    expect(result.staged, isTrue);
    expect(staged, isNotNull);
    final record = await store.read();
    expect(record.consumedBackupId, older.id);
    expect(record.consumedBackupName, older.name);
  });

  test('access cancellation is reported without staging', () async {
    final newest = backup('newest', 12);
    var stageCalls = 0;
    final service = DefaultSettingsRecoveryService(
      shared: _Shared([newest], const {}, denied: {newest.id}),
      stageRestore: (_) async {
        stageCalls++;
        return true;
      },
      bootstrapStore: store,
      workingDirectory: Directory(p.join(temp.path, 'work')),
      pickBackupFile: () async => null,
    );

    final result = await service.recoverLatest();

    expect(result.staged, isFalse);
    expect(result.message, 'Backup access was cancelled.');
    expect(stageCalls, 0);
  });

  test(
    'picked older filename records the matching older source identity',
    () async {
      final newest = backup('newest', 12);
      final older = backup('older', 11);
      final valid = await validDatabase(older.name);
      final service = DefaultSettingsRecoveryService(
        shared: _Shared([newest, older], const {}, denied: {newest.id}),
        stageRestore: (_) async => true,
        bootstrapStore: store,
        workingDirectory: Directory(p.join(temp.path, 'work')),
        pickBackupFile: () async => valid,
      );

      final result = await service.recoverLatest();

      expect(result.staged, isTrue);
      expect((await store.read()).consumedBackupId, older.id);
    },
  );
}
