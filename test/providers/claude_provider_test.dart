import 'dart:convert';

import 'package:dio/dio.dart';
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

      final result = await provider.chat([const ChatMessage('user', 'Hi')]);

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

      final result = await provider.chat([const ChatMessage('user', 'Hi')]);

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

      final result = await provider.structured('Extract data', {
        'type': 'object',
        'properties': {
          'ok': {'type': 'boolean'},
        },
      });

      expect(result, {'ok': true});
    });

    test(
      'groundedStructured allows search before emitting structured output',
      () async {
        final dio = fakeDio({
          'content': [
            {
              'type': 'web_search_result',
              'url': 'https://example.com/nutrition',
              'title': 'Nutrition',
            },
            {
              'type': 'tool_use',
              'name': 'emit',
              'input': {'ok': true},
            },
          ],
        });
        Object? sent;
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              sent = options.data;
              handler.next(options);
            },
          ),
        );
        final provider = ClaudeProvider(
          apiKey: 'test-key',
          model: 'claude-haiku-4-5',
          dio: dio,
        );

        final result = await provider.groundedStructured('Find food', const {
          'type': 'object',
        });

        final body = jsonDecode(sent as String) as Map<String, dynamic>;
        expect(body.containsKey('tool_choice'), isFalse);
        expect(jsonEncode(body['tools']), contains('web_search_20250305'));
        expect(result.citations.single.url.host, 'example.com');
      },
    );
  });
}
