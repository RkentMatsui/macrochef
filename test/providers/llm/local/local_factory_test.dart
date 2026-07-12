import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/providers/llm/llm_provider_factory.dart';
import 'package:macrochef/providers/llm/local_provider.dart';

void main() {
  test('LlmKind has a local case with a default model', () {
    expect(LlmKind.values.contains(LlmKind.local), isTrue);
    expect(defaultModelFor(LlmKind.local), isNotEmpty);
    expect(modelsFor(LlmKind.local), isNotEmpty);
  });

  test('buildLlm(local) returns a LocalLlmProvider without an API key', () {
    final p = buildLlm(LlmKind.local, '', defaultModelFor(LlmKind.local));
    expect(p, isA<LocalLlmProvider>());
  });
}
