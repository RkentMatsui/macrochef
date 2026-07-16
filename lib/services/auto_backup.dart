import 'dart:developer' as developer;
import 'dart:io';

import 'package:path/path.dart' as p;

import 'backup_service.dart';
import 'shared_storage.dart';

/// Settings keys for backup bookkeeping (stored via SettingsRepository).
const String kLastAutoBackupMsKey = 'last_auto_backup_ms';
const String kLastDriveBackupMsKey = 'last_drive_backup_ms';
const String kAutoBackupCleanupRetryAfterMsKey =
    'auto_backup_cleanup_retry_after_ms';

/// At most one silent launch backup per this interval.
const Duration kAutoBackupInterval = Duration(hours: 12);

/// How many rotating snapshots to keep (both local and in Downloads).
const int kBackupKeepLast = 5;

/// Nudge the user for an offsite (Drive) backup once the last one is older.
const Duration kDriveBackupStaleAfter = Duration(days: 7);
const Duration kAutoBackupCleanupRetryDelay = Duration(days: 7);

/// New rotating snapshots are deliberately separate from user-created exports.
const String kAutomaticBackupPrefix = 'macrochef-auto-';
const String kManualBackupPrefix = 'macrochef-manual-';

/// Backups made before separate manual/automatic names were introduced.
///
/// The old auto-backup implementation used this filename, so these snapshots
/// are part of the automatic retention set.  Keep the pattern exact: a broad
/// prefix match could otherwise remove a user file that merely starts with the
/// old application prefix.
const String kLegacyBackupPrefix = 'macrochef-backup-';

/// Legacy compatibility for restore code that has not yet migrated to the
/// explicit automatic/legacy discovery helpers.
const String kBackupPrefix = kLegacyBackupPrefix;

final RegExp _automaticBackupName = RegExp(
  r'^macrochef-auto-\d{8}-\d{4}\.sqlite$',
);
final RegExp _legacyAutomaticBackupName = RegExp(
  r'^macrochef-backup-\d{8}-\d{4}\.sqlite$',
);
final RegExp _retainedAutomaticBackupTimestamp = RegExp(
  r'^macrochef-(?:auto|backup)-(\d{8}-\d{4})\.sqlite$',
);

bool isAutomaticBackupFileName(String name) =>
    _automaticBackupName.hasMatch(name);

/// Whether [name] is an automatic snapshot created by versions before the
/// explicit `auto`/`manual` filename split.
bool isLegacyAutomaticBackupFileName(String name) =>
    _legacyAutomaticBackupName.hasMatch(name);

bool isRetainedAutomaticBackupFileName(String name) =>
    isAutomaticBackupFileName(name) || isLegacyAutomaticBackupFileName(name);

String _automaticBackupTimestamp(String name) =>
    _retainedAutomaticBackupTimestamp.firstMatch(name)?.group(1) ?? '';

enum AutoBackupRunStatus { skipped, saved, localOnly, failed }

class AutoBackupRunResult {
  final AutoBackupRunStatus status;
  final String? downloadsBackupId;
  final Object? warning;

  const AutoBackupRunResult(
    this.status, {
    this.downloadsBackupId,
    this.warning,
  });
}

/// True when enough time has passed since [last] to run another auto-backup.
bool shouldRunAutoBackup({
  required DateTime? last,
  required DateTime now,
  Duration minInterval = kAutoBackupInterval,
}) {
  if (last == null) return true;
  return now.difference(last) >= minInterval;
}

/// True when the last offsite (Drive) backup is missing or older than [staleAfter].
bool isDriveBackupStale({
  required DateTime? lastDrive,
  required DateTime now,
  Duration staleAfter = kDriveBackupStaleAfter,
}) {
  if (lastDrive == null) return true;
  return now.difference(lastDrive) >= staleAfter;
}

/// Given items sorted NEWEST-first, return those to delete so only [keepLast]
/// remain. Pure so both the local-file and Downloads rotations can reuse it.
List<T> pruneTargets<T>(List<T> newestFirst, {int keepLast = kBackupKeepLast}) {
  if (newestFirst.length <= keepLast) return <T>[];
  return newestFirst.sublist(keepLast);
}

/// Orchestrates the launch-time safety-net backup: a throttled silent snapshot
/// mirrored to (1) an on-device rotating folder for a fast restore point and
/// (2) public Downloads so it survives an uninstall. All I/O is injected so the
/// whole flow is unit-testable without plugins or a device.
class AutoBackupService {
  /// Writes a self-contained snapshot to [dest] and returns it (wraps
  /// BackupService.exportTo in production).
  final Future<File> Function(File dest) exportSnapshot;
  final SharedStorage shared;
  final Future<String?> Function(String key) getSetting;
  final Future<void> Function(String key, String value) setSetting;
  final Future<Directory> Function() localBackupDir;
  final String Function(DateTime) fileName;

  AutoBackupService({
    required this.exportSnapshot,
    required this.shared,
    required this.getSetting,
    required this.setSetting,
    required this.localBackupDir,
    this.fileName = BackupService.automaticFileName,
  });

  /// Run once per launch. Snapshot publication is throttled, but retention is
  /// deliberately checked on every launch. This lets an upgrade clean up old
  /// automatic snapshots even when the most recent backup is still fresh.
  /// Never throws: backup maintenance must not block or crash app startup.
  Future<AutoBackupRunResult> runOnLaunch(
    DateTime now, {
    bool force = false,
  }) async {
    try {
      final shouldPublish =
          force ||
          shouldRunAutoBackup(
            last: await _readTs(kLastAutoBackupMsKey),
            now: now,
          );
      if (!shouldPublish) {
        return _pruneOnSkippedLaunch(now);
      }

      final dir = await localBackupDir();
      await dir.create(recursive: true);
      final name = fileName(now);
      final snapshot = File(p.join(dir.path, name));
      final exported = await exportSnapshot(snapshot);
      if (!await BackupIO.isSqliteFile(exported)) {
        throw StateError('Exported backup is not a valid SQLite snapshot.');
      }

      // Best-effort offsite mirror — a Downloads failure must not lose the local
      // snapshot we already wrote, nor block recording the run.
      await setSetting(
        kLastAutoBackupMsKey,
        now.millisecondsSinceEpoch.toString(),
      );
      String downloadsBackupId;
      try {
        downloadsBackupId = await shared.saveToDownloads(exported, name);
      } catch (error) {
        developer.log(
          'publication=failed retention=skipped',
          name: 'macrochef.backup',
        );
        return AutoBackupRunResult(
          AutoBackupRunStatus.localOnly,
          warning: error,
        );
      }

      try {
        await _validatePublishedDownload(
          directory: dir,
          backupId: downloadsBackupId,
          fileName: name,
        );
      } catch (error) {
        // Keep every older snapshot when publication cannot be proven valid.
        developer.log(
          'publication=unverified retention=skipped',
          name: 'macrochef.backup',
        );
        return AutoBackupRunResult(
          AutoBackupRunStatus.localOnly,
          downloadsBackupId: downloadsBackupId,
          warning: error,
        );
      }

      // Retention starts only after both copies of the new snapshot have been
      // validated.
      await _pruneLocal(dir);
      developer.log(
        'publication=validated retention=started',
        name: 'macrochef.backup',
      );

      Object? warning;
      try {
        await _pruneDownloads(now: now, publishedBackupId: downloadsBackupId);
      } catch (error) {
        warning = error;
      }
      return AutoBackupRunResult(
        AutoBackupRunStatus.saved,
        downloadsBackupId: downloadsBackupId,
        warning: warning,
      );
    } catch (error) {
      // Swallow: startup resilience beats a guaranteed backup this launch.
      return AutoBackupRunResult(AutoBackupRunStatus.failed, warning: error);
    }
  }

  Future<void> _validatePublishedDownload({
    required Directory directory,
    required String backupId,
    required String fileName,
  }) async {
    if (backupId.trim().isEmpty) {
      throw StateError('Shared storage returned no backup identifier.');
    }
    SharedBackup? published;
    final prefix = isLegacyAutomaticBackupFileName(fileName)
        ? kLegacyBackupPrefix
        : kAutomaticBackupPrefix;
    for (final backup in await shared.listDownloads(prefix)) {
      if (backup.id == backupId && backup.name == fileName) {
        published = backup;
        break;
      }
    }
    if (published == null) {
      throw StateError('Published backup could not be found in Downloads.');
    }

    final verification = File(
      p.join(directory.path, '.verify-${p.basename(fileName)}'),
    );
    try {
      final copied = await shared.copyToPrivate(published, verification);
      if (!await BackupIO.isSqliteFile(copied)) {
        throw StateError('Published Downloads backup is not valid SQLite.');
      }
    } finally {
      if (await verification.exists()) await verification.delete();
    }
  }

  /// Performs retention-only maintenance for a throttled launch. In
  /// particular, there is no reserved slot here because no new Downloads
  /// snapshot was published during this run.
  Future<AutoBackupRunResult> _pruneOnSkippedLaunch(DateTime now) async {
    final warnings = <Object>[];
    try {
      final dir = await localBackupDir();
      if (await dir.exists()) await _pruneLocal(dir);
    } catch (error) {
      warnings.add(error);
    }
    try {
      await _pruneDownloads(now: now);
    } catch (error) {
      warnings.add(error);
    }
    return AutoBackupRunResult(
      AutoBackupRunStatus.skipped,
      warning: warnings.isEmpty ? null : StateError(warnings.join('\n')),
    );
  }

  Future<void> _pruneLocal(Directory dir) async {
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => isRetainedAutomaticBackupFileName(p.basename(f.path)))
            .toList()
          ..sort((a, b) {
            final aName = p.basename(a.path);
            final bName = p.basename(b.path);
            final byTimestamp = _automaticBackupTimestamp(
              bName,
            ).compareTo(_automaticBackupTimestamp(aName));
            return byTimestamp != 0 ? byTimestamp : bName.compareTo(aName);
          });
    for (final f in pruneTargets(files)) {
      await f.delete();
    }
  }

  Future<void> _pruneDownloads({
    required DateTime now,
    String? publishedBackupId,
  }) async {
    // The first automatic-backup release named snapshots
    // `macrochef-backup-YYYYMMDD-HHMM.sqlite`.  Query both exact namespaces so
    // upgrading does not leave that rotating set behind indefinitely. Manual
    // exports use their own prefix and are deliberately never queried here.
    final listed = await Future.wait([
      shared.listDownloads(kAutomaticBackupPrefix),
      shared.listDownloads(kLegacyBackupPrefix),
    ]);
    final seenIds = <String>{};
    final items = [
      for (final backup in listed.expand((items) => items))
        if (seenIds.add(backup.id)) backup,
    ];
    final automatic =
        items.where((b) => isRetainedAutomaticBackupFileName(b.name)).toList()
          ..sort((a, b) {
            final byAdded = b.addedAt.compareTo(a.addedAt);
            return byAdded != 0 ? byAdded : b.name.compareTo(a.name);
          });

    // A just-published snapshot is always retained, even if a MediaStore clock
    // tie sorts it at the tail. If a provider has not indexed it yet, reserve
    // one of the five retention slots for it nevertheless.
    final containsPublished =
        publishedBackupId != null &&
        automatic.any((backup) => backup.id == publishedBackupId);
    final preferred = [
      if (publishedBackupId != null)
        ...automatic.where((backup) => backup.id == publishedBackupId),
      ...automatic.where((backup) => backup.id != publishedBackupId),
    ];
    final retained = preferred
        .take(
          publishedBackupId == null || containsPublished
              ? kBackupKeepLast
              : kBackupKeepLast - 1,
        )
        .map((backup) => backup.id)
        .toSet();
    final stale = automatic.where((backup) => !retained.contains(backup.id));
    final owned = <SharedBackup>[];
    final legacy = <SharedBackup>[];
    for (final backup in stale) {
      (backup.ownedByApp ? owned : legacy).add(backup);
    }

    final warnings = <String>[];
    final existingRetryAfter = await _readTs(kAutoBackupCleanupRetryAfterMsKey);
    var retryImmediately = false;
    var deferRetry = false;
    for (final backup in owned) {
      try {
        // `notFound` means the desired state was already reached.
        final result = await shared.deleteDownload(backup.id);
        if (result == SharedDeleteResult.declined) {
          deferRetry = true;
          warnings.add('Cleanup of ${backup.name} was declined.');
        }
      } catch (error) {
        retryImmediately = true;
        warnings.add('Could not remove ${backup.name}: $error');
      }
    }

    if (legacy.isEmpty) {
      await _storeCleanupRetry(
        now: now,
        retryImmediately: retryImmediately,
        deferRetry: deferRetry,
        existingRetryAfter: existingRetryAfter,
      );
      if (warnings.isNotEmpty) throw StateError(warnings.join('\n'));
      return;
    }

    if (existingRetryAfter != null && now.isBefore(existingRetryAfter)) {
      warnings.add(
        'Legacy backup cleanup is deferred until $existingRetryAfter.',
      );
      deferRetry = true;
    } else if (shared is SharedStorageBatchDeletion) {
      try {
        final result = await (shared as SharedStorageBatchDeletion)
            .deleteDownloadsBatch(legacy.map((backup) => backup.id).toList());
        if (result.declined) {
          deferRetry = true;
          warnings.add('Legacy backup cleanup was declined.');
        }
        if (result.failures.isNotEmpty) {
          retryImmediately = true;
        }
        for (final failure in result.failures.entries) {
          warnings.add('Could not remove ${failure.key}: ${failure.value}');
        }
      } catch (error) {
        retryImmediately = true;
        warnings.add('Could not clean up legacy backups: $error');
      }
    } else {
      retryImmediately = true;
      warnings.add('Legacy backup cleanup is unavailable on this platform.');
    }
    await _storeCleanupRetry(
      now: now,
      retryImmediately: retryImmediately,
      deferRetry: deferRetry,
      existingRetryAfter: existingRetryAfter,
    );
    if (warnings.isNotEmpty) throw StateError(warnings.join('\n'));
  }

  Future<void> _storeCleanupRetry({
    required DateTime now,
    required bool retryImmediately,
    required bool deferRetry,
    required DateTime? existingRetryAfter,
  }) {
    if (deferRetry) {
      final next = existingRetryAfter != null && existingRetryAfter.isAfter(now)
          ? existingRetryAfter
          : now.add(kAutoBackupCleanupRetryDelay);
      return setSetting(
        kAutoBackupCleanupRetryAfterMsKey,
        next.millisecondsSinceEpoch.toString(),
      );
    }
    // An ordinary error is deliberately due again on the next launch; the
    // persisted timestamp still records that cleanup remains outstanding.
    if (retryImmediately) {
      return setSetting(
        kAutoBackupCleanupRetryAfterMsKey,
        now.millisecondsSinceEpoch.toString(),
      );
    }
    return setSetting(kAutoBackupCleanupRetryAfterMsKey, '');
  }

  Future<DateTime?> _readTs(String key) async {
    final ms = int.tryParse(await getSetting(key) ?? '');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }
}
