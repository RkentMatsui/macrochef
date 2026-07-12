import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'voice_model_files.dart';

/// Resolves the paths of the DOWNLOADED sherpa voice models (see
/// [VoiceModelManager]). The files live under `voice_models/…` mirroring their
/// old asset paths; nothing is bundled in the APK anymore.
class VoiceAssets {
  VoiceAssets._(this._dir);
  final String _dir;

  static Future<String> _baseDir() async {
    final base = await getApplicationSupportDirectory();
    return p.join(base.path, 'voice_models');
  }

  /// True when every voice file is present at (at least) its expected size.
  /// Uses async file I/O so it never blocks the UI isolate (it's called from
  /// the recipe list tap and the detail screen's initState).
  static Future<bool> isReady() async {
    final dir = await _baseDir();
    final onDisk = <String, int>{};
    for (final f in voiceModelFiles) {
      final file = File(p.join(dir, f.relPath));
      if (await file.exists()) onDisk[f.relPath] = await file.length();
    }
    return resolveVoiceState(onDisk) == VoiceState.ready;
  }

  /// Returns a ready [VoiceAssets]. Throws [StateError] if the pack is missing —
  /// callers gate on [isReady] first (the cook flow is disabled otherwise).
  static Future<VoiceAssets> ensure() async {
    if (!await isReady()) {
      throw StateError('Voice pack not downloaded — cannot start voice.');
    }
    return VoiceAssets._(await _baseDir());
  }

  String _path(String asset) => p.join(_dir, asset);

  String get whisperEncoder =>
      _path('assets/models/asr/base.en-encoder.int8.onnx');
  String get whisperDecoder =>
      _path('assets/models/asr/base.en-decoder.int8.onnx');
  String get whisperTokens => _path('assets/models/asr/base.en-tokens.txt');
  String get vadModel => _path('assets/models/asr/silero_vad.onnx');
  String get ttsModel => _path('assets/models/tts/vits-ljs.onnx');
  String get ttsLexicon => _path('assets/models/tts/lexicon.txt');
  String get ttsTokens => _path('assets/models/tts/tokens.txt');
}
