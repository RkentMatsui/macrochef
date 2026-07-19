import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/models/food_unit_weight.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/services/llm_food_web_grounder.dart';

class _GroundingLlm implements LLMProvider, LlmWebGroundingProvider {
  final LlmGroundedStructuredResponse response;
  int calls = 0;
  String? prompt;
  Map<String, dynamic>? schema;
  Object? error;

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
    this.prompt = prompt;
    schema = jsonSchema;
    if (error != null) throw error!;
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

  group('unit-weight grounding', () {
    LlmGroundedStructuredResponse unitWeightResponse({
      String name = 'Mission Flour Tortillas',
      String unit = 'piece',
      num grams = 140,
      String evidenceKind = 'published',
      List<LlmWebCitation>? citations,
    }) => LlmGroundedStructuredResponse(
      data: {
        'matchedName': name,
        'unit': unit,
        'gramsPerUnit': grams,
        'evidenceKind': evidenceKind,
      },
      citations:
          citations ??
          [
            LlmWebCitation(
              url: Uri.parse('https://example.com/label'),
              title: 'Official nutrition label',
            ),
          ],
    );

    test('returns exact cited published manufacturer unit weight', () async {
      final llm = _GroundingLlm(unitWeightResponse());
      final result = await LlmFoodWebGrounder(
        llm: llm,
        clock: () => DateTime.utc(2026, 7, 18),
      ).groundUnitWeight('Mission Flour Tortillas', requestedUnit: 'piece');

      expect(result?.weight.foodName, 'Mission Flour Tortillas');
      expect(result?.weight.unit, 'piece');
      expect(result?.weight.gramsPerUnit, 140);
      expect(result?.weight.kind, FoodUnitWeightKind.published);
      expect(result?.weight.provenance.url.host, 'example.com');
    });

    test('returns cited exact generic unit weight', () async {
      final llm = _GroundingLlm(
        unitWeightResponse(name: 'Medium apple', unit: 'piece', grams: 85),
      );
      final result = await LlmFoodWebGrounder(
        llm: llm,
      ).groundUnitWeight('Medium apple', requestedUnit: 'piece');

      expect(result?.weight.gramsPerUnit, 85);
      expect(result?.weight.kind, FoodUnitWeightKind.published);
    });

    test('marks cited generic typical average as estimated', () async {
      final llm = _GroundingLlm(
        unitWeightResponse(
          name: 'Cooked rice',
          unit: 'cup',
          grams: 150,
          evidenceKind: 'average',
        ),
      );
      final result = await LlmFoodWebGrounder(
        llm: llm,
      ).groundUnitWeight('Cooked rice', requestedUnit: 'cup');

      expect(result?.weight.kind, FoodUnitWeightKind.average);
      expect(result?.isEstimate, isTrue);
      expect(
        result?.weight.provenance.inferredFields,
        contains('gramsPerUnit'),
      );
    });

    test(
      'requires native search and exact-unit evidence in its prompt',
      () async {
        final llm = _GroundingLlm(unitWeightResponse());
        await LlmFoodWebGrounder(
          llm: llm,
        ).groundUnitWeight('Mission Flour Tortillas', requestedUnit: 'piece');

        expect(llm.prompt, contains('manufacturer'));
        expect(llm.prompt, contains('USDA'));
        expect(llm.prompt, contains('reputable retailer'));
        expect(llm.prompt, contains('exact requested unit'));
        expect(llm.prompt, contains('do not substitute'));
        expect(llm.prompt, contains('web-search tool before'));
        expect(
          llm.schema?['required'],
          containsAll(['matchedName', 'unit', 'gramsPerUnit', 'evidenceKind']),
        );
      },
    );

    test(
      'rejects wrong unit, missing citations, malformed or implausible data',
      () async {
        for (final response in [
          unitWeightResponse(unit: 'slice'),
          unitWeightResponse(citations: const []),
          unitWeightResponse(grams: 0),
          unitWeightResponse(grams: 5001),
          LlmGroundedStructuredResponse(
            data: const {'matchedName': 'apple'},
            citations: const [],
          ),
        ]) {
          final result = await LlmFoodWebGrounder(
            llm: _GroundingLlm(response),
          ).groundUnitWeight('Medium apple', requestedUnit: 'piece');
          expect(result, isNull);
        }
      },
    );

    test('rejects a cited different-brand published result', () async {
      final result = await LlmFoodWebGrounder(
        llm: _GroundingLlm(
          unitWeightResponse(name: 'Guerrero Flour Tortillas'),
        ),
      ).groundUnitWeight('Mission Flour Tortillas', requestedUnit: 'piece');

      expect(result, isNull);
    });

    test('fails soft on provider errors and unsupported providers', () async {
      final throwing = _GroundingLlm(unitWeightResponse())
        ..error = StateError('network failed');
      expect(
        await LlmFoodWebGrounder(
          llm: throwing,
        ).groundUnitWeight('apple', requestedUnit: 'piece'),
        isNull,
      );
      expect(
        await LlmFoodWebGrounder(
          llm: _OfflineLlm(),
        ).groundUnitWeight('apple', requestedUnit: 'piece'),
        isNull,
      );
    });
  });
}
