// lib/providers/speech/voice_model_manager.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'voice_model_files.dart';

/// Downloads / inspects / deletes the optional voice model pack. [baseDir] is
/// injected so tests avoid path_provider (defaults to the app support dir, which
/// is where VoiceAssets also resolves).
class VoiceModelManager {
  final Future<Directory> Function() baseDir;
  VoiceModelManager({Future<Directory> Function()? baseDir})
      : baseDir = baseDir ?? getApplicationSupportDirectory;

  Future<String> _pathFor(String relPath) async =>
      p.join((await baseDir()).path, 'voice_models', relPath);

  Future<VoiceState> state() async {
    final onDisk = <String, int>{};
    for (final f in voiceModelFiles) {
      final file = File(await _pathFor(f.relPath));
      if (await file.exists()) onDisk[f.relPath] = await file.length();
    }
    return resolveVoiceState(onDisk);
  }

  Future<bool> isDownloaded() async => (await state()) == VoiceState.ready;

  /// Download every file, reporting aggregate progress weighted by byte size.
  Future<void> download({void Function(double progress)? onProgress}) async {
    final total = totalVoiceBytes;
    var done = 0;
    final client = HttpClient();
    try {
      for (final f in voiceModelFiles) {
        final dest = File(await _pathFor(f.relPath));
        // Resume: skip files already complete so an interrupted run doesn't
        // re-fetch ~266 MB — still count them toward aggregate progress.
        if (await dest.exists() && await dest.length() >= f.sizeBytes) {
          done += f.sizeBytes;
          if (total > 0) onProgress?.call(done / total);
          continue;
        }
        await dest.parent.create(recursive: true);
        final resp = await (await client.getUrl(Uri.parse(f.url))).close();
        // HttpClient does NOT throw on 4xx/5xx. Without this guard an error page
        // (e.g. a 404 from a wrong release URL) would be written as if it were a
        // valid model file and falsely read as "downloaded ✓".
        if (resp.statusCode != HttpStatus.ok) {
          throw HttpException('GET failed: HTTP ${resp.statusCode}',
              uri: Uri.parse(f.url));
        }
        final sink = dest.openWrite();
        try {
          await for (final chunk in resp) {
            done += chunk.length;
            sink.add(chunk);
            if (total > 0) onProgress?.call(done / total);
          }
        } finally {
          await sink.close();
        }
      }
    } finally {
      client.close();
    }
  }

  Future<void> delete() async {
    final dir = Directory(p.join((await baseDir()).path, 'voice_models'));
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
