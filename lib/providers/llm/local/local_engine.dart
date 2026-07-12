// lib/providers/llm/local/local_engine.dart

/// Hardware backend for on-device inference.
enum LocalBackend { cpu, gpu }

/// Generation parameters passed to a [LocalEngine].
class LocalGenOpts {
  final double temperature;
  final int maxTokens;

  /// When non-null, the engine SHOULD constrain output to this JSON schema if it
  /// supports native structured decoding. Engines without that capability ignore
  /// it; [LocalLlmProvider] applies a prompt+repair fallback instead.
  final Map<String, dynamic>? jsonSchema;

  const LocalGenOpts({
    this.temperature = 0.4,
    this.maxTokens = 1024,
    this.jsonSchema,
  });
}

/// Thin seam over a native on-device LLM runtime. The real implementation
/// (FlutterGemmaEngine) runs only on Android/iOS; tests inject a fake so all
/// provider logic is exercised without MediaPipe.
abstract class LocalEngine {
  /// Load the model at [modelPath] into memory. Idempotent per instance.
  Future<void> load(String modelPath, {LocalBackend backend = LocalBackend.cpu});

  /// Produce a completion for [prompt].
  Future<String> generate(String prompt, {LocalGenOpts opts = const LocalGenOpts()});

  /// Release native resources.
  Future<void> dispose();
}
