import 'package:flutter/foundation.dart';
import 'speech_provider.dart';

// TODO(Task 8): replace with SherpaSpeechProvider once on-device voice is built.

/// No-op speech provider used during development and on desktop/emulator.
/// All methods complete without error; [speak] prints to debug console.
class StubSpeechProvider implements SpeechProvider {
  @override
  Future<void> init() async {}

  @override
  Future<void> startListening(
    void Function(String partial) onPartial,
    void Function(String finalText) onFinal, {
    void Function()? onSpeechEnd,
  }) async {}

  @override
  Future<void> stopListening() async {}

  @override
  Future<void> speak(String text) async {
    debugPrint('[TTS] $text');
  }

  @override
  Future<void> stopSpeaking() async {}

  @override
  Future<void> dispose() async {}
}
