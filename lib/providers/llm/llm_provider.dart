import 'dart:typed_data';

import '../../models/chat.dart';

class LlmException implements Exception {
  final String message;
  LlmException(this.message);
  @override
  String toString() => 'LlmException: $message';
}

/// A source returned by a provider-native web search tool.
///
/// This stays independent of the food domain so provider adapters can retain
/// citations without knowing how callers will use the structured response.
class LlmWebCitation {
  final Uri url;
  final String title;

  const LlmWebCitation({required this.url, required this.title});
}

/// A structured response accompanied by the sources used to ground it.
class LlmGroundedStructuredResponse {
  final Map<String, dynamic> data;
  final List<LlmWebCitation> citations;

  const LlmGroundedStructuredResponse({
    required this.data,
    required this.citations,
  });
}

/// Optional provider capability. Keeping this separate from [LLMProvider]
/// avoids forcing existing offline/test implementations to pretend that they
/// can search the web.
abstract interface class LlmWebGroundingProvider {
  /// Whether this provider exposes a verified, native web-search tool.
  ///
  /// Callers must check this before grounding; the default keeps existing test
  /// fakes and third-party implementations source-compatible.
  bool get supportsWebGrounding;

  /// Uses the provider's native web-search facility and retains its citations.
  /// Unsupported providers fail before any network request.
  Future<LlmGroundedStructuredResponse> groundedStructured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  });
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

/// Capability access for callers which only hold an [LLMProvider].
extension LLMProviderWebGrounding on LLMProvider {
  bool get supportsWebGrounding =>
      this is LlmWebGroundingProvider &&
      (this as LlmWebGroundingProvider).supportsWebGrounding;

  Future<LlmGroundedStructuredResponse> groundedStructured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) {
    final provider = this;
    if (provider is! LlmWebGroundingProvider ||
        !provider.supportsWebGrounding) {
      throw UnsupportedError(
        'This LLM provider does not support web grounding.',
      );
    }
    return (provider as LlmWebGroundingProvider).groundedStructured(
      prompt,
      jsonSchema,
      opts: opts,
    );
  }
}
