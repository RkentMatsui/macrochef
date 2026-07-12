// test/providers/speech/voice_model_manager_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/providers/speech/voice_model_files.dart';
import 'package:macrochef/providers/speech/voice_model_manager.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('voice_mgr'));
  tearDown(() async { if (await tmp.exists()) await tmp.delete(recursive: true); });

  VoiceModelManager mgr() => VoiceModelManager(baseDir: () async => tmp);

  test('state is notDownloaded on an empty dir', () async {
    expect(await mgr().state(), VoiceState.notDownloaded);
  });

  test('state is ready when every file is present at full size', () async {
    for (final f in voiceModelFiles) {
      final file = File(p.join(tmp.path, 'voice_models', f.relPath));
      await file.create(recursive: true);
      // Report the full expected length WITHOUT allocating ~280 MB of buffers:
      // a sparse truncate makes File.length() return sizeBytes cheaply, which is
      // all resolveVoiceState inspects.
      final raf = await file.open(mode: FileMode.write);
      await raf.truncate(f.sizeBytes);
      await raf.close();
    }
    expect(await mgr().state(), VoiceState.ready);
    expect(await mgr().isDownloaded(), isTrue);
  });

  test('delete removes the voice_models dir', () async {
    final file = File(p.join(tmp.path, 'voice_models', voiceModelFiles.first.relPath));
    await file.create(recursive: true);
    await file.writeAsBytes([1, 2, 3]);
    await mgr().delete();
    expect(await mgr().state(), VoiceState.notDownloaded);
  });
}
