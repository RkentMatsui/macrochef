import 'llm_provider.dart';
import 'claude_provider.dart';
import 'openai_provider.dart';
import 'gemini_provider.dart';
import 'groq_provider.dart';
import 'local_provider.dart';
import 'local/local_engine.dart';
import 'local/local_models.dart';
import 'local/local_model_manager.dart';
import 'local/flutter_gemma_engine.dart';

enum LlmKind { claude, openai, gemini, groq, local }

/// Default model id per provider. Single source of truth used by both the
/// Settings UI and the [llmProvider] fallback so a provider is never built with
/// another provider's model (which caused Gemini 404s when `llm_model` was unset).
const defaultModels = <LlmKind, String>{
  LlmKind.claude: 'claude-haiku-4-5',
  LlmKind.openai: 'gpt-4o-mini',
  LlmKind.gemini: 'gemini-2.0-flash',
  LlmKind.groq: 'llama-3.3-70b-versatile',
  LlmKind.local: kDefaultLocalModelId,
};

String defaultModelFor(LlmKind kind) => defaultModels[kind]!;

/// Selectable models per provider (used by the Settings model dropdown).
final providerModels = <LlmKind, List<String>>{
  LlmKind.claude: ['claude-haiku-4-5', 'claude-sonnet-4-6', 'claude-opus-4-8'],
  LlmKind.openai: ['gpt-4o-mini', 'gpt-4o'],
  LlmKind.gemini: ['gemini-2.0-flash', 'gemini-2.5-flash'],
  LlmKind.groq: ['llama-3.3-70b-versatile', 'llama-3.1-8b-instant'],
  LlmKind.local: [for (final m in localModels) m.id],
};

List<String> modelsFor(LlmKind kind) => providerModels[kind]!;

LLMProvider buildLlm(LlmKind kind, String apiKey, String model) {
  switch (kind) {
    case LlmKind.claude:
      return ClaudeProvider(apiKey: apiKey, model: model);
    case LlmKind.openai:
      return OpenAIProvider(apiKey: apiKey, model: model);
    case LlmKind.gemini:
      return GeminiProvider(apiKey: apiKey, model: model);
    case LlmKind.groq:
      return GroqProvider(apiKey: apiKey, model: model);
    case LlmKind.local:
      final mgr = LocalModelManager();
      final m = localModelById(model) ?? localModels.first;
      return LocalLlmProvider(
        model: model,
        engine: FlutterGemmaEngine(arch: m.arch, maxTokens: m.maxTokens),
        resolveModelPath: () async => mgr.pathFor(m),
        // GPU backend keeps inference off the CPU so the UI stays responsive
        // while the model generates.
        backend: LocalBackend.gpu,
      );
  }
}
