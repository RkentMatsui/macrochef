import 'dart:convert';

import 'package:dio/dio.dart';
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
            {'text': 'Hello chef'},
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
            {
              'text': jsonEncode({'ok': true}),
            },
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
        final result = await tc.provider.structured('Extract data', {
          'type': 'object',
          'properties': {
            'ok': {'type': 'boolean'},
          },
        });
        expect(result, {'ok': true});
      });
    }
  });

  group('LLMProvider web-grounding capability', () {
    test(
      'supported providers request their native search tool and retain URLs',
      () async {
        final cases =
            <
              ({
                LLMProvider provider,
                Map<String, dynamic> response,
                String tool,
              })
            >[
              (
                provider: OpenAIProvider(apiKey: 'key', model: 'gpt-4o-mini'),
                response: {
                  'output': [
                    {
                      'content': [
                        {
                          'type': 'output_text',
                          'text': jsonEncode({'ok': true}),
                          'annotations': [
                            {
                              'type': 'url_citation',
                              'url': 'https://example.com/openai',
                              'title': 'OpenAI source',
                            },
                          ],
                        },
                      ],
                    },
                  ],
                },
                tool: 'web_search',
              ),
              (
                provider: GeminiProvider(
                  apiKey: 'key',
                  model: 'gemini-2.0-flash',
                ),
                response: {
                  'candidates': [
                    {
                      'content': {
                        'parts': [
                          {
                            'text': jsonEncode({'ok': true}),
                          },
                        ],
                      },
                      'groundingMetadata': {
                        'groundingChunks': [
                          {
                            'web': {
                              'uri': 'https://example.com/gemini',
                              'title': 'Gemini source',
                            },
                          },
                        ],
                      },
                    },
                  ],
                },
                tool: 'google_search',
              ),
              (
                provider: ClaudeProvider(
                  apiKey: 'key',
                  model: 'claude-haiku-4-5',
                ),
                response: {
                  'content': [
                    {
                      'type': 'web_search_result',
                      'url': 'https://example.com/claude',
                      'title': 'Claude source',
                    },
                    {
                      'type': 'tool_use',
                      'name': 'emit',
                      'input': {'ok': true},
                    },
                  ],
                },
                tool: 'web_search_20250305',
              ),
            ];

        for (final item in cases) {
          final provider = item.provider;
          final dio = fakeDio(item.response);
          Object? sent;
          dio.interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                sent = options.data;
                handler.next(options);
              },
            ),
          );
          final LLMProvider wired = switch (provider) {
            OpenAIProvider p => OpenAIProvider(
              apiKey: p.apiKey,
              model: p.model,
              dio: dio,
            ),
            GeminiProvider p => GeminiProvider(
              apiKey: p.apiKey,
              model: p.model,
              dio: dio,
            ),
            ClaudeProvider p => ClaudeProvider(
              apiKey: p.apiKey,
              model: p.model,
              dio: dio,
            ),
            _ => throw StateError('Unexpected provider'),
          };

          expect(wired.supportsWebGrounding, isTrue);
          final result = await wired.groundedStructured('food', {
            'type': 'object',
            'properties': {
              'ok': {'type': 'boolean'},
            },
          });
          expect(result.data, {'ok': true});
          expect(result.citations, hasLength(1));
          expect(jsonEncode(sent), contains(item.tool));
        }
      },
    );

    test('Groq fails unsupported before I/O', () async {
      final provider = GroqProvider(
        apiKey: 'key',
        model: 'llama-3.3-70b-versatile',
        dio: fakeDio({}),
      );

      expect(provider.supportsWebGrounding, isFalse);
      expect(
        () => provider.groundedStructured('food', const {'type': 'object'}),
        throwsUnsupportedError,
      );
    });
  });
}
