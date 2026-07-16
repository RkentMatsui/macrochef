import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/services/backup_service.dart';
import 'package:macrochef/services/recovery/backup_candidate_validator.dart';
import 'package:macrochef/services/shared_storage.dart';
import 'package:path/path.dart' as p;

/// Minimal valid SQLite header + padding, enough for [BackupIO.isSqliteFile].
final _sqliteBytes = <int>[
  ...'SQLite format 3'.codeUnits, 0x00, // 16-byte magic
  ...List.filled(84, 0), // pad past the 100-byte header
];

void main() {
  late Directory tmp;

  setUp(() => tmp = Directory.systemTemp.createTempSync('backup_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  File write(String name, List<int> bytes) {
    final f = File(p.join(tmp.path, name));
    f.writeAsBytesSync(bytes);
    return f;
  }

  Future<File> writeDatabase(String name) async {
    final file = File(p.join(tmp.path, name));
    final db = AppDatabase(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await db.close();
    return file;
  }

  group('BackupIO.isSqliteFile', () {
    test('true for a file with the SQLite magic header', () async {
      expect(
        await BackupIO.isSqliteFile(write('a.sqlite', _sqliteBytes)),
        isTrue,
      );
    });
    test('false for a non-sqlite file', () async {
      expect(
        await BackupIO.isSqliteFile(
          write('a.txt', 'hello world!!!!!'.codeUnits),
        ),
        isFalse,
      );
    });
    test('false for a missing file', () async {
      expect(
        await BackupIO.isSqliteFile(File(p.join(tmp.path, 'nope'))),
        isFalse,
      );
    });
    test('false for a too-short file', () async {
      expect(
        await BackupIO.isSqliteFile(write('short', [0x53, 0x51])),
        isFalse,
      );
    });
  });

  group('BackupIO.replaceDatabase', () {
    test('overwrites the db and deletes stale -wal/-shm sidecars', () async {
      final db = write('macrochef.sqlite', 'OLD'.codeUnits);
      final wal = write('macrochef.sqlite-wal', 'stale'.codeUnits);
      final shm = write('macrochef.sqlite-shm', 'stale'.codeUnits);
      final src = write('backup.sqlite', _sqliteBytes);

      await BackupIO.replaceDatabase(source: src, dbFile: db);

      expect(db.readAsBytesSync(), _sqliteBytes);
      expect(wal.existsSync(), isFalse);
      expect(shm.existsSync(), isFalse);
    });

    test('creates the db file when none exists yet', () async {
      final db = File(p.join(tmp.path, 'sub', 'macrochef.sqlite'));
      final src = write('backup.sqlite', _sqliteBytes);
      await BackupIO.replaceDatabase(source: src, dbFile: db);
      expect(db.existsSync(), isTrue);
      expect(db.readAsBytesSync(), _sqliteBytes);
    });
  });

  group('BackupIO.replaceWithRollback', () {
    test('applies a replacement that passes verification', () async {
      final live = write('macrochef.sqlite', 'ORIGINAL'.codeUnits);
      final candidate = await writeDatabase('candidate.sqlite');
      const validator = BackupCandidateValidator();

      final result = await BackupIO.replaceWithRollback(
        source: candidate,
        dbFile: live,
        verify: (file) async =>
            validator.validate(file).then((value) => value.isValid),
      );

      expect(result, RestoreReplacementResult.applied);
      expect((await validator.validate(live)).isValid, isTrue);
      expect(candidate.existsSync(), isTrue);
      expect(
        File(p.join(tmp.path, 'macrochef.rollback.sqlite')).existsSync(),
        isFalse,
      );
    });

    test(
      'restores the original when verification corrupts the replacement',
      () async {
        final original = 'ORIGINAL'.codeUnits;
        final live = write('macrochef.sqlite', original);
        final wal = write('macrochef.sqlite-wal', 'stale'.codeUnits);
        final shm = write('macrochef.sqlite-shm', 'stale'.codeUnits);
        final candidate = await writeDatabase('candidate.sqlite');
        const validator = BackupCandidateValidator();

        final result = await BackupIO.replaceWithRollback(
          source: candidate,
          dbFile: live,
          verify: (file) async {
            expect((await validator.validate(file)).isValid, isTrue);
            await file.writeAsString('corrupt', flush: true);
            return false;
          },
        );

        expect(result, RestoreReplacementResult.verificationFailed);
        expect(live.readAsBytesSync(), original);
        expect(wal.existsSync(), isFalse);
        expect(shm.existsSync(), isFalse);
        expect(candidate.existsSync(), isTrue);
      },
    );

    test('retains the rollback when restoring it fails', () async {
      final original = 'ORIGINAL'.codeUnits;
      final live = write('macrochef.sqlite', original);
      final candidate = await writeDatabase('candidate.sqlite');
      final rollback = File(p.join(tmp.path, 'macrochef.rollback.sqlite'));

      await expectLater(
        BackupIO.replaceWithRollback(
          source: candidate,
          dbFile: live,
          verify: (file) async {
            await file.delete();
            await Directory(file.path).create();
            return false;
          },
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(rollback.existsSync(), isTrue);
      expect(rollback.readAsBytesSync(), original);
    });
  });

  group('BackupIO.applyPending', () {
    test('applies a staged file then removes it', () async {
      final staging = write('macrochef.import.sqlite', _sqliteBytes);
      final db = write('macrochef.sqlite', 'OLD'.codeUnits);

      final applied = await BackupIO.applyPending(staging: staging, dbFile: db);

      expect(applied, isTrue);
      expect(db.readAsBytesSync(), _sqliteBytes);
      expect(staging.existsSync(), isFalse); // consumed
    });

    test('no-op (returns false) when nothing is staged', () async {
      final staging = File(p.join(tmp.path, 'macrochef.import.sqlite'));
      final db = write('macrochef.sqlite', 'KEEP'.codeUnits);

      final applied = await BackupIO.applyPending(staging: staging, dbFile: db);

      expect(applied, isFalse);
      expect(db.readAsStringSync(), 'KEEP'); // untouched
    });
  });

  test('manual and automatic names are stamped and distinct', () {
    final when = DateTime(2026, 7, 8, 9, 5);
    expect(
      BackupService.manualFileName(when),
      'macrochef-manual-20260708-0905.sqlite',
    );
    expect(
      BackupService.automaticFileName(when),
      'macrochef-auto-20260708-0905.sqlite',
    );
  });

  test(
    'manual publisher validates and saves a manual-named snapshot',
    () async {
      final shared = _RecordingSharedStorage();
      final publisher = ManualBackupPublisher(
        temporaryDirectory: () async => tmp,
        exportSnapshot: (destination) async {
          await destination.writeAsBytes(_sqliteBytes);
          return destination;
        },
        sharedStorage: shared,
      );

      final result = await publisher.save(DateTime(2026, 7, 15, 14, 30));

      expect(result.fileName, 'macrochef-manual-20260715-1430.sqlite');
      expect(result.downloadsId, 'content://manual');
      expect(shared.saved, [result.fileName]);
    },
  );
}

class _RecordingSharedStorage implements SharedStorage {
  final List<String> saved = [];

  @override
  Future<File> copyToPrivate(SharedBackup backup, File destination) async =>
      destination;

  @override
  Future<SharedDeleteResult> deleteDownload(String id) async =>
      SharedDeleteResult.notFound;

  @override
  Future<List<SharedBackup>> listDownloads(String prefix) async => const [];

  @override
  Future<String> saveToDownloads(File source, String fileName) async {
    saved.add(fileName);
    return 'content://manual';
  }
}
