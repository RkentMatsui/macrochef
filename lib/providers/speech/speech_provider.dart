abstract class SpeechProvider {
  Future<void> init();
  Future<void> startListening(
    void Function(String partial) onPartial,
    void Function(String finalText) onFinal, {
    void Function()? onSpeechEnd,
  });
  Future<void> stopListening();
  Future<void> speak(String text);
  Future<void> stopSpeaking();
  Future<void> dispose();
}
