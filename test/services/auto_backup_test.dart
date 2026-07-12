import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/auto_backup.dart';
import 'package:macrochef/services/shared_storage.dart';
import 'package:path/path.dart' as p;

/// Records calls; can be told to throw on save to test best-effort behaviour.
class FakeSharedStorage implements SharedStorage {
  final List<String> saved = [];
  final List<String> deleted = [];
  List<SharedBackup> existing;
  bool throwOnSave;
  bool throwOnList;
  FakeSharedStorage({
    this.existing = const [],
    this.throwOnSave = false,
    this.throwOnList = false,
  });

  @override
  Future<String> saveToDownloads(File source, String fileName) async {
    if (throwOnSave) throw const FileSystemException('no downloads');
    saved.add(fileName);
    return 'content://$fileName';
  }

  @override
  Future<List<SharedBackup>> listDownloads(String prefix) async {
    if (throwOnList) throw const FileSystemException('cannot prune');
    return existing;
  }

  @override
  Future<File> copyToPrivate(SharedBackup backup, File destination) async {
    return File(backup.id).copy(destination.path);
  }

  @override
  Future<SharedDeleteResult> deleteDownload(String id) async {
    deleted.add(id);
    return SharedDeleteResult.deleted;
  }
}

void main() {
  group('pure policy', () {
    final now = DateTime(2026, 7, 10, 12);

    test('shouldRunAutoBackup: null last → true', () {
      expect(shouldRunAutoBackup(last: null, now: now), isTrue);
    });
    test('shouldRunAutoBackup: recent → false', () {
      expect(
        shouldRunAutoBackup(
          last: now.subtract(const Duration(hours: 1)),
          now: now,
        ),
        isFalse,
      );
    });
    test('shouldRunAutoBackup: old → true', () {
      expect(
        shouldRunAutoBackup(
          last: now.subtract(const Duration(hours: 13)),
          now: now,
        ),
        isTrue,
      );
    });

    test('isDriveBackupStale: null → true, recent → false, old → true', () {
      expect(isDriveBackupStale(lastDrive: null, now: now), isTrue);
      expect(
        isDriveBackupStale(
          lastDrive: now.subtract(const Duration(days: 1)),
          now: now,
        ),
        isFalse,
      );
      expect(
        isDriveBackupStale(
          lastDrive: now.subtract(const Duration(days: 8)),
          now: now,
        ),
        isTrue,
      );
    });

    test('pruneTargets keeps last N, returns overflow', () {
      expect(pruneTargets([1, 2, 3], keepLast: 5), isEmpty);
      expect(pruneTargets([5, 4, 3, 2, 1, 0], keepLast: 5), [0]);
    });
  });

  group('AutoBackupService.runOnLaunch', () {
    late Directory tmp;
    late Map<String, String> settings;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('autobackup_test');
      settings = {};
    });
    tearDown(() async {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    });

    AutoBackupService build(
      FakeSharedStorage shared, {
      String Function(DateTime)? fileName,
    }) => AutoBackupService(
      exportSnapshot: (dest) async {
        await dest.writeAsString('SQLite fake');
        return dest;
      },
      shared: shared,
      getSetting: (k) async => settings[k],
      setSetting: (k, v) async => settings[k] = v,
      localBackupDir: () async => tmp,
      fileName: fileName ?? (dt) => 'macrochef-backup-live.sqlite',
    );

    test(
      'first run exports, mirrors to Downloads, and records timestamp',
      () async {
        final shared = FakeSharedStorage();
        final result = await build(
          shared,
        ).runOnLaunch(DateTime(2026, 7, 10, 12));

        expect(result.status, AutoBackupRunStatus.saved);
        expect(
          result.downloadsBackupId,
          'content://macrochef-backup-live.sqlite',
        );
        expect(
          File(p.join(tmp.path, 'macrochef-backup-live.sqlite')).existsSync(),
          isTrue,
        );
        expect(shared.saved, ['macrochef-backup-live.sqlite']);
        expect(settings[kLastAutoBackupMsKey], isNotNull);
      },
    );

    test('throttled run does nothing when last backup is recent', () async {
      final now = DateTime(2026, 7, 10, 12);
      settings[kLastAutoBackupMsKey] = now
          .subtract(const Duration(hours: 1))
          .millisecondsSinceEpoch
          .toString();
      final shared = FakeSharedStorage();
      final result = await build(shared).runOnLaunch(now);

      expect(result.status, AutoBackupRunStatus.skipped);
      expect(shared.saved, isEmpty);
      expect(tmp.listSync(), isEmpty);
    });

    test('force bypasses the throttle and returns the saved URI', () async {
      final now = DateTime(2026, 7, 11, 12);
      settings[kLastAutoBackupMsKey] = now.millisecondsSinceEpoch.toString();
      final shared = FakeSharedStorage();
      final result = await build(
        shared,
        fileName: (_) => 'macrochef-backup-20260711-1200.sqlite',
      ).runOnLaunch(now, force: true);

      expect(result.status, AutoBackupRunStatus.saved);
      expect(
        result.downloadsBackupId,
        'content://macrochef-backup-20260711-1200.sqlite',
      );
      expect(shared.saved.single, startsWith('macrochef-backup-'));
      expect(shared.saved.single, endsWith('.sqlite'));
    });

    test(
      'prune failure warns without hiding a successful fresh backup',
      () async {
        final shared = FakeSharedStorage(throwOnList: true);
        final result = await build(
          shared,
        ).runOnLaunch(DateTime(2026, 7, 10, 12));

        expect(result.status, AutoBackupRunStatus.saved);
        expect(
          result.downloadsBackupId,
          'content://macrochef-backup-live.sqlite',
        );
        expect(result.warning, isNotNull);
      },
    );

    test('rotates local snapshots down to kBackupKeepLast', () async {
      // Pre-seed 5 older snapshots (older names sort lower).
      for (var i = 0; i < kBackupKeepLast; i++) {
        File(
          p.join(tmp.path, 'macrochef-backup-20200101-000$i.sqlite'),
        ).writeAsStringSync('old');
      }
      final shared = FakeSharedStorage();
      // New snapshot name sorts newest.
      await build(
        shared,
        fileName: (_) => 'macrochef-backup-20260710-1200.sqlite',
      ).runOnLaunch(DateTime(2026, 7, 10, 12));

      final remaining =
          tmp
              .listSync()
              .whereType<File>()
              .map((f) => p.basename(f.path))
              .toList()
            ..sort();
      expect(remaining.length, kBackupKeepLast);
      expect(
        remaining.contains('macrochef-backup-20260710-1200.sqlite'),
        isTrue,
      );
      // Oldest was pruned.
      expect(
        remaining.contains('macrochef-backup-20200101-0000.sqlite'),
        isFalse,
      );
    });

    test('prunes Downloads beyond keepLast', () async {
      final existing = [
        for (var i = 8; i >= 1; i--)
          SharedBackup(
            id: 'id$i',
            name: 'macrochef-backup-$i',
            addedAt: DateTime(2026),
          ),
      ]; // 8 existing, newest-first
      final shared = FakeSharedStorage(existing: existing);
      await build(shared).runOnLaunch(DateTime(2026, 7, 10, 12));

      // 8 existing → keep 5, delete the 3 oldest (tail of newest-first list).
      expect(shared.deleted, ['id3', 'id2', 'id1']);
    });

    test(
      'Downloads failure is swallowed; local snapshot + timestamp still succeed',
      () async {
        final shared = FakeSharedStorage(throwOnSave: true);
        final result = await build(
          shared,
        ).runOnLaunch(DateTime(2026, 7, 10, 12));

        expect(result.status, AutoBackupRunStatus.localOnly);
        expect(
          File(p.join(tmp.path, 'macrochef-backup-live.sqlite')).existsSync(),
          isTrue,
        );
        expect(settings[kLastAutoBackupMsKey], isNotNull);
      },
    );
  });
}
