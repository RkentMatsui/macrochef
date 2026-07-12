import 'dart:io';

import 'package:path/path.dart' as p;

import 'backup_service.dart';
import 'shared_storage.dart';

/// Settings keys for backup bookkeeping (stored via SettingsRepository).
const String kLastAutoBackupMsKey = 'last_auto_backup_ms';
const String kLastDriveBackupMsKey = 'last_drive_backup_ms';

/// At most one silent launch backup per this interval.
const Duration kAutoBackupInterval = Duration(hours: 12);

/// How many rotating snapshots to keep (both local and in Downloads).
const int kBackupKeepLast = 5;

/// Nudge the user for an offsite (Drive) backup once the last one is older.
const Duration kDriveBackupStaleAfter = Duration(days: 7);

/// Backup file names all start with this (shared with [BackupService]).
const String kBackupPrefix = 'macrochef-backup-';

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
    this.fileName = BackupService.suggestedFileName,
  });

  /// Run once per launch. Throttled; never throws (a backup must never block or
  /// crash app startup).
  Future<AutoBackupRunResult> runOnLaunch(
    DateTime now, {
    bool force = false,
  }) async {
    try {
      if (!force &&
          !shouldRunAutoBackup(
            last: await _readTs(kLastAutoBackupMsKey),
            now: now,
          )) {
        return const AutoBackupRunResult(AutoBackupRunStatus.skipped);
      }

      final dir = await localBackupDir();
      await dir.create(recursive: true);
      final name = fileName(now);
      final snapshot = File(p.join(dir.path, name));
      await exportSnapshot(snapshot);

      await _pruneLocal(dir);

      // Best-effort offsite mirror — a Downloads failure must not lose the local
      // snapshot we already wrote, nor block recording the run.
      await setSetting(
        kLastAutoBackupMsKey,
        now.millisecondsSinceEpoch.toString(),
      );
      String downloadsBackupId;
      try {
        downloadsBackupId = await shared.saveToDownloads(snapshot, name);
      } catch (error) {
        return AutoBackupRunResult(
          AutoBackupRunStatus.localOnly,
          warning: error,
        );
      }

      Object? warning;
      try {
        await _pruneDownloads();
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

  Future<void> _pruneLocal(Directory dir) async {
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => p.basename(f.path).startsWith(kBackupPrefix))
            .toList()
          // Names are `...-YYYYMMDD-HHMM.sqlite`, so lexicographic desc == newest-first.
          ..sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
    for (final f in pruneTargets(files)) {
      await f.delete();
    }
  }

  Future<void> _pruneDownloads() async {
    final items = await shared.listDownloads(kBackupPrefix); // newest-first
    for (final b in pruneTargets(items)) {
      await shared.deleteDownload(b.id);
    }
  }

  Future<DateTime?> _readTs(String key) async {
    final ms = int.tryParse(await getSetting(key) ?? '');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }
}
