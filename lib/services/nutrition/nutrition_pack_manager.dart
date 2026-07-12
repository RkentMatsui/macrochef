import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const String kNutritionPackUrl =
    'https://github.com/RkentMatsui/macrochef/releases/download/'
    'nutrition-pack-v1/nutrition_pack.sqlite';
const String kMiniLmModelUrl =
    'https://github.com/RkentMatsui/macrochef/releases/download/'
    'nutrition-pack-v1/minilm-l6-v2.onnx';
const String kMiniLmVocabUrl =
    'https://github.com/RkentMatsui/macrochef/releases/download/'
    'nutrition-pack-v1/minilm-vocab.txt';

// Exact byte sizes of the published GitHub Release (nutrition-pack-v1) assets,
// built + verified on 2026-07-12 (8170 USDA Foundation+SR-Legacy foods,
// minilm-l6-v2-384 vectors). These must match the uploaded files exactly — the
// downloader rejects a transfer whose length differs. All three being non-zero
// is what marks the pack "configured" and enables the Settings download UI
// (see NutritionPackAsset.configured); the release must exist for downloads to
// succeed.
const int kNutritionPackSizeBytes = 17129472; // nutrition_pack.sqlite
const int kMiniLmModelSizeBytes = 90405214; // minilm-l6-v2.onnx
const int kMiniLmVocabSizeBytes = 231508; // minilm-vocab.txt

enum NutritionPackState { notDownloaded, partial, downloaded }

class NutritionPackAsset {
  final String fileName;
  final String url;
  final int sizeBytes;

  const NutritionPackAsset({
    required this.fileName,
    required this.url,
    required this.sizeBytes,
  });

  bool get configured =>
      sizeBytes > 0 &&
      !url.contains('REPLACE_') &&
      (Uri.tryParse(url)?.hasScheme ?? false);
}

class NutritionPackManifest {
  final NutritionPackAsset database;
  final NutritionPackAsset model;
  final NutritionPackAsset vocab;

  const NutritionPackManifest({
    required this.database,
    required this.model,
    required this.vocab,
  });

  static const placeholder = NutritionPackManifest(
    database: NutritionPackAsset(
      fileName: 'nutrition_pack.sqlite',
      url: kNutritionPackUrl,
      sizeBytes: kNutritionPackSizeBytes,
    ),
    model: NutritionPackAsset(
      fileName: 'minilm-l6-v2.onnx',
      url: kMiniLmModelUrl,
      sizeBytes: kMiniLmModelSizeBytes,
    ),
    vocab: NutritionPackAsset(
      fileName: 'minilm-vocab.txt',
      url: kMiniLmVocabUrl,
      sizeBytes: kMiniLmVocabSizeBytes,
    ),
  );

  List<NutritionPackAsset> get assets => [database, model, vocab];
  bool get configured => assets.every((asset) => asset.configured);
  int get totalSizeBytes =>
      assets.fold(0, (total, asset) => total + asset.sizeBytes);
}

class NutritionPackUnavailableException implements Exception {
  final String message;
  const NutritionPackUnavailableException(this.message);
  @override
  String toString() => 'NutritionPackUnavailableException: $message';
}

typedef NutritionAssetDownloader =
    Future<void> Function(
      NutritionPackAsset asset,
      File destination,
      void Function(int received, int total) onBytes,
    );

typedef NutritionFilePromoter =
    Future<void> Function(File source, String destination);
typedef NutritionFileDeleter = Future<void> Function(File file);
typedef NutritionFileRenamer =
    Future<void> Function(File source, String destination);

class NutritionPackPromotionException extends FileSystemException {
  final Object cause;
  final List<Object> rollbackErrors;

  NutritionPackPromotionException(this.cause, this.rollbackErrors)
    : super(
        'Nutrition pack promotion failed; rollback also reported '
        '${rollbackErrors.length} error(s): $cause',
      );
}

class NutritionPackManager {
  final Future<Directory> Function() _supportDirectory;
  final NutritionPackManifest manifest;
  final NutritionAssetDownloader _downloader;
  final NutritionFilePromoter _promoteFile;
  final NutritionFileDeleter _deleteFile;
  final NutritionFileRenamer _renameFileOperation;
  Future<void> _operation = Future<void>.value();
  Future<void>? _downloadInFlight;

  NutritionPackManager({
    Future<Directory> Function()? supportDirectory,
    this.manifest = NutritionPackManifest.placeholder,
    NutritionAssetDownloader? downloader,
    NutritionFilePromoter? promoteFile,
    NutritionFileDeleter? deleteFile,
    NutritionFileRenamer? renameFile,
  }) : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory,
       _downloader = downloader ?? _downloadWithHttpClient,
       _promoteFile = promoteFile ?? _renameFile,
       _deleteFile = deleteFile ?? _deleteFileDefault,
       _renameFileOperation = renameFile ?? _renameFile;

  bool get canDownload => manifest.configured;

  Future<Directory> _packDirectory() async =>
      Directory(p.join((await _supportDirectory()).path, 'nutrition'));

  Future<String> _pathFor(NutritionPackAsset asset) async =>
      p.join((await _packDirectory()).path, asset.fileName);

  Future<String> dbPath() => _pathFor(manifest.database);
  Future<String> modelPath() => _pathFor(manifest.model);
  Future<String> vocabPath() => _pathFor(manifest.vocab);

  Future<List<String>> allPaths() async => [
    await dbPath(),
    await modelPath(),
    await vocabPath(),
  ];

  Future<NutritionPackState> resolveState() async {
    if (!manifest.configured) return NutritionPackState.notDownloaded;
    var complete = 0;
    var anyBytes = false;
    for (final asset in manifest.assets) {
      final file = File(await _pathFor(asset));
      final part = File('${file.path}.part');
      if (await file.exists()) {
        final length = await file.length();
        anyBytes = anyBytes || length > 0;
        if (length == asset.sizeBytes) complete++;
      }
      if (await part.exists() && await part.length() > 0) anyBytes = true;
    }
    if (complete == manifest.assets.length) {
      return NutritionPackState.downloaded;
    }
    return anyBytes
        ? NutritionPackState.partial
        : NutritionPackState.notDownloaded;
  }

  Future<bool> isDownloaded() async =>
      await resolveState() == NutritionPackState.downloaded;

  Future<void> download({void Function(double)? onProgress}) {
    final active = _downloadInFlight;
    if (active != null) return active;
    final future = _operation.then(
      (_) => _downloadTransaction(onProgress: onProgress),
    );
    _operation = future.catchError((_) {});
    _downloadInFlight = future;
    future.then(
      (_) => _clearDownload(future),
      onError: (_, __) => _clearDownload(future),
    );
    return future;
  }

  void _clearDownload(Future<void> future) {
    if (identical(_downloadInFlight, future)) _downloadInFlight = null;
  }

  Future<void> _downloadTransaction({void Function(double)? onProgress}) async {
    if (!manifest.configured) {
      throw const NutritionPackUnavailableException(
        'Download assets have not been published yet.',
      );
    }
    await _recoverStaleBackups();
    final received = <NutritionPackAsset, int>{};
    for (final asset in manifest.assets) {
      final destination = File(await _pathFor(asset));
      await destination.parent.create(recursive: true);
      final part = File('${destination.path}.part');
      if (await part.exists()) await part.delete();
      await _downloader(asset, part, (bytes, _) {
        received[asset] = bytes;
        final total = received.values.fold<int>(0, (a, b) => a + b);
        onProgress?.call((total / manifest.totalSizeBytes).clamp(0, 1));
      });
      final actual = await part.length();
      if (actual != asset.sizeBytes) {
        await part.delete();
        throw FormatException(
          '${asset.fileName} is incomplete ($actual of ${asset.sizeBytes} bytes).',
        );
      }
    }
    await _promoteStagedAssets();
    onProgress?.call(1);
  }

  Future<void> _promoteStagedAssets() async {
    final destinations = <File>[];
    final backups = <File>[];
    try {
      for (final asset in manifest.assets) {
        final destination = File(await _pathFor(asset));
        final staleBackup = File('${destination.path}.backup');
        final backup = File(
          '${destination.path}.${await staleBackup.exists() ? 'rollback' : 'backup'}',
        );
        if (await backup.exists()) {
          throw FileSystemException(
            'Unrecoverable nutrition pack backup already exists',
            backup.path,
          );
        }
        if (await destination.exists()) {
          await _renameFileOperation(destination, backup.path);
        }
        destinations.add(destination);
        backups.add(backup);
      }
      for (var i = 0; i < destinations.length; i++) {
        await _promoteFile(
          File('${destinations[i].path}.part'),
          destinations[i].path,
        );
      }
    } on Object catch (error, stackTrace) {
      final rollbackErrors = <Object>[];
      for (var i = destinations.length - 1; i >= 0; i--) {
        var destinationRemoved = !await destinations[i].exists();
        if (!destinationRemoved) {
          try {
            await _deleteFile(destinations[i]);
            destinationRemoved = true;
          } on Object catch (rollbackError) {
            rollbackErrors.add(rollbackError);
          }
        }
        if (destinationRemoved && await backups[i].exists()) {
          try {
            await _renameFileOperation(backups[i], destinations[i].path);
          } on Object catch (rollbackError) {
            rollbackErrors.add(rollbackError);
          }
        }
      }
      if (rollbackErrors.isEmpty) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      throw NutritionPackPromotionException(error, rollbackErrors);
    }

    // The complete new set is now installed. Cleanup is deliberately outside
    // the rollback catch: failure here must not destroy committed assets.
    for (final destination in destinations) {
      for (final backup in [
        File('${destination.path}.backup'),
        File('${destination.path}.rollback'),
      ]) {
        if (await backup.exists()) {
          try {
            await _deleteFile(backup);
          } on Object {
            // The new set is already committed. Leave the recoverable backup
            // in place rather than reporting the successful install as failed.
          }
        }
      }
    }
  }

  Future<void> _recoverStaleBackups() async {
    for (final destinationPath in await allPaths()) {
      final destination = File(destinationPath);
      for (final backup in [
        File('$destinationPath.rollback'),
        File('$destinationPath.backup'),
      ]) {
        if (!await backup.exists()) continue;
        if (!await destination.exists()) {
          await _renameFileOperation(backup, destination.path);
        } else if (backup.path.endsWith('.rollback')) {
          throw FileSystemException(
            'Interrupted nutrition pack rollback needs manual recovery',
            backup.path,
          );
        }
      }
    }
  }

  Future<void> delete() {
    final future = _operation.then((_) => _deleteFiles());
    _operation = future.catchError((_) {});
    return future;
  }

  Future<void> _deleteFiles() async {
    for (final path in await allPaths()) {
      for (final file in [
        File(path),
        File('$path.part'),
        File('$path.backup'),
        File('$path.rollback'),
      ]) {
        if (await file.exists()) await file.delete();
      }
    }
  }

  static Future<void> _renameFile(File source, String destination) =>
      source.rename(destination);

  static Future<void> _deleteFileDefault(File file) => file.delete();

  static Future<void> _downloadWithHttpClient(
    NutritionPackAsset asset,
    File destination,
    void Function(int received, int total) onBytes,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(asset.url));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Download failed with HTTP ${response.statusCode}',
          uri: Uri.parse(asset.url),
        );
      }
      var received = 0;
      final sink = destination.openWrite();
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;
          onBytes(received, asset.sizeBytes);
        }
      } finally {
        await sink.close();
      }
    } finally {
      client.close();
    }
  }
}
