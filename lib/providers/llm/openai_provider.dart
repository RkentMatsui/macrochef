import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../models/chat.dart';
import 'llm_provider.dart';

class OpenAIProvider implements LLMProvider {
  final String apiKey;
  final String model;
  final Dio _dio;

  static const _endpoint = 'https://api.openai.com/v1/chat/completions';

  OpenAIProvider({
    required this.apiKey,
    required this.model,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $apiKey',
        'content-type': 'application/json',
      };

  @override
  Future<String> chat(List<ChatMessage> messages, {ChatOpts? opts}) async {
    final body = <String, dynamic>{
      'model': opts?.model ?? model,
      'messages':
          messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
    };

    if (opts?.maxTokens != null) {
      body['max_tokens'] = opts!.maxTokens;
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
      final choices = response.data!['choices'] as List<dynamic>;
      return choices[0]['message']['content'] as String;
    } on DioException catch (e) {
      throw LlmException('OpenAI chat error: ${_dioMessage(e)}');
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
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'response_format': {
        'type': 'json_schema',
        'json_schema': {
          'name': 'emit',
          'schema': jsonSchema,
          'strict': true,
        },
      },
    };

    if (opts?.maxTokens != null) {
      body['max_tokens'] = opts!.maxTokens;
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
      final choices = response.data!['choices'] as List<dynamic>;
      final content = choices[0]['message']['content'] as String;
      return Map<String, dynamic>.from(jsonDecode(content) as Map);
    } on DioException catch (e) {
      throw LlmException('OpenAI structured error: ${_dioMessage(e)}');
    }
  }

  @override
  Future<Map<String, dynamic>> vision(
    Uint8List imageBytes,
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) {
    throw UnsupportedError(
      'OpenAI vision not implemented — switch to Claude or Gemini.',
    );
  }

  /// HTTP status + the API's error message (OpenAI returns
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
