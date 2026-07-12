import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'local_models.dart';

/// Filesystem home for downloaded models and path resolution.
class LocalModelManager {
  /// Absolute path where [model] is (or will be) stored.
  Future<String> pathFor(LocalModel model) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/models/llm/${model.fileName}';
  }

  /// Resolve download state by inspecting the file on disk.
  Future<LocalModelState> stateOf(LocalModel model) async {
    final f = File(await pathFor(model));
    if (!await f.exists()) return LocalModelState.notDownloaded;
    final size = await f.length();
    return resolveState(model, exists: true, sizeOnDisk: size);
  }
}

/// Download [model] to its on-device path, reporting fractional progress.
Future<void> downloadLocalModel(
  LocalModel model, {
  void Function(double progress)? onProgress,
}) async {
  final mgr = LocalModelManager();
  final dest = await mgr.pathFor(model);
  final file = File(dest);
  await file.parent.create(recursive: true);

  final client = HttpClient();
  final req = await client.getUrl(Uri.parse(model.url));
  final resp = await req.close();
  final total = resp.contentLength > 0 ? resp.contentLength : model.sizeBytes;
  var received = 0;
  final sink = file.openWrite();
  try {
    await for (final chunk in resp) {
      received += chunk.length;
      sink.add(chunk);
      onProgress?.call(received / total);
    }
  } finally {
    await sink.close();
    client.close(force: true);
  }
}

/// Delete the on-device file for [model].
Future<void> deleteLocalModel(LocalModel model) async {
  final f = File(await LocalModelManager().pathFor(model));
  if (await f.exists()) await f.delete();
}
