import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../models/chat.dart';
import 'llm_provider.dart';

/// Groq — OpenAI-compatible chat completions (free tier). Fast Llama models.
class GroqProvider implements LLMProvider {
  final String apiKey;
  final String model;
  final Dio _dio;

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  /// The configured text model (e.g. llama-3.3-70b-versatile) is text-only, so
  /// vision requests are routed to this multimodal Groq model instead.
  static const _visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  GroqProvider({
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
    if (opts?.maxTokens != null) body['max_tokens'] = opts!.maxTokens;
    if (opts?.temperature != null) body['temperature'] = opts!.temperature;

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        data: jsonEncode(body),
        options: Options(headers: _headers),
      );
      final choices = response.data!['choices'] as List<dynamic>;
      return choices[0]['message']['content'] as String;
    } on DioException catch (e) {
      throw LlmException('Groq chat error: ${_dioMessage(e)}');
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
        {
          'role': 'system',
          'content':
              'You output only a single JSON object conforming to this JSON schema. '
                  'No prose, no markdown fences. Schema: ${jsonEncode(jsonSchema)}'
        },
        {'role': 'user', 'content': prompt},
      ],
      'response_format': {'type': 'json_object'},
    };
    if (opts?.maxTokens != null) body['max_tokens'] = opts!.maxTokens;
    if (opts?.temperature != null) body['temperature'] = opts!.temperature;

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
      throw LlmException('Groq structured error: ${_dioMessage(e)}');
    }
  }

  @override
  Future<Map<String, dynamic>> vision(
    Uint8List imageBytes,
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) async {
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(imageBytes)}';
    final body = <String, dynamic>{
      // Force a vision-capable model; the configured text model can't see images.
      'model': opts?.model ?? _visionModel,
      'messages': [
        {
          'role': 'system',
          'content':
              'You output only a single JSON object conforming to this JSON schema. '
                  'No prose, no markdown fences. Schema: ${jsonEncode(jsonSchema)}'
        },
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': {'url': dataUrl},
            },
          ],
        },
      ],
      'response_format': {'type': 'json_object'},
    };
    if (opts?.maxTokens != null) body['max_tokens'] = opts!.maxTokens;
    if (opts?.temperature != null) body['temperature'] = opts!.temperature;

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
      throw LlmException('Groq vision error: ${_dioMessage(e)}');
    }
  }

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
