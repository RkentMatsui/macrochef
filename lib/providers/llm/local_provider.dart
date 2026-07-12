import 'dart:typed_data';

import '../../models/chat.dart';
import 'llm_provider.dart';
import 'local/local_engine.dart';
import 'local/local_json.dart';
import 'local/local_prompt.dart';

/// On-device LLM provider backed by a [LocalEngine] (flutter_gemma in prod).
///
/// The model file loads lazily on first use, guarded by a single-flight [Future]
/// so concurrent first calls share one load. No API key is used.
class LocalLlmProvider implements LLMProvider {
  final String model;
  final LocalEngine engine;

  /// Resolves the absolute path of the downloaded model file. Injected so tests
  /// don't hit the filesystem; production wires this to the model manager.
  final Future<String> Function() resolveModelPath;

  final LocalBackend backend;

  Future<void>? _ready;

  LocalLlmProvider({
    required this.model,
    required this.engine,
    required this.resolveModelPath,
    this.backend = LocalBackend.cpu,
  });

  Future<void> _ensureReady() {
    return _ready ??= () async {
      try {
        final path = await resolveModelPath();
        await engine.load(path, backend: backend);
      } catch (e) {
        _ready = null; // allow a later retry after the user fixes the model
        throw LlmException('Local model not ready: $e');
      }
    }();
  }

  @override
  Future<String> chat(List<ChatMessage> messages, {ChatOpts? opts}) async {
    await _ensureReady();
    return engine.generate(buildChatPrompt(messages));
  }

  @override
  Future<Map<String, dynamic>> structured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) async {
    await _ensureReady();
    final p = buildStructuredPrompt(prompt, jsonSchema);
    final genOpts = LocalGenOpts(jsonSchema: jsonSchema);

    final first = await engine.generate(p, opts: genOpts);
    final parsed = extractJsonObject(first);
    if (parsed != null) return parsed;

    // One repair retry with a stricter nudge.
    final retryPrompt = '$p\n\n(Previous answer was not valid JSON. '
        'Return ONLY the JSON object.)';
    final second = await engine.generate(retryPrompt, opts: genOpts);
    final reparsed = extractJsonObject(second);
    if (reparsed != null) return reparsed;

    final snippet = second.length > 200 ? second.substring(0, 200) : second;
    throw LlmException('Local model did not return valid JSON: $snippet');
  }

  @override
  Future<Map<String, dynamic>> vision(
    Uint8List imageBytes,
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) {
    throw UnsupportedError('Local provider does not support vision yet.');
  }
}
