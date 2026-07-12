import 'dart:io';

import 'package:flutter/services.dart';

enum SharedDeleteResult { deleted, declined, notFound }

class SharedStorageAccessException implements Exception {
  final String code;
  final String message;
  const SharedStorageAccessException(this.code, this.message);
}

/// A backup file previously written to shared storage (Downloads).
class SharedBackup {
  final String id; // opaque handle (a MediaStore content URI on Android)
  final String name;
  final DateTime addedAt;
  final int? sizeBytes;
  final String? relativePath;
  final bool ownedByApp;
  const SharedBackup({
    required this.id,
    required this.name,
    required this.addedAt,
    this.sizeBytes,
    this.relativePath,
    this.ownedByApp = false,
  });
}

/// Writes/reads backup snapshots to storage that OUTLIVES an app uninstall.
///
/// App-private and app-scoped-external directories are both wiped when the app
/// is uninstalled (which a debug-over-release `flutter run` triggers), so those
/// cannot protect data. Only the public Downloads collection survives — this
/// seam abstracts it so the orchestrator stays platform-agnostic and testable.
abstract class SharedStorage {
  /// Copy [source] into public Downloads as [fileName]; return an opaque id.
  Future<String> saveToDownloads(File source, String fileName);

  /// List previously saved backups whose name starts with [prefix], newest-first.
  Future<List<SharedBackup>> listDownloads(String prefix);

  /// Copy [backup] into the app-private [destination].
  Future<File> copyToPrivate(SharedBackup backup, File destination);

  /// Delete a previously saved backup by its [id].
  Future<SharedDeleteResult> deleteDownload(String id);
}

/// Fallback for platforms without shared storage (desktop/tests). Every call is
/// a no-op so callers never need a platform check.
class NoopSharedStorage implements SharedStorage {
  const NoopSharedStorage();

  @override
  Future<String> saveToDownloads(File source, String fileName) async => '';

  @override
  Future<List<SharedBackup>> listDownloads(String prefix) async => const [];

  @override
  Future<File> copyToPrivate(SharedBackup backup, File destination) =>
      throw const SharedStorageAccessException(
        'unavailable',
        'Shared storage is unavailable on this platform',
      );

  @override
  Future<SharedDeleteResult> deleteDownload(String id) async =>
      SharedDeleteResult.notFound;
}

/// Android implementation backed by MediaStore Downloads via a MethodChannel.
///
/// MediaStore inserts into Downloads need NO runtime permission on API 29+
/// (our minSdk is 24; on 24–28 the platform side falls back to a direct write
/// under the public Downloads dir — see the Kotlin handler).
class MediaStoreSharedStorage implements SharedStorage {
  static const MethodChannel _channel = MethodChannel(
    'com.macrochef.app/downloads_backup',
  );
  const MediaStoreSharedStorage();

  @override
  Future<String> saveToDownloads(File source, String fileName) async {
    final uri = await _channel.invokeMethod<String>('save', {
      'path': source.path,
      'name': fileName,
    });
    return uri ?? '';
  }

  @override
  Future<List<SharedBackup>> listDownloads(String prefix) async {
    final raw =
        await _channel.invokeListMethod<Map<dynamic, dynamic>>('list', {
          'prefix': prefix,
        }) ??
        const [];
    return raw
        .where(
          (m) =>
              (m['name'] as String).startsWith(prefix) &&
              (m['relativePath'] == null ||
                  m['relativePath'] == 'Download/MacroChef/'),
        )
        .map(
          (m) => SharedBackup(
            id: m['id'] as String,
            name: m['name'] as String,
            addedAt: DateTime.fromMillisecondsSinceEpoch(m['addedAtMs'] as int),
            sizeBytes: m['sizeBytes'] as int?,
            relativePath: m['relativePath'] as String?,
            ownedByApp: m['ownedByApp'] as bool? ?? false,
          ),
        )
        .toList();
  }

  @override
  Future<File> copyToPrivate(SharedBackup backup, File destination) async {
    try {
      await _channel.invokeMethod<void>('copy', {
        'id': backup.id,
        'destinationPath': destination.path,
      });
      return destination;
    } on PlatformException catch (error) {
      if (error.code == 'access_required') {
        throw SharedStorageAccessException(
          error.code,
          error.message ?? 'Android access required',
        );
      }
      rethrow;
    }
  }

  @override
  Future<SharedDeleteResult> deleteDownload(String id) async {
    final value = await _channel.invokeMethod<String>('delete', {'id': id});
    return switch (value) {
      'deleted' => SharedDeleteResult.deleted,
      'declined' => SharedDeleteResult.declined,
      'not_found' => SharedDeleteResult.notFound,
      _ => throw StateError('Unknown shared delete result: $value'),
    };
  }
}
