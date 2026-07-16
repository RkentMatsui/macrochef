import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/database.dart';
import 'shared_storage.dart';

/// The single SQLite file drift_flutter stores under the app documents dir for
/// `driftDatabase(name: 'macrochef')`.
const String _kDbName = 'macrochef';
String get _dbFileName => '$_kDbName.sqlite';

/// A staged restore waiting to be applied on next launch (see
/// [BackupService.applyPendingRestore]). Kept next to the live DB.
String get _pendingFileName => '$_kDbName.import.sqlite';

/// The 16-byte magic header every SQLite 3 file starts with: "SQLite format 3\0".
const List<int> _sqliteMagic = [
  0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, //
  0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00,
];

enum RestoreReplacementResult { applied, verificationFailed }

/// A manual snapshot after it has been published to public Downloads.
class ManualBackupExport {
  final String fileName;
  final String downloadsId;

  const ManualBackupExport({required this.fileName, required this.downloadsId});
}

/// Publishes a user-requested snapshot to public Downloads. This plugin-free
/// seam keeps the export contract testable outside the Settings widget.
class ManualBackupPublisher {
  final Future<File> Function(File destination) exportSnapshot;
  final SharedStorage sharedStorage;
  final Future<Directory> Function() temporaryDirectory;

  const ManualBackupPublisher({
    required this.exportSnapshot,
    required this.sharedStorage,
    required this.temporaryDirectory,
  });

  Future<ManualBackupExport> save(DateTime when) async {
    final fileName = BackupService.manualFileName(when);
    final directory = await temporaryDirectory();
    final snapshot = File(p.join(directory.path, fileName));
    final exported = await exportSnapshot(snapshot);
    if (!await BackupIO.isSqliteFile(exported)) {
      throw const FileSystemException('Backup snapshot is not a SQLite file');
    }
    final downloadsId = await sharedStorage.saveToDownloads(exported, fileName);
    return ManualBackupExport(fileName: fileName, downloadsId: downloadsId);
  }
}

/// Pure, path-based file operations for backup/restore — no plugins, no drift,
/// so they're unit-testable with temp files. The plugin-facing [BackupService]
/// resolves real directories and calls into these.
class BackupIO {
  BackupIO._();

  /// True when [f] exists and begins with the SQLite file header. Guards a
  /// restore against a user picking an unrelated file.
  static Future<bool> isSqliteFile(File f) async {
    if (!await f.exists()) return false;
    final raf = await f.open();
    try {
      final header = await raf.read(16);
      if (header.length < 16) return false;
      for (var i = 0; i < 16; i++) {
        if (header[i] != _sqliteMagic[i]) return false;
      }
      return true;
    } finally {
      await raf.close();
    }
  }

  /// Copy [source] over [dbFile], first deleting the old `-wal`/`-shm` sidecars
  /// so a stale write-ahead log can't corrupt the restored database. Callers
  /// must run this BEFORE any connection to [dbFile] is opened.
  static Future<void> replaceDatabase({
    required File source,
    required File dbFile,
  }) async {
    for (final ext in const ['-wal', '-shm']) {
      final side = File('${dbFile.path}$ext');
      if (await side.exists()) await side.delete();
    }
    await dbFile.parent.create(recursive: true);
    await source.copy(dbFile.path);
  }

  static Future<RestoreReplacementResult> replaceWithRollback({
    required File source,
    required File dbFile,
    required Future<bool> Function(File file) verify,
  }) async {
    final rollback = File(
      p.join(dbFile.parent.path, 'macrochef.rollback.sqlite'),
    );
    if (await rollback.exists()) await rollback.delete();
    final hadLiveDatabase = await dbFile.exists();
    if (hadLiveDatabase) await dbFile.copy(rollback.path);
    var rollbackCanBeDeleted = false;

    try {
      await replaceDatabase(source: source, dbFile: dbFile);
      if (await verify(dbFile)) {
        rollbackCanBeDeleted = true;
        return RestoreReplacementResult.applied;
      }

      if (hadLiveDatabase) {
        await replaceDatabase(source: rollback, dbFile: dbFile);
        rollbackCanBeDeleted = await _filesMatch(rollback, dbFile);
      } else if (await dbFile.exists()) {
        await dbFile.delete();
      }
      return RestoreReplacementResult.verificationFailed;
    } catch (_) {
      if (hadLiveDatabase && await rollback.exists()) {
        await replaceDatabase(source: rollback, dbFile: dbFile);
        rollbackCanBeDeleted = await _filesMatch(rollback, dbFile);
      }
      rethrow;
    } finally {
      if (rollbackCanBeDeleted && await rollback.exists()) {
        await rollback.delete();
      }
    }
  }

  static Future<bool> _filesMatch(File first, File second) async {
    if (!await first.exists() || !await second.exists()) return false;
    if (await first.length() != await second.length()) return false;

    final firstHandle = await first.open();
    final secondHandle = await second.open();
    try {
      while (true) {
        final left = await firstHandle.read(64 * 1024);
        final right = await secondHandle.read(64 * 1024);
        if (left.length != right.length) return false;
        for (var i = 0; i < left.length; i++) {
          if (left[i] != right[i]) return false;
        }
        if (left.isEmpty) return true;
      }
    } finally {
      await firstHandle.close();
      await secondHandle.close();
    }
  }

  /// If [staging] exists, replace [dbFile] with it and delete [staging].
  /// Returns true when a restore was applied.
  static Future<bool> applyPending({
    required File staging,
    required File dbFile,
  }) async {
    if (!await staging.exists()) return false;
    await replaceDatabase(source: staging, dbFile: dbFile);
    await staging.delete();
    return true;
  }
}

/// Export/import of the app's on-device database so a user's data can survive a
/// reinstall or move to a new phone. Export produces a self-contained `.sqlite`
/// snapshot (WAL checkpointed in); import stages the chosen file and swaps it in
/// on the next launch, before the database connection opens.
class BackupService {
  final AppDatabase db;
  BackupService(this.db);

  static Future<File> databaseFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _dbFileName));
  }

  static Future<File> _pendingRestoreFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _pendingFileName));
  }

  /// Write a self-contained snapshot of the live database to [dest]. The WAL is
  /// checkpointed (TRUNCATE) first so the copied file needs no sidecars.
  Future<File> exportTo(File dest) async {
    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    final src = await databaseFile();
    await dest.parent.create(recursive: true);
    await src.copy(dest.path);
    return dest;
  }

  /// Filename for a backup the user explicitly saves or shares.
  static String manualFileName(DateTime when) {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = '${when.year}${two(when.month)}${two(when.day)}';
    final t = '${two(when.hour)}${two(when.minute)}';
    return 'macrochef-manual-$d-$t.sqlite';
  }

  /// Filename for an app-created rotating safety-net snapshot.
  static String automaticFileName(DateTime when) {
    String two(int n) => n.toString().padLeft(2, '0');
    final d = '${when.year}${two(when.month)}${two(when.day)}';
    final t = '${two(when.hour)}${two(when.minute)}';
    return 'macrochef-auto-$d-$t.sqlite';
  }

  /// Validate [source] is a SQLite file and stage it to be applied on next
  /// launch. Returns false (and stages nothing) when it isn't a database.
  Future<bool> stageRestore(File source) async {
    if (!await BackupIO.isSqliteFile(source)) return false;
    final staging = await _pendingRestoreFile();
    await source.copy(staging.path);
    return true;
  }

  /// Apply a staged restore if present. Call ONCE at startup, before the
  /// database is opened. Returns true when a restore was applied.
  static Future<bool> applyPendingRestore() async {
    final staging = await _pendingRestoreFile();
    final dbFile = await databaseFile();
    return BackupIO.applyPending(staging: staging, dbFile: dbFile);
  }
}
