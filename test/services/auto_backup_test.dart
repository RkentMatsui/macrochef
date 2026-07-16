import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/auto_backup.dart';
import 'package:macrochef/services/shared_storage.dart';
import 'package:path/path.dart' as p;

final _sqliteHeader = <int>[
  ...'SQLite format 3'.codeUnits,
  0,
  ...List.filled(84, 0),
];

/// Records calls; can be told to throw on save to test best-effort behaviour.
class FakeSharedStorage implements SharedStorage, SharedStorageBatchDeletion {
  final List<String> saved = [];
  final List<String> deleted = [];
  List<SharedBackup> existing;
  bool throwOnSave;
  bool throwOnList;
  bool throwOnDelete;
  bool publishListed;
  bool corruptPublishedCopy;
  SharedDeleteResult ownedDeleteResult;
  SharedDeleteBatchResult batchResult;
  final List<List<String>> batchDeleted = [];
  final Map<String, String> _publishedSources = {};
  FakeSharedStorage({
    List<SharedBackup> existing = const [],
    this.throwOnSave = false,
    this.throwOnList = false,
    this.throwOnDelete = false,
    this.publishListed = true,
    this.corruptPublishedCopy = false,
    this.ownedDeleteResult = SharedDeleteResult.deleted,
    this.batchResult = const SharedDeleteBatchResult(),
  }) : existing = List.of(existing);

  @override
  Future<String> saveToDownloads(File source, String fileName) async {
    if (throwOnSave) throw const FileSystemException('no downloads');
    saved.add(fileName);
    final id = 'content://$fileName';
    _publishedSources[id] = source.path;
    if (publishListed) {
      existing.add(
        SharedBackup(
          id: id,
          name: fileName,
          addedAt: DateTime(2026, 7, 10, 12),
          sizeBytes: await source.length(),
          relativePath: 'Download/MacroChef/',
          ownedByApp: true,
        ),
      );
    }
    return id;
  }

  @override
  Future<List<SharedBackup>> listDownloads(String prefix) async {
    if (throwOnList) throw const FileSystemException('cannot prune');
    return existing;
  }

  @override
  Future<File> copyToPrivate(SharedBackup backup, File destination) async {
    if (corruptPublishedCopy) {
      await destination.writeAsString('not sqlite');
      return destination;
    }
    final source = _publishedSources[backup.id];
    if (source == null) return File(backup.id).copy(destination.path);
    return File(source).copy(destination.path);
  }

  @override
  Future<SharedDeleteResult> deleteDownload(String id) async {
    deleted.add(id);
    if (throwOnDelete) throw const FileSystemException('cannot delete');
    return ownedDeleteResult;
  }

  @override
  Future<SharedDeleteBatchResult> deleteDownloadsBatch(List<String> ids) async {
    batchDeleted.add(ids);
    return batchResult;
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

    test('automatic naming keeps current and legacy namespaces distinct', () {
      expect(
        isAutomaticBackupFileName('macrochef-auto-20260710-1200.sqlite'),
        isTrue,
      );
      expect(
        isAutomaticBackupFileName('macrochef-manual-20260710-1200.sqlite'),
        isFalse,
      );
      expect(
        isAutomaticBackupFileName('macrochef-backup-20260710-1200.sqlite'),
        isFalse,
      );
      expect(
        isLegacyAutomaticBackupFileName(
          'macrochef-backup-20260710-1200.sqlite',
        ),
        isTrue,
      );
      expect(
        isLegacyAutomaticBackupFileName('macrochef-backup-not-a-backup.sqlite'),
        isFalse,
      );
      expect(
        isRetainedAutomaticBackupFileName(
          'macrochef-manual-20260710-1200.sqlite',
        ),
        isFalse,
      );
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
      Future<File> Function(File)? exportSnapshot,
    }) => AutoBackupService(
      exportSnapshot:
          exportSnapshot ??
          (dest) async {
            await dest.writeAsBytes(_sqliteHeader);
            return dest;
          },
      shared: shared,
      getSetting: (k) async => settings[k],
      setSetting: (k, v) async => settings[k] = v,
      localBackupDir: () async => tmp,
      fileName: fileName ?? (dt) => 'macrochef-auto-20260710-1200.sqlite',
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
          'content://macrochef-auto-20260710-1200.sqlite',
        );
        expect(
          File(
            p.join(tmp.path, 'macrochef-auto-20260710-1200.sqlite'),
          ).existsSync(),
          isTrue,
        );
        expect(shared.saved, ['macrochef-auto-20260710-1200.sqlite']);
        expect(settings[kLastAutoBackupMsKey], isNotNull);
      },
    );

    test(
      'throttled run skips publication when last backup is recent',
      () async {
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
      },
    );

    test(
      'throttled launch still prunes local and Downloads automatic backups',
      () async {
        final now = DateTime(2026, 7, 10, 12);
        settings[kLastAutoBackupMsKey] = now
            .subtract(const Duration(hours: 1))
            .millisecondsSinceEpoch
            .toString();
        // The legacy name must be retained only when it is among the five
        // newest automatic snapshots; manual exports are never selected.
        for (final name in [
          'macrochef-backup-20260701-1200.sqlite',
          'macrochef-auto-20260702-1200.sqlite',
          'macrochef-auto-20260703-1200.sqlite',
          'macrochef-auto-20260704-1200.sqlite',
          'macrochef-auto-20260705-1200.sqlite',
          'macrochef-auto-20260706-1200.sqlite',
          'macrochef-manual-20260701-1200.sqlite',
        ]) {
          File(p.join(tmp.path, name)).writeAsStringSync('old');
        }
        final shared = FakeSharedStorage(
          existing: [
            SharedBackup(
              id: 'legacy-old',
              name: 'macrochef-backup-20260701-1200.sqlite',
              addedAt: DateTime(2026, 7, 1),
              ownedByApp: true,
            ),
            for (var day = 2; day <= 6; day++)
              SharedBackup(
                id: 'auto-$day',
                name: 'macrochef-auto-2026070$day-1200.sqlite',
                addedAt: DateTime(2026, 7, day),
                ownedByApp: true,
              ),
            SharedBackup(
              id: 'manual',
              name: 'macrochef-manual-20260701-1200.sqlite',
              addedAt: DateTime(2026, 7, 1),
              ownedByApp: true,
            ),
          ],
        );

        final result = await build(shared).runOnLaunch(now);

        expect(result.status, AutoBackupRunStatus.skipped);
        expect(shared.saved, isEmpty);
        expect(shared.deleted, ['legacy-old']);
        expect(
          File(
            p.join(tmp.path, 'macrochef-backup-20260701-1200.sqlite'),
          ).existsSync(),
          isFalse,
        );
        expect(
          File(
            p.join(tmp.path, 'macrochef-manual-20260701-1200.sqlite'),
          ).existsSync(),
          isTrue,
        );
      },
    );

    test('force bypasses the throttle and returns the saved URI', () async {
      final now = DateTime(2026, 7, 11, 12);
      settings[kLastAutoBackupMsKey] = now.millisecondsSinceEpoch.toString();
      final shared = FakeSharedStorage();
      final result = await build(
        shared,
        fileName: (_) => 'macrochef-auto-20260711-1200.sqlite',
      ).runOnLaunch(now, force: true);

      expect(result.status, AutoBackupRunStatus.saved);
      expect(
        result.downloadsBackupId,
        'content://macrochef-auto-20260711-1200.sqlite',
      );
      expect(shared.saved.single, startsWith(kAutomaticBackupPrefix));
      expect(shared.saved.single, endsWith('.sqlite'));
    });

    test(
      'publication verification failure preserves the local snapshot',
      () async {
        final shared = FakeSharedStorage(throwOnList: true);
        final result = await build(
          shared,
        ).runOnLaunch(DateTime(2026, 7, 10, 12));

        expect(result.status, AutoBackupRunStatus.localOnly);
        expect(
          result.downloadsBackupId,
          'content://macrochef-auto-20260710-1200.sqlite',
        );
        expect(result.warning, isNotNull);
      },
    );

    test('rotates local snapshots down to kBackupKeepLast', () async {
      // Pre-seed 5 older snapshots (older names sort lower).
      for (var i = 0; i < kBackupKeepLast; i++) {
        File(
          p.join(tmp.path, 'macrochef-auto-20200101-000$i.sqlite'),
        ).writeAsStringSync('old');
      }
      final shared = FakeSharedStorage();
      // New snapshot name sorts newest.
      await build(
        shared,
        fileName: (_) => 'macrochef-auto-20260710-1200.sqlite',
      ).runOnLaunch(DateTime(2026, 7, 10, 12));

      final remaining =
          tmp
              .listSync()
              .whereType<File>()
              .map((f) => p.basename(f.path))
              .toList()
            ..sort();
      expect(remaining.length, kBackupKeepLast);
      expect(remaining.contains('macrochef-auto-20260710-1200.sqlite'), isTrue);
      // Oldest was pruned.
      expect(
        remaining.contains('macrochef-auto-20200101-0000.sqlite'),
        isFalse,
      );
    });

    test('prunes Downloads beyond keepLast', () async {
      final existing = [
        for (var i = 8; i >= 1; i--)
          SharedBackup(
            id: 'id$i',
            name: 'macrochef-auto-2026070$i-1200.sqlite',
            addedAt: DateTime(2026),
            ownedByApp: true,
          ),
      ]; // 8 existing, newest-first
      final shared = FakeSharedStorage(existing: existing);
      await build(shared).runOnLaunch(DateTime(2026, 7, 10, 12));

      // The new snapshot consumes one retention slot before it appears in this
      // simulated MediaStore listing.
      expect(shared.deleted, ['id4', 'id3', 'id2', 'id1']);
    });

    test(
      'ignores manual files and orders timestamp ties by filename',
      () async {
        final shared = FakeSharedStorage(
          existing: [
            for (final name in [
              'macrochef-auto-20260710-1200.sqlite',
              'macrochef-auto-20260710-1100.sqlite',
              'macrochef-auto-20260710-1000.sqlite',
              'macrochef-auto-20260710-0900.sqlite',
              'macrochef-auto-20260710-0800.sqlite',
              'macrochef-auto-20260710-0700.sqlite',
            ])
              SharedBackup(
                id: name,
                name: name,
                addedAt: DateTime(2026, 7, 10),
                ownedByApp: true,
              ),
            SharedBackup(
              id: 'manual',
              name: 'macrochef-manual-20260710-1200.sqlite',
              addedAt: DateTime(2026, 7, 10),
              ownedByApp: true,
            ),
          ],
        );

        await build(shared).runOnLaunch(DateTime(2026, 7, 10, 12));

        expect(shared.deleted, [
          'macrochef-auto-20260710-0800.sqlite',
          'macrochef-auto-20260710-0700.sqlite',
        ]);
        expect(shared.batchDeleted, isEmpty);
      },
    );

    test(
      'rotates legacy automatic snapshots while never selecting manual exports',
      () async {
        final shared = FakeSharedStorage(
          existing: [
            for (var i = 1; i <= 5; i++)
              SharedBackup(
                id: 'legacy$i',
                name: 'macrochef-backup-20260701-120$i.sqlite',
                addedAt: DateTime(2026, 7, 1, 12, i),
                ownedByApp: true,
              ),
            SharedBackup(
              id: 'manual',
              name: 'macrochef-manual-20260701-1200.sqlite',
              addedAt: DateTime(2026, 7, 1, 12),
              ownedByApp: true,
            ),
          ],
        );

        await build(shared).runOnLaunch(DateTime(2026, 7, 10, 12));

        // The fresh snapshot reserves one slot, so only the four newest
        // legacy automatic snapshots remain. The manual export is untouched.
        expect(shared.deleted, ['legacy1']);
        expect(shared.deleted, isNot(contains('manual')));
      },
    );

    test(
      'declined legacy cleanup defers another prompt for seven days',
      () async {
        final shared = FakeSharedStorage(
          existing: [
            for (var i = 1; i <= 5; i++)
              SharedBackup(
                id: 'legacy$i',
                name: 'macrochef-auto-20260701-120$i.sqlite',
                addedAt: DateTime(2026, 7, 1, i),
              ),
          ],
          batchResult: const SharedDeleteBatchResult(declined: true),
        );
        final first = await build(
          shared,
        ).runOnLaunch(DateTime(2026, 7, 10, 12));
        expect(first.warning, isNotNull);
        expect(shared.batchDeleted, hasLength(1));
        expect(settings[kAutoBackupCleanupRetryAfterMsKey], isNotNull);

        await build(
          shared,
          fileName: (_) => 'macrochef-auto-20260710-1300.sqlite',
        ).runOnLaunch(DateTime(2026, 7, 10, 13), force: true);
        expect(shared.batchDeleted, hasLength(1));
      },
    );

    test('declined owned cleanup is deferred and remains a warning', () async {
      final shared = FakeSharedStorage(
        existing: [
          for (var i = 1; i <= 5; i++)
            SharedBackup(
              id: 'owned$i',
              name: 'macrochef-auto-20260701-120$i.sqlite',
              addedAt: DateTime(2026, 7, 1, i),
              ownedByApp: true,
            ),
        ],
        ownedDeleteResult: SharedDeleteResult.declined,
      );
      final now = DateTime(2026, 7, 10, 12);
      final result = await build(shared).runOnLaunch(now);

      expect(result.status, AutoBackupRunStatus.saved);
      expect(result.warning, isNotNull);
      expect(
        settings[kAutoBackupCleanupRetryAfterMsKey],
        now.add(kAutoBackupCleanupRetryDelay).millisecondsSinceEpoch.toString(),
      );
    });

    test(
      'ordinary cleanup failures are recorded as immediately retryable',
      () async {
        final shared = FakeSharedStorage(
          existing: [
            for (var i = 1; i <= 5; i++)
              SharedBackup(
                id: 'owned$i',
                name: 'macrochef-auto-20260701-120$i.sqlite',
                addedAt: DateTime(2026, 7, 1, i),
                ownedByApp: true,
              ),
          ],
          throwOnDelete: true,
        );
        final now = DateTime(2026, 7, 10, 12);
        final result = await build(shared).runOnLaunch(now);

        expect(result.warning, isNotNull);
        expect(
          settings[kAutoBackupCleanupRetryAfterMsKey],
          now.millisecondsSinceEpoch.toString(),
        );
      },
    );

    test(
      'batch cleanup failures are recorded as immediately retryable',
      () async {
        final shared = FakeSharedStorage(
          existing: [
            for (var i = 1; i <= 5; i++)
              SharedBackup(
                id: 'legacy$i',
                name: 'macrochef-auto-20260701-120$i.sqlite',
                addedAt: DateTime(2026, 7, 1, i),
              ),
          ],
          batchResult: const SharedDeleteBatchResult(
            failures: {'legacy1': 'access failed'},
          ),
        );
        final now = DateTime(2026, 7, 10, 12);
        final result = await build(shared).runOnLaunch(now);

        expect(result.warning, isNotNull);
        expect(
          settings[kAutoBackupCleanupRetryAfterMsKey],
          now.millisecondsSinceEpoch.toString(),
        );
      },
    );

    test('invalid export never publishes or prunes snapshots', () async {
      File(
        p.join(tmp.path, 'macrochef-auto-20200101-0000.sqlite'),
      ).writeAsBytesSync(_sqliteHeader);
      final shared = FakeSharedStorage();
      final result = await build(
        shared,
        exportSnapshot: (destination) async {
          await destination.writeAsString('not sqlite');
          return destination;
        },
      ).runOnLaunch(DateTime(2026, 7, 10, 12));

      expect(result.status, AutoBackupRunStatus.failed);
      expect(shared.saved, isEmpty);
      expect(
        File(
          p.join(tmp.path, 'macrochef-auto-20200101-0000.sqlite'),
        ).existsSync(),
        isTrue,
      );
    });

    test('missing published snapshot keeps every older local backup', () async {
      for (var i = 0; i < 5; i++) {
        await File(
          p.join(tmp.path, 'macrochef-auto-2026070${i + 1}-1200.sqlite'),
        ).writeAsBytes(_sqliteHeader);
      }
      final result = await build(
        FakeSharedStorage(publishListed: false),
      ).runOnLaunch(DateTime(2026, 7, 10, 12));

      expect(result.status, AutoBackupRunStatus.localOnly);
      expect(result.warning, isNotNull);
      expect(
        tmp.listSync().whereType<File>().where(
          (file) => isAutomaticBackupFileName(p.basename(file.path)),
        ),
        hasLength(6),
      );
    });

    test('invalid published copy prevents retention cleanup', () async {
      final old = File(p.join(tmp.path, 'macrochef-auto-20260701-1200.sqlite'));
      await old.writeAsBytes(_sqliteHeader);
      final result = await build(
        FakeSharedStorage(corruptPublishedCopy: true),
      ).runOnLaunch(DateTime(2026, 7, 10, 12));

      expect(result.status, AutoBackupRunStatus.localOnly);
      expect(await old.exists(), isTrue);
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
          File(
            p.join(tmp.path, 'macrochef-auto-20260710-1200.sqlite'),
          ).existsSync(),
          isTrue,
        );
        expect(settings[kLastAutoBackupMsKey], isNotNull);
      },
    );
  });
}
