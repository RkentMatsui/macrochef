import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/services/llm_food_web_grounder.dart';

class _GroundingLlm implements LLMProvider, LlmWebGroundingProvider {
  final LlmGroundedStructuredResponse response;
  int calls = 0;

  _GroundingLlm(this.response);

  @override
  bool get supportsWebGrounding => true;

  @override
  Future<LlmGroundedStructuredResponse> groundedStructured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) async {
    calls++;
    return response;
  }

  @override
  Future<String> chat(List<ChatMessage> messages, {ChatOpts? opts}) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> structured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> vision(
    dynamic imageBytes,
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) => throw UnimplementedError();
}

class _OfflineLlm implements LLMProvider {
  @override
  Future<String> chat(List<ChatMessage> messages, {ChatOpts? opts}) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> structured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> vision(
    dynamic imageBytes,
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) => throw UnimplementedError();
}

void main() {
  final citedResponse = LlmGroundedStructuredResponse(
    data: {
      'name': 'Chicken curry',
      'quantity': 240,
      'unit': 'g',
      'kcal': 510,
      'protein': 35,
      'carb': 48,
      'fat': 19,
      'physicalGrams': 240,
      'fibre': null,
      'sodium': null,
      'inferredFields': ['carb'],
    },
    citations: [
      LlmWebCitation(
        url: Uri.parse('https://example.com/nutrition'),
        title: 'Official nutrition facts',
      ),
    ],
  );

  test(
    'converts cited provider response into a grounded portion basis',
    () async {
      final llm = _GroundingLlm(citedResponse);
      final grounder = LlmFoodWebGrounder(
        llm: llm,
        clock: () => DateTime.utc(2026, 7, 15),
      );

      final result = await grounder.ground('chicken curry');

      expect(llm.calls, 1);
      expect(result?.basis.quantity, 240);
      expect(result?.basis.unit, 'g');
      expect(result?.basis.macros.kcal, 510);
      expect(result?.provenance.url.host, 'example.com');
      expect(result?.isEstimate, isTrue);
    },
  );

  test(
    'rejects an otherwise valid response without a provider citation',
    () async {
      final llm = _GroundingLlm(
        LlmGroundedStructuredResponse(
          data: citedResponse.data,
          citations: const [],
        ),
      );

      expect(await LlmFoodWebGrounder(llm: llm).ground('curry'), isNull);
    },
  );

  test('does not call ordinary or unsupported providers', () async {
    expect(
      await LlmFoodWebGrounder(llm: _OfflineLlm()).ground('curry'),
      isNull,
    );
  });
}
