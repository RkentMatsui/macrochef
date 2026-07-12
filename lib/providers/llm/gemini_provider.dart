import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../models/chat.dart';
import 'llm_provider.dart';

class GeminiProvider implements LLMProvider {
  final String apiKey;
  final String model;
  final Dio _dio;

  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  GeminiProvider({
    required this.apiKey,
    required this.model,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  String get _endpoint => '$_baseUrl/$model:generateContent?key=$apiKey';

  @override
  Future<String> chat(List<ChatMessage> messages, {ChatOpts? opts}) async {
    final joined = messages.map((m) => m.content).join('\n');

    final body = <String, dynamic>{
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': joined}
          ],
        }
      ],
    };

    if (opts?.maxTokens != null || opts?.temperature != null) {
      final genConfig = <String, dynamic>{};
      if (opts?.maxTokens != null) {
        genConfig['maxOutputTokens'] = opts!.maxTokens;
      }
      if (opts?.temperature != null) {
        genConfig['temperature'] = opts!.temperature;
      }
      body['generationConfig'] = genConfig;
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        data: jsonEncode(body),
        options: Options(headers: {'content-type': 'application/json'}),
      );
      return _extractText(response.data);
    } on DioException catch (e) {
      throw LlmException('Gemini chat error: ${_dioMessage(e)}');
    }
  }

  @override
  Future<Map<String, dynamic>> structured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) async {
    final body = <String, dynamic>{
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ],
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': jsonSchema,
      },
    };

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        data: jsonEncode(body),
        options: Options(headers: {'content-type': 'application/json'}),
      );
      final text = _extractText(response.data);
      return Map<String, dynamic>.from(jsonDecode(text) as Map);
    } on DioException catch (e) {
      throw LlmException('Gemini structured error: ${_dioMessage(e)}');
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
      'contents': [
        {
          'role': 'user',
          'parts': [
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Encode(imageBytes),
              },
            },
            {'text': prompt},
          ],
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'responseSchema': jsonSchema,
      },
    };
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        data: jsonEncode(body),
        options: Options(headers: {'content-type': 'application/json'}),
      );
      final text = _extractText(response.data);
      return Map<String, dynamic>.from(jsonDecode(text) as Map);
    } on DioException catch (e) {
      throw LlmException('Gemini vision error: ${_dioMessage(e)}');
    }
  }

  /// Pulls the first candidate's text out of a Gemini response, raising a
  /// legible [LlmException] instead of an opaque cast/range error when the
  /// shape is unexpected (no candidates, a safety-blocked prompt, or a missing
  /// text part). Without this, callers like FoodLookup.resolveFromImage that
  /// swallow exceptions would just see a silent null with no clue why.
  String _extractText(Map<String, dynamic>? data) {
    final candidates = data?['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      final reason = (data?['promptFeedback'] as Map?)?['blockReason'];
      throw LlmException(
          'Gemini returned no candidates${reason != null ? ' (blocked: $reason)' : ''}.');
    }
    final parts = (candidates[0] as Map?)?['content']?['parts'];
    if (parts is! List || parts.isEmpty || parts[0] is! Map || (parts[0] as Map)['text'] is! String) {
      throw LlmException('Gemini response contained no text part.');
    }
    return (parts[0] as Map)['text'] as String;
  }

  /// Builds a legible error string from a Dio failure: HTTP status + the API's
  /// error message (Gemini returns `{error: {message: ...}}`), falling back to
  /// the transport message. Without this, a 404 (e.g. retired model id) shows
  /// as a bare null/"Http status error".
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
