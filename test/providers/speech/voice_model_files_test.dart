// test/providers/speech/voice_model_files_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/providers/speech/voice_model_files.dart';

void main() {
  test('registry has the 7 sherpa files with unique relPaths', () {
    expect(voiceModelFiles.length, 7);
    final rels = voiceModelFiles.map((f) => f.relPath).toSet();
    expect(rels.length, 7);
    expect(rels, contains('assets/models/asr/base.en-encoder.int8.onnx'));
    expect(rels, contains('assets/models/tts/vits-ljs.onnx'));
  });

  test('every entry carries a url and a positive size', () {
    for (final f in voiceModelFiles) {
      expect(f.url, isNotEmpty);
      expect(f.sizeBytes, greaterThan(0));
    }
  });

  test('resolveVoiceState: all present+full → ready', () {
    final onDisk = {for (final f in voiceModelFiles) f.relPath: f.sizeBytes};
    expect(resolveVoiceState(onDisk), VoiceState.ready);
  });
  test('resolveVoiceState: none present → notDownloaded', () {
    expect(resolveVoiceState(const {}), VoiceState.notDownloaded);
  });
  test('resolveVoiceState: some present → partial', () {
    final f = voiceModelFiles.first;
    expect(resolveVoiceState({f.relPath: f.sizeBytes}), VoiceState.partial);
  });
  test('resolveVoiceState: a complete file alongside a short one → partial', () {
    // A short (truncated) file must NOT count as complete: one full file + one
    // one-byte-short file = 1 of 7 present → partial (an interrupted download).
    final full = voiceModelFiles[0];
    final short = voiceModelFiles[1];
    final onDisk = {
      full.relPath: full.sizeBytes,
      short.relPath: short.sizeBytes - 1,
    };
    expect(resolveVoiceState(onDisk), VoiceState.partial);
  });
  test('resolveVoiceState: every file short → notDownloaded', () {
    // Nothing is complete, so there is nothing usable to resume from.
    final onDisk = {for (final f in voiceModelFiles) f.relPath: f.sizeBytes - 1};
    expect(resolveVoiceState(onDisk), VoiceState.notDownloaded);
  });

  test('totalBytes sums the registry', () {
    final sum = voiceModelFiles.fold<int>(0, (s, f) => s + f.sizeBytes);
    expect(totalVoiceBytes, sum);
  });
}
