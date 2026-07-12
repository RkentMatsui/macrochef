import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/nutrition/nutrition_pack_manager.dart';

void main() {
  late Directory temp;
  late NutritionPackManifest manifest;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('nutrition-pack-test-');
    manifest = const NutritionPackManifest(
      database: NutritionPackAsset(
        fileName: 'nutrition.sqlite',
        url: 'https://example.test/nutrition.sqlite',
        sizeBytes: 4,
      ),
      model: NutritionPackAsset(
        fileName: 'minilm.onnx',
        url: 'https://example.test/minilm.onnx',
        sizeBytes: 5,
      ),
      vocab: NutritionPackAsset(
        fileName: 'vocab.txt',
        url: 'https://example.test/vocab.txt',
        sizeBytes: 3,
      ),
    );
  });

  tearDown(() async => temp.delete(recursive: true));

  NutritionPackManager manager({
    NutritionAssetDownloader? downloader,
    NutritionFilePromoter? promoteFile,
    NutritionFileDeleter? deleteFile,
    NutritionFileRenamer? renameFile,
  }) => NutritionPackManager(
    supportDirectory: () async => temp,
    manifest: manifest,
    downloader: downloader,
    promoteFile: promoteFile,
    deleteFile: deleteFile,
    renameFile: renameFile,
  );

  test(
    'resolveState distinguishes absent, partial, and complete packs',
    () async {
      final subject = manager();
      expect(await subject.resolveState(), NutritionPackState.notDownloaded);

      final db = File(await subject.dbPath());
      await db.parent.create(recursive: true);
      await db.writeAsBytes([1, 2, 3, 4]);
      expect(await subject.resolveState(), NutritionPackState.partial);

      await File(await subject.modelPath()).writeAsBytes([1, 2, 3, 4, 5]);
      await File(await subject.vocabPath()).writeAsBytes([1, 2, 3]);
      expect(await subject.resolveState(), NutritionPackState.downloaded);
    },
  );

  test('an unconfigured manifest is never downloadable or valid', () async {
    // A manifest whose assets are not fully published (zero size / placeholder
    // URL) must never offer a download, whatever else is set.
    const unconfigured = NutritionPackManifest(
      database: NutritionPackAsset(
        fileName: 'nutrition.sqlite',
        url: 'https://example.test/nutrition.sqlite',
        sizeBytes: 0,
      ),
      model: NutritionPackAsset(
        fileName: 'minilm.onnx',
        url: 'https://example.test/minilm.onnx',
        sizeBytes: 0,
      ),
      vocab: NutritionPackAsset(
        fileName: 'vocab.txt',
        url: 'https://example.test/vocab.txt',
        sizeBytes: 3,
      ),
    );
    final subject = NutritionPackManager(
      supportDirectory: () async => temp,
      manifest: unconfigured,
    );

    expect(subject.canDownload, isFalse);
    expect(await subject.resolveState(), NutritionPackState.notDownloaded);
    expect(
      subject.download(),
      throwsA(isA<NutritionPackUnavailableException>()),
    );
  });

  test('the shipped placeholder manifest is configured for download', () async {
    // Once the release is published (sizes set), the default manifest is a real,
    // downloadable configuration.
    expect(NutritionPackManifest.placeholder.configured, isTrue);
    expect(NutritionPackManager().canDownload, isTrue);
  });

  test('interrupted download leaves only a safe partial file', () async {
    final subject = manager(
      downloader: (asset, destination, onBytes) async {
        await destination.writeAsBytes([1, 2]);
        throw const SocketException('connection reset');
      },
    );

    await expectLater(subject.download(), throwsA(isA<SocketException>()));
    expect(await subject.resolveState(), NutritionPackState.partial);
    expect(await File(await subject.dbPath()).exists(), isFalse);
    expect(await File('${await subject.dbPath()}.part').exists(), isTrue);
  });

  test('download verifies every asset before promoting temp files', () async {
    final subject = manager(
      downloader: (asset, destination, onBytes) async {
        final bytes = List<int>.filled(asset.sizeBytes, 7);
        await destination.writeAsBytes(bytes);
        onBytes(bytes.length, bytes.length);
      },
    );
    final progress = <double>[];

    await subject.download(onProgress: progress.add);

    expect(await subject.resolveState(), NutritionPackState.downloaded);
    expect(progress.last, 1);
    expect(await File('${await subject.dbPath()}.part').exists(), isFalse);
  });

  for (final failingIndex in [1, 2]) {
    test(
      'failure on asset ${failingIndex + 1} preserves installed pack',
      () async {
        final subject = manager(
          downloader: (asset, destination, onBytes) async {
            if (manifest.assets.indexOf(asset) == failingIndex) {
              throw const SocketException('connection reset');
            }
            await destination.writeAsBytes(
              List<int>.filled(asset.sizeBytes, failingIndex + 10),
            );
          },
        );
        final original = <String, List<int>>{};
        for (final path in await subject.allPaths()) {
          final asset =
              manifest.assets[(await subject.allPaths()).indexOf(path)];
          original[path] = List<int>.filled(asset.sizeBytes, 3);
          await File(path).parent.create(recursive: true);
          await File(path).writeAsBytes(original[path]!);
        }

        await expectLater(subject.download(), throwsA(isA<SocketException>()));

        for (final entry in original.entries) {
          expect(await File(entry.key).readAsBytes(), entry.value);
        }
      },
    );
  }

  test('promotion failure rolls back every installed asset', () async {
    final subject = manager(
      promoteFile: (source, destination) async {
        if (destination.endsWith('minilm.onnx')) {
          throw const FileSystemException('rename failed');
        }
        await source.rename(destination);
      },
      downloader: (asset, destination, onBytes) async {
        await destination.writeAsBytes(List<int>.filled(asset.sizeBytes, 9));
      },
    );
    final originals = <String, List<int>>{};
    for (final asset in manifest.assets) {
      final path = (await subject.allPaths())[manifest.assets.indexOf(asset)];
      originals[path] = List<int>.filled(asset.sizeBytes, 2);
      await File(path).parent.create(recursive: true);
      await File(path).writeAsBytes(originals[path]!);
    }

    await expectLater(subject.download(), throwsA(isA<FileSystemException>()));

    for (final entry in originals.entries) {
      expect(await File(entry.key).readAsBytes(), entry.value);
    }
  });

  test(
    'later backup cleanup failure does not roll back committed pack',
    () async {
      var backupDeletes = 0;
      final subject = manager(
        downloader: (asset, destination, onBytes) async {
          await destination.writeAsBytes(List<int>.filled(asset.sizeBytes, 9));
        },
        deleteFile: (file) async {
          if (file.path.endsWith('.backup') && ++backupDeletes == 2) {
            throw const FileSystemException('cleanup failed');
          }
          await file.delete();
        },
      );
      for (final asset in manifest.assets) {
        final path = (await subject.allPaths())[manifest.assets.indexOf(asset)];
        await File(path).parent.create(recursive: true);
        await File(path).writeAsBytes(List<int>.filled(asset.sizeBytes, 2));
      }

      await subject.download();

      for (final path in await subject.allPaths()) {
        expect(await File(path).readAsBytes(), everyElement(9));
      }
      expect(backupDeletes, 3);
    },
  );

  test('rollback rename failure still attempts every restoration', () async {
    final restoreAttempts = <String>[];
    final subject = manager(
      downloader: (asset, destination, onBytes) async {
        await destination.writeAsBytes(List<int>.filled(asset.sizeBytes, 9));
      },
      promoteFile: (source, destination) async {
        if (destination.endsWith('vocab.txt')) {
          throw const FileSystemException('promotion failed');
        }
        await source.rename(destination);
      },
      renameFile: (source, destination) async {
        if (source.path.endsWith('.backup')) {
          restoreAttempts.add(destination);
          if (destination.endsWith('minilm.onnx')) {
            throw const FileSystemException('restore failed');
          }
        }
        await source.rename(destination);
      },
    );
    final originals = <String, List<int>>{};
    for (final asset in manifest.assets) {
      final path = (await subject.allPaths())[manifest.assets.indexOf(asset)];
      originals[path] = List<int>.filled(asset.sizeBytes, 2);
      await File(path).parent.create(recursive: true);
      await File(path).writeAsBytes(originals[path]!);
    }

    await expectLater(subject.download(), throwsA(isA<FileSystemException>()));

    expect(restoreAttempts, hasLength(3));
    expect(
      await File(await subject.dbPath()).readAsBytes(),
      originals[await subject.dbPath()],
    );
    expect(
      await File(await subject.vocabPath()).readAsBytes(),
      originals[await subject.vocabPath()],
    );
    expect(
      await File('${await subject.modelPath()}.backup').readAsBytes(),
      originals[await subject.modelPath()],
    );
  });

  test('stale backup is restored before a new install starts', () async {
    var downloaderCalled = false;
    final subject = manager(
      downloader: (asset, destination, onBytes) async {
        downloaderCalled = true;
        throw const SocketException('stop after recovery');
      },
    );
    final dbPath = await subject.dbPath();
    await File(dbPath).parent.create(recursive: true);
    await File('$dbPath.backup').writeAsBytes([2, 2, 2, 2]);

    await expectLater(subject.download(), throwsA(isA<SocketException>()));

    expect(downloaderCalled, isTrue);
    expect(await File(dbPath).readAsBytes(), [2, 2, 2, 2]);
    expect(await File('$dbPath.backup').exists(), isFalse);
  });

  test('concurrent downloads coalesce into one transfer', () async {
    var calls = 0;
    final gate = Completer<void>();
    final subject = manager(
      downloader: (asset, destination, onBytes) async {
        calls++;
        if (calls == 1) await gate.future;
        await destination.writeAsBytes(List<int>.filled(asset.sizeBytes, 7));
      },
    );

    final first = subject.download();
    final second = subject.download();
    gate.complete();
    await Future.wait([first, second]);

    expect(calls, manifest.assets.length);
  });

  test(
    'delete requested during download waits then removes the pack',
    () async {
      final gate = Completer<void>();
      var calls = 0;
      final subject = manager(
        downloader: (asset, destination, onBytes) async {
          calls++;
          if (calls == 1) await gate.future;
          await destination.writeAsBytes(List<int>.filled(asset.sizeBytes, 7));
        },
      );

      final downloading = subject.download();
      final deleting = subject.delete();
      gate.complete();
      await Future.wait([downloading, deleting]);

      expect(await subject.resolveState(), NutritionPackState.notDownloaded);
    },
  );

  test('delete removes installed and partial pack files', () async {
    final subject = manager();
    for (final path in await subject.allPaths()) {
      await File(path).parent.create(recursive: true);
      await File(path).writeAsBytes([1]);
      await File('$path.part').writeAsBytes([1]);
    }

    await subject.delete();

    for (final path in await subject.allPaths()) {
      expect(await File(path).exists(), isFalse);
      expect(await File('$path.part').exists(), isFalse);
    }
    expect(await subject.resolveState(), NutritionPackState.notDownloaded);
  });
}
