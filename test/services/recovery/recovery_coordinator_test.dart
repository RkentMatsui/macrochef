import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/recovery/backup_candidate_validator.dart';
import 'package:macrochef/services/recovery/local_data_classifier.dart';
import 'package:macrochef/services/recovery/recovery_bootstrap_store.dart';
import 'package:macrochef/services/recovery/recovery_coordinator.dart';
import 'package:macrochef/services/shared_storage.dart';
import 'package:path/path.dart' as p;

class _Shared implements SharedStorage {
  final List<SharedBackup> backups;
  final Map<String, File> files;
  final Set<String> denied;
  _Shared(this.backups, this.files, [this.denied = const {}]);
  @override
  Future<List<SharedBackup>> listDownloads(String prefix) async => backups;
  @override
  Future<File> copyToPrivate(SharedBackup backup, File destination) async {
    if (denied.contains(backup.id)) {
      throw const SharedStorageAccessException('access_required', 'pick file');
    }
    return files[backup.id]!.copy(destination.path);
  }

  @override
  Future<SharedDeleteResult> deleteDownload(String id) async =>
      SharedDeleteResult.deleted;
  @override
  Future<String> saveToDownloads(File source, String fileName) async =>
      'unused';
}

class _Validator extends BackupCandidateValidator {
  final Set<String> invalidNames;
  const _Validator([this.invalidNames = const {}]);
  @override
  Future<BackupValidation> validate(File file) async =>
      invalidNames.contains(p.basename(file.path)) || !await file.exists()
      ? const BackupValidation(BackupValidationCode.corrupt)
      : const BackupValidation(BackupValidationCode.valid);
}

class _Classifier extends LocalDataClassifier {
  final LocalDataState state;
  const _Classifier(this.state);
  @override
  Future<LocalDataState> classify(File file) async => state;
}

void main() {
  late Directory tmp;
  late File live;
  late File pending;
  late RecoveryBootstrapStore store;
  final backup = SharedBackup(
    id: 'one',
    name: 'macrochef-backup-one.sqlite',
    addedAt: DateTime(2026),
  );

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('recovery-coordinator-');
    live = File(p.join(tmp.path, 'macrochef.sqlite'));
    pending = File(p.join(tmp.path, 'macrochef.import.sqlite'));
    store = RecoveryBootstrapStore(File(p.join(tmp.path, 'bootstrap.json')));
  });
  tearDown(() async => tmp.delete(recursive: true));

  RecoveryCoordinator coordinator({
    LocalDataState local = LocalDataState.empty,
    List<SharedBackup>? backups,
    Map<String, File>? files,
    Set<String> denied = const {},
    Set<String> invalid = const {},
  }) {
    return RecoveryCoordinator(
      bootstrapStore: store,
      sharedStorage: _Shared(backups ?? [backup], files ?? {}, denied),
      validator: _Validator(invalid),
      classifier: _Classifier(local),
      liveDatabase: live,
      pendingRestore: pending,
      privateCandidate: (b) => File(p.join(tmp.path, b.name)),
    );
  }

  test('initialized bootstrap skips recovery', () async {
    final c = coordinator();
    await store.write(
      const RecoveryBootstrapRecord(
        status: RecoveryBootstrapStatus.initialized,
      ),
    );
    expect(await c.prepare(), isA<RecoverySkip>());
  });

  test(
    'empty live data auto-restores and meaningful data asks confirmation',
    () async {
      final source = File(p.join(tmp.path, 'source'))
        ..writeAsStringSync('valid');
      expect(
        await coordinator(files: {'one': source}).prepare(),
        isA<RecoveryAutoRestore>(),
      );
      expect(
        await coordinator(
          local: LocalDataState.meaningful,
          files: {'one': source},
        ).prepare(),
        isA<RecoveryConfirmRestore>(),
      );
    },
  );

  test('copy access denial requests user-selected file', () async {
    expect(
      await coordinator(denied: {'one'}).prepare(),
      isA<RecoveryNeedsFileAccess>(),
    );
  });

  test(
    'no visible MediaStore backups requests file access after reinstall',
    () async {
      final result = await coordinator(backups: const []).prepare();

      expect(result, isA<RecoveryNeedsFileAccess>());
      expect((result as RecoveryNeedsFileAccess).backup.id, isEmpty);
      expect((await store.read()).status, RecoveryBootstrapStatus.newInstall);
    },
  );

  test('selected file becomes an automatic restore candidate', () async {
    final picked = File(p.join(tmp.path, 'picked'))..writeAsStringSync('valid');
    expect(
      await coordinator().prepareSelectedFile(backup, picked),
      isA<RecoveryAutoRestore>(),
    );
  });

  test(
    'ownerless selected file restores without recording a deletable URI',
    () async {
      final picked = File(p.join(tmp.path, 'picked', 'picked-ownerless.sqlite'))
        ..parent.createSync()
        ..writeAsStringSync('valid');
      final access =
          await coordinator(backups: const []).prepare()
              as RecoveryNeedsFileAccess;
      final prepared =
          await coordinator().prepareSelectedFile(access.backup, picked)
              as RecoveryAutoRestore;

      expect(await coordinator().restore(prepared), isTrue);
      final record = await store.read();
      expect(record.status, RecoveryBootstrapStatus.recoveryApplied);
      expect(record.consumedBackupId, isNull);
      expect(record.consumedBackupName, p.basename(picked.path));
    },
  );

  test('manual pending restore takes precedence over downloads', () async {
    pending.writeAsStringSync('pending');
    final result = await coordinator(backups: const []).prepare();
    expect(result, isA<RecoveryAutoRestore>());
    expect((result as RecoveryAutoRestore).candidate.path, pending.path);
  });

  test('invalid newest candidate falls back to next valid backup', () async {
    final newest = SharedBackup(
      id: 'new',
      name: 'new.sqlite',
      addedAt: DateTime(2026, 2),
    );
    final older = SharedBackup(
      id: 'old',
      name: 'old.sqlite',
      addedAt: DateTime(2026, 1),
    );
    final newFile = File(p.join(tmp.path, 'new-source'))
      ..writeAsStringSync('bad');
    final oldFile = File(p.join(tmp.path, 'old-source'))
      ..writeAsStringSync('ok');
    final result = await coordinator(
      backups: [newest, older],
      files: {'new': newFile, 'old': oldFile},
      invalid: {'new.sqlite'},
    ).prepare();
    expect((result as RecoveryAutoRestore).backup.id, 'old');
  });

  test('decline records state and applied state skips reapplication', () async {
    final c = coordinator();
    await c.decline();
    expect(
      (await store.read()).status,
      RecoveryBootstrapStatus.recoveryDeclined,
    );
    await store.write(
      const RecoveryBootstrapRecord(
        status: RecoveryBootstrapStatus.recoveryApplied,
      ),
    );
    expect(await c.prepare(), isA<RecoverySkip>());
  });

  test(
    'failed replacement verification returns false and keeps source',
    () async {
      final source = File(p.join(tmp.path, 'source'))
        ..writeAsStringSync('valid');
      live.writeAsStringSync('original');
      final c = coordinator(
        files: {'one': source},
        invalid: {'macrochef.sqlite'},
      );
      final prepared = await c.prepare() as RecoveryAutoRestore;
      expect(await c.restore(prepared), isFalse);
      expect(source.existsSync(), isTrue);
      expect(live.readAsStringSync(), 'original');
    },
  );
}
