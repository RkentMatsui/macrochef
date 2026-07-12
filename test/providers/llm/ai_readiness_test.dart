// test/providers/llm/ai_readiness_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/providers/llm/ai_readiness.dart';
import 'package:macrochef/providers/llm/llm_provider_factory.dart';

void main() {
  test('cloud provider is ready only when an API key is set', () {
    expect(
        aiProviderReady(
            kind: LlmKind.claude, hasApiKey: true, localModelReady: false),
        isTrue);
    expect(
        aiProviderReady(
            kind: LlmKind.openai, hasApiKey: false, localModelReady: true),
        isFalse);
  });

  test('local provider is ready only when the model is downloaded', () {
    expect(
        aiProviderReady(
            kind: LlmKind.local, hasApiKey: false, localModelReady: true),
        isTrue);
    // A cloud key is irrelevant to the local provider.
    expect(
        aiProviderReady(
            kind: LlmKind.local, hasApiKey: true, localModelReady: false),
        isFalse);
  });

  test('hint points at the missing piece, null when ready', () {
    expect(
        aiDisabledHint(
            kind: LlmKind.claude, hasApiKey: false, localModelReady: false),
        'Add an AI provider key in Settings → AI Provider');
    expect(
        aiDisabledHint(
            kind: LlmKind.local, hasApiKey: false, localModelReady: false),
        'Download the on-device model in Settings → AI Provider');
    expect(
        aiDisabledHint(
            kind: LlmKind.claude, hasApiKey: true, localModelReady: false),
        isNull);
    expect(
        aiDisabledHint(
            kind: LlmKind.local, hasApiKey: false, localModelReady: true),
        isNull);
  });
}
