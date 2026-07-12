import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../models/chat.dart';
import 'llm_provider.dart';

class ClaudeProvider implements LLMProvider {
  final String apiKey;
  final String model;
  final Dio _dio;

  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _defaultMaxTokens = 1024;

  ClaudeProvider({
    required this.apiKey,
    required this.model,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  Map<String, String> get _headers => {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      };

  @override
  Future<String> chat(List<ChatMessage> messages, {ChatOpts? opts}) async {
    final systemMessages =
        messages.where((m) => m.role == 'system').toList();
    final nonSystemMessages =
        messages.where((m) => m.role != 'system').toList();

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
        {
          'name': 'emit',
          'input_schema': jsonSchema,
        }
      ],
      'tool_choice': {'type': 'tool', 'name': 'emit'},
      'messages': [
        {'role': 'user', 'content': prompt}
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
        {'name': 'emit', 'input_schema': jsonSchema}
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
        }
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
