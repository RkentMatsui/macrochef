// lib/providers/speech/voice_model_files.dart

enum VoiceState { notDownloaded, partial, ready }

/// One downloadable voice model file. [relPath] is the path UNDER the
/// `voice_models/` dir — identical to the asset path VoiceAssets returns, so the
/// downloader and VoiceAssets stay in lockstep.
class VoiceModelFile {
  final String relPath;
  final String fileName;
  final String url;
  final int sizeBytes;
  const VoiceModelFile({
    required this.relPath,
    required this.fileName,
    required this.url,
    required this.sizeBytes,
  });
}

// GitHub Release assets. Sizes are the EXACT on-disk byte counts of the files
// fetched by `tool/fetch_voice_models.sh` (so a truncated download reads as
// `partial`). The `voice-pack-v1` release must carry these same files.
const String _base =
    'https://github.com/RkentMatsui/macrochef/releases/download/voice-pack-v1';

const List<VoiceModelFile> voiceModelFiles = [
  VoiceModelFile(relPath: 'assets/models/asr/base.en-encoder.int8.onnx',
      fileName: 'base.en-encoder.int8.onnx', url: '$_base/base.en-encoder.int8.onnx', sizeBytes: 29120534),
  VoiceModelFile(relPath: 'assets/models/asr/base.en-decoder.int8.onnx',
      fileName: 'base.en-decoder.int8.onnx', url: '$_base/base.en-decoder.int8.onnx', sizeBytes: 130669978),
  VoiceModelFile(relPath: 'assets/models/asr/base.en-tokens.txt',
      fileName: 'base.en-tokens.txt', url: '$_base/base.en-tokens.txt', sizeBytes: 835554),
  VoiceModelFile(relPath: 'assets/models/asr/silero_vad.onnx',
      fileName: 'silero_vad.onnx', url: '$_base/silero_vad.onnx', sizeBytes: 643854),
  VoiceModelFile(relPath: 'assets/models/tts/vits-ljs.onnx',
      fileName: 'vits-ljs.onnx', url: '$_base/vits-ljs.onnx', sizeBytes: 114124456),
  VoiceModelFile(relPath: 'assets/models/tts/lexicon.txt',
      fileName: 'lexicon.txt', url: '$_base/lexicon.txt', sizeBytes: 3708181),
  VoiceModelFile(relPath: 'assets/models/tts/tokens.txt',
      fileName: 'tokens.txt', url: '$_base/tokens.txt', sizeBytes: 1084),
];

int get totalVoiceBytes =>
    voiceModelFiles.fold<int>(0, (s, f) => s + f.sizeBytes);

/// Resolve overall state from a map of relPath → size-on-disk (absent = missing).
VoiceState resolveVoiceState(Map<String, int> onDisk) {
  var present = 0;
  for (final f in voiceModelFiles) {
    final sz = onDisk[f.relPath];
    if (sz != null && sz >= f.sizeBytes) present++;
  }
  if (present == 0) return VoiceState.notDownloaded;
  if (present == voiceModelFiles.length) return VoiceState.ready;
  return VoiceState.partial;
}
