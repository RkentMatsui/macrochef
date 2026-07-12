import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/providers/llm/local/local_prompt.dart';

void main() {
  test('buildChatPrompt joins roles in order with a trailing assistant cue', () {
    final msgs = [
      ChatMessage('system', 'You are terse.'),
      ChatMessage('user', 'Hi'),
    ];
    final p = buildChatPrompt(msgs);
    expect(p.indexOf('You are terse.') < p.indexOf('Hi'), isTrue);
    expect(p.trimRight().endsWith('Assistant:'), isTrue);
  });

  test('buildStructuredPrompt embeds the schema and demands JSON-only output', () {
    final p = buildStructuredPrompt('Extract macros', {
      'type': 'object',
      'properties': {'kcal': {'type': 'number'}},
    });
    expect(p.contains('Extract macros'), isTrue);
    expect(p.contains('"kcal"'), isTrue);
    expect(p.toLowerCase().contains('json'), isTrue);
  });
}
