import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../models/chat.dart';
import 'llm_provider.dart';

class ClaudeProvider implements LLMProvider, LlmWebGroundingProvider {
  final String apiKey;
  final String model;
  final Dio _dio;

  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _defaultMaxTokens = 1024;

  ClaudeProvider({required this.apiKey, required this.model, Dio? dio})
    : _dio = dio ?? Dio();

  Map<String, String> get _headers => {
    'x-api-key': apiKey,
    'anthropic-version': '2023-06-01',
    'content-type': 'application/json',
  };

  @override
  bool get supportsWebGrounding => true;

  @override
  Future<LlmGroundedStructuredResponse> groundedStructured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) async {
    // Anthropic returns web-search citations in content blocks. Do not force
    // `emit`: server-side web search cannot be forced, and forcing emit would
    // prevent Claude from searching before producing structured output.
    final body = <String, dynamic>{
      'model': opts?.model ?? model,
      'max_tokens': opts?.maxTokens ?? _defaultMaxTokens,
      'tools': [
        {'type': 'web_search_20250305', 'name': 'web_search'},
        {'name': 'emit', 'input_schema': jsonSchema},
      ],
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    };
    if (opts?.temperature != null) body['temperature'] = opts!.temperature;
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        data: jsonEncode(body),
        options: Options(
          headers: {..._headers, 'anthropic-beta': 'web-search-2025-03-05'},
        ),
      );
      final content = response.data?['content'];
      if (content is! List) {
        throw LlmException('Claude grounded response contained no content.');
      }
      final toolUse = content
          .cast<dynamic>()
          .whereType<Map>()
          .cast<Map?>()
          .firstWhere(
            (block) => block?['type'] == 'tool_use' && block?['name'] == 'emit',
            orElse: () => null,
          );
      if (toolUse == null || toolUse['input'] is! Map) {
        throw LlmException(
          'Claude grounded response contained no structured output.',
        );
      }
      return LlmGroundedStructuredResponse(
        data: Map<String, dynamic>.from(toolUse['input'] as Map),
        citations: _extractCitations(content),
      );
    } on DioException catch (e) {
      throw LlmException('Claude grounded search error: ${_dioMessage(e)}');
    }
  }

  List<LlmWebCitation> _extractCitations(Object? value) {
    final citations = <LlmWebCitation>[];
    void visit(Object? node) {
      if (node is Map) {
        final rawUrl = node['url'];
        final rawTitle = node['title'];
        final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
        if (uri != null &&
            uri.hasScheme &&
            rawTitle is String &&
            rawTitle.trim().isNotEmpty) {
          final citation = LlmWebCitation(url: uri, title: rawTitle.trim());
          if (!citations.any((item) => item.url == citation.url)) {
            citations.add(citation);
          }
        }
        for (final child in node.values) {
          visit(child);
        }
      } else if (node is Iterable) {
        for (final child in node) {
          visit(child);
        }
      }
    }

    visit(value);
    return citations;
  }

  @override
  Future<String> chat(List<ChatMessage> messages, {ChatOpts? opts}) async {
    final systemMessages = messages.where((m) => m.role == 'system').toList();
    final nonSystemMessages = messages
        .where((m) => m.role != 'system')
        .toList();

    final body = <String, dynamic>{
      'model': opts?.model ?? model,
      'max_tokens': opts?.maxTokens ?? _defaultMaxTokens,
      'messages': nonSystemMessages
          .map((m) => {'role': m.role, 'content': m.content})
          .toList(),
    };

    if (systemMessages.isNotEmpty) {
      body['system'] = systemMessages.map((m) => m.content).join('\n');
    }

    if (opts?.temperature != null) {
      body['temperature'] = opts!.temperature;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        data: jsonEncode(body),
        options: Options(headers: _headers),
      );
      final content = response.data!['content'] as List<dynamic>;
      return content
          .where((block) => block['type'] == 'text')
          .map((block) => block['text'] as String)
          .join('');
    } on DioException catch (e) {
      throw LlmException('Claude chat error: ${_dioMessage(e)}');
    }
  }

  @override
  Future<Map<String, dynamic>> structured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) async {
    final body = <String, dynamic>{
      'model': opts?.model ?? model,
      'max_tokens': opts?.maxTokens ?? _defaultMaxTokens,
      'tools': [
        {'name': 'emit', 'input_schema': jsonSchema},
      ],
      'tool_choice': {'type': 'tool', 'name': 'emit'},
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    };

    if (opts?.temperature != null) {
      body['temperature'] = opts!.temperature;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        data: jsonEncode(body),
        options: Options(headers: _headers),
      );
      final content = response.data!['content'] as List<dynamic>;
      final toolUseBlock = content.firstWhere(
        (block) => block['type'] == 'tool_use',
      );
      return Map<String, dynamic>.from(toolUseBlock['input'] as Map);
    } on DioException catch (e) {
      throw LlmException('Claude structured error: ${_dioMessage(e)}');
    }
  }

  @override
  Future<Map<String, dynamic>> vision(
    Uint8List imageBytes,
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) async {
    final body = <String, dynamic>{
      'model': opts?.model ?? model,
      'max_tokens': opts?.maxTokens ?? _defaultMaxTokens,
      'tools': [
        {'name': 'emit', 'input_schema': jsonSchema},
      ],
      'tool_choice': {'type': 'tool', 'name': 'emit'},
      'messages': [
        {
          'role': 'user',
          'content': [
            {
              'type': 'image',
              'source': {
                'type': 'base64',
                'media_type': 'image/jpeg',
                'data': base64Encode(imageBytes),
              },
            },
            {'type': 'text', 'text': prompt},
          ],
        },
      ],
    };
    if (opts?.temperature != null) body['temperature'] = opts!.temperature;
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        data: jsonEncode(body),
        options: Options(headers: _headers),
      );
      final content = response.data!['content'] as List<dynamic>;
      final toolUseBlock = content.firstWhere(
        (block) => block['type'] == 'tool_use',
      );
      return Map<String, dynamic>.from(toolUseBlock['input'] as Map);
    } on DioException catch (e) {
      throw LlmException('Claude vision error: ${_dioMessage(e)}');
    }
  }

  /// HTTP status + the API's error message (Anthropic returns
  /// `{error: {message: ...}}`), falling back to the transport message — so a
  /// 401 (bad/foreign key) or 404 (bad model) is legible instead of null.
  String _dioMessage(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String? apiMsg;
    if (data is Map && data['error'] is Map) {
      apiMsg = (data['error'] as Map)['message']?.toString();
    }
    final detail = apiMsg ?? (data?.toString() ?? e.message ?? 'unknown error');
    return status != null ? '[$status] $detail' : detail;
  }
}
