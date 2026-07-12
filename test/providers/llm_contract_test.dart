import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/providers/llm/claude_provider.dart';
import 'package:macrochef/providers/llm/gemini_provider.dart';
import 'package:macrochef/providers/llm/groq_provider.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/providers/llm/openai_provider.dart';

import '_fake_dio.dart';

/// Describes a test case for one provider variant.
class _ProviderCase {
  final String name;
  final LLMProvider provider;

  _ProviderCase(this.name, this.provider);
}

void main() {
  // ── Claude ─────────────────────────────────────────────────────────────────
  final claudeChatResponse = {
    'content': [
      {'type': 'text', 'text': 'Hello chef'},
    ],
  };
  final claudeStructuredResponse = {
    'content': [
      {
        'type': 'tool_use',
        'name': 'emit',
        'input': {'ok': true},
      },
    ],
  };

  // ── OpenAI ─────────────────────────────────────────────────────────────────
  final openaiChatResponse = {
    'choices': [
      {
        'message': {'role': 'assistant', 'content': 'Hello chef'},
      },
    ],
  };
  final openaiStructuredResponse = {
    'choices': [
      {
        'message': {
          'role': 'assistant',
          'content': jsonEncode({'ok': true}),
        },
      },
    ],
  };

  // ── Gemini ─────────────────────────────────────────────────────────────────
  final geminiChatResponse = {
    'candidates': [
      {
        'content': {
          'parts': [
            {'text': 'Hello chef'}
          ],
        },
      },
    ],
  };
  final geminiStructuredResponse = {
    'candidates': [
      {
        'content': {
          'parts': [
            {'text': jsonEncode({'ok': true})}
          ],
        },
      },
    ],
  };

  // ── Groq (OpenAI-compatible shape) ─────────────────────────────────────────
  final groqChatResponse = {
    'choices': [
      {
        'message': {'role': 'assistant', 'content': 'Hello chef'},
      },
    ],
  };
  final groqStructuredResponse = {
    'choices': [
      {
        'message': {
          'role': 'assistant',
          'content': jsonEncode({'ok': true}),
        },
      },
    ],
  };

  // ── Contract tests run for each provider ───────────────────────────────────
  group('LLMProvider contract — chat()', () {
    final chatCases = [
      _ProviderCase(
        'ClaudeProvider',
        ClaudeProvider(
          apiKey: 'key',
          model: 'claude-3-haiku-20240307',
          dio: fakeDio(claudeChatResponse),
        ),
      ),
      _ProviderCase(
        'OpenAIProvider',
        OpenAIProvider(
          apiKey: 'key',
          model: 'gpt-4o-mini',
          dio: fakeDio(openaiChatResponse),
        ),
      ),
      _ProviderCase(
        'GeminiProvider',
        GeminiProvider(
          apiKey: 'key',
          model: 'gemini-1.5-flash',
          dio: fakeDio(geminiChatResponse),
        ),
      ),
      _ProviderCase(
        'GroqProvider',
        GroqProvider(
          apiKey: 'key',
          model: 'llama-3.3-70b-versatile',
          dio: fakeDio(groqChatResponse),
        ),
      ),
    ];

    for (final tc in chatCases) {
      test('${tc.name} chat() returns expected text', () async {
        final result = await tc.provider.chat([
          const ChatMessage('user', 'Hi'),
        ]);
        expect(result, 'Hello chef');
      });
    }
  });

  group('LLMProvider contract — structured()', () {
    final structuredCases = [
      _ProviderCase(
        'ClaudeProvider',
        ClaudeProvider(
          apiKey: 'key',
          model: 'claude-3-haiku-20240307',
          dio: fakeDio(claudeStructuredResponse),
        ),
      ),
      _ProviderCase(
        'OpenAIProvider',
        OpenAIProvider(
          apiKey: 'key',
          model: 'gpt-4o-mini',
          dio: fakeDio(openaiStructuredResponse),
        ),
      ),
      _ProviderCase(
        'GeminiProvider',
        GeminiProvider(
          apiKey: 'key',
          model: 'gemini-1.5-flash',
          dio: fakeDio(geminiStructuredResponse),
        ),
      ),
      _ProviderCase(
        'GroqProvider',
        GroqProvider(
          apiKey: 'key',
          model: 'llama-3.3-70b-versatile',
          dio: fakeDio(groqStructuredResponse),
        ),
      ),
    ];

    for (final tc in structuredCases) {
      test('${tc.name} structured() returns expected map', () async {
        final result = await tc.provider.structured(
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
    }
  });
}
