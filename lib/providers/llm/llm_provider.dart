import 'dart:typed_data';

import '../../models/chat.dart';

class LlmException implements Exception {
  final String message;
  LlmException(this.message);
  @override
  String toString() => 'LlmException: $message';
}

abstract class LLMProvider {
  Future<String> chat(List<ChatMessage> messages, {ChatOpts? opts});
  Future<Map<String, dynamic>> structured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  });

  /// Analyse [imageBytes] (JPEG) and return structured JSON matching [jsonSchema].
  /// Throws [UnsupportedError] for providers without multimodal support.
  Future<Map<String, dynamic>> vision(
    Uint8List imageBytes,
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  });
}
