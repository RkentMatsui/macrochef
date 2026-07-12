import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/auto_backup.dart';
import 'package:macrochef/services/recovery/recovery_bootstrap_store.dart';
import 'package:macrochef/services/recovery/recovery_finalizer.dart';
import 'package:macrochef/services/shared_storage.dart';
import 'package:path/path.dart' as p;

class _Shared implements SharedStorage {
  final SharedDeleteResult deleteResult;
  bool failSave;
  bool failDelete;
  final List<String> saved = [];
  final List<String> deleted = [];

  _Shared({
    this.deleteResult = SharedDeleteResult.deleted,
    this.failSave = false,
    this.failDelete = false,
  });

  @override
  Future<String> saveToDownloads(File source, String fileName) async {
    if (failSave) throw const FileSystemException('save failed');
    saved.add(fileName);
    return 'content://fresh';
  }

  @override
  Future<SharedDeleteResult> deleteDownload(String id) async {
    deleted.add(id);
    if (failDelete) throw const FileSystemException('delete failed');
    return deleteResult;
  }

  @override
  Future<List<SharedBackup>> listDownloads(String prefix) async => const [];

  @override
  Future<File> copyToPrivate(SharedBackup backup, File destination) async =>
      destination;
}

void main() {
  late Directory tmp;
  late RecoveryBootstrapStore store;
  late Map<String, String> settings;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('recovery_finalizer_test');
    store = RecoveryBootstrapStore(File(p.join(tmp.path, 'marker.json')));
    settings = {};
  });

  tearDown(() async => tmp.delete(recursive: true));

  RecoveryFinalizer build(_Shared shared) {
    final autoBackup = AutoBackupService(
      exportSnapshot: (destination) =>
          destination.writeAsString('snapshot').then((_) => destination),
      shared: shared,
      getSetting: (key) async => settings[key],
      setSetting: (key, value) async => settings[key] = value,
      localBackupDir: () async => Directory(p.join(tmp.path, 'backups')),
      fileName: (_) => 'macrochef-backup-20260711-1200.sqlite',
    );
    return RecoveryFinalizer(
      store: store,
      autoBackup: autoBackup,
      shared: shared,
    );
  }

  test('no recovery pending does no work', () async {
    final shared = _Shared();

    expect(await build(shared).run(DateTime(2026, 7, 11, 12)), isFalse);
    expect(shared.saved, isEmpty);
    expect(shared.deleted, isEmpty);
  });

  for (final deleteResult in SharedDeleteResult.values) {
    test(
      'fresh backup plus ${deleteResult.name} initializes recovery',
      () async {
        await store.write(
          const RecoveryBootstrapRecord(
            status: RecoveryBootstrapStatus.recoveryApplied,
            consumedBackupId: 'content://consumed',
          ),
        );
        final shared = _Shared(deleteResult: deleteResult);

        expect(await build(shared).run(DateTime(2026, 7, 11, 12)), isTrue);
        expect(shared.saved, ['macrochef-backup-20260711-1200.sqlite']);
        expect(shared.deleted, ['content://consumed']);
        expect(
          (await store.read()).status,
          RecoveryBootstrapStatus.initialized,
        );
      },
    );
  }

  test(
    'failed fresh backup retains recovery and does not delete source',
    () async {
      await store.write(
        const RecoveryBootstrapRecord(
          status: RecoveryBootstrapStatus.recoveryApplied,
          consumedBackupId: 'content://consumed',
        ),
      );
      final shared = _Shared(failSave: true);

      expect(await build(shared).run(DateTime(2026, 7, 11, 12)), isTrue);
      expect(shared.deleted, isEmpty);
      expect(
        (await store.read()).status,
        RecoveryBootstrapStatus.recoveryApplied,
      );
    },
  );

  test(
    'second run after initialization creates and deletes nothing again',
    () async {
      await store.write(
        const RecoveryBootstrapRecord(
          status: RecoveryBootstrapStatus.recoveryApplied,
          consumedBackupId: 'content://consumed',
        ),
      );
      final shared = _Shared();
      final finalizer = build(shared);

      expect(await finalizer.run(DateTime(2026, 7, 11, 12)), isTrue);
      expect(await finalizer.run(DateTime(2026, 7, 11, 12)), isFalse);
      expect(shared.saved, hasLength(1));
      expect(shared.deleted, ['content://consumed']);
    },
  );

  test('thrown source deletion still initializes after fresh backup', () async {
    await store.write(
      const RecoveryBootstrapRecord(
        status: RecoveryBootstrapStatus.recoveryApplied,
        consumedBackupId: 'content://consumed',
      ),
    );
    final shared = _Shared(failDelete: true);

    expect(await build(shared).run(DateTime(2026, 7, 11, 12)), isTrue);
    expect(shared.saved, ['macrochef-backup-20260711-1200.sqlite']);
    expect(shared.deleted, ['content://consumed']);
    expect((await store.read()).status, RecoveryBootstrapStatus.initialized);
  });
}
