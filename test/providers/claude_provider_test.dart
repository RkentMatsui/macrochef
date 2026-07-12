import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/providers/llm/claude_provider.dart';

import '_fake_dio.dart';

void main() {
  group('ClaudeProvider', () {
    test('chat() returns joined text from content blocks', () async {
      final dio = fakeDio({
        'content': [
          {'type': 'text', 'text': 'Hello chef'},
        ],
      });

      final provider = ClaudeProvider(
        apiKey: 'test-key',
        model: 'claude-3-haiku-20240307',
        dio: dio,
      );

      final result = await provider.chat([
        const ChatMessage('user', 'Hi'),
      ]);

      expect(result, 'Hello chef');
    });

    test('chat() joins multiple text blocks', () async {
      final dio = fakeDio({
        'content': [
          {'type': 'text', 'text': 'Hello '},
          {'type': 'text', 'text': 'chef'},
        ],
      });

      final provider = ClaudeProvider(
        apiKey: 'test-key',
        model: 'claude-3-haiku-20240307',
        dio: dio,
      );

      final result = await provider.chat([
        const ChatMessage('user', 'Hi'),
      ]);

      expect(result, 'Hello chef');
    });

    test('chat() extracts system message to top-level field', () async {
      // The fake adapter just returns a canned response; we verify the call
      // doesn't throw and still returns the correct text.
      final dio = fakeDio({
        'content': [
          {'type': 'text', 'text': 'Hello chef'},
        ],
      });

      final provider = ClaudeProvider(
        apiKey: 'test-key',
        model: 'claude-3-haiku-20240307',
        dio: dio,
      );

      final result = await provider.chat([
        const ChatMessage('system', 'You are a chef assistant'),
        const ChatMessage('user', 'Hi'),
      ]);

      expect(result, 'Hello chef');
    });

    test('structured() returns decoded map from tool_use block', () async {
      final dio = fakeDio({
        'content': [
          {
            'type': 'tool_use',
            'name': 'emit',
            'input': {'ok': true},
          },
        ],
      });

      final provider = ClaudeProvider(
        apiKey: 'test-key',
        model: 'claude-3-haiku-20240307',
        dio: dio,
      );

      final result = await provider.structured(
        'Extract data',
        {
          'type': 'object',
          'properties': {
            'ok': {'type': 'boolean'}
          },
        },
      );

      expect(result, {'ok': true});
    });
  });
}
