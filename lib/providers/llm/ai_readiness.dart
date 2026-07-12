// lib/providers/llm/ai_readiness.dart
import 'llm_provider_factory.dart' show LlmKind;

/// Whether the currently-selected AI provider is usable *right now*. Cloud
/// providers (claude/openai/gemini/groq) need an API key; the on-device `local`
/// provider needs its model downloaded. Pure so it can be unit-tested; the live
/// facts (key present / model downloaded) are gathered by the caller.
bool aiProviderReady({
  required LlmKind kind,
  required bool hasApiKey,
  required bool localModelReady,
}) =>
    kind == LlmKind.local ? localModelReady : hasApiKey;

/// A hint for why an AI-requiring action is blocked, or null when AI is ready.
String? aiDisabledHint({
  required LlmKind kind,
  required bool hasApiKey,
  required bool localModelReady,
}) {
  if (aiProviderReady(
      kind: kind, hasApiKey: hasApiKey, localModelReady: localModelReady)) {
    return null;
  }
  return kind == LlmKind.local
      ? 'Download the on-device model in Settings → AI Provider'
      : 'Add an AI provider key in Settings → AI Provider';
}
