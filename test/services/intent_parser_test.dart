import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/cooking_intent.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/services/intent_parser.dart';

class FakeLLMProvider implements LLMProvider {
  @override
  Future<String> chat(List<ChatMessage> messages, {ChatOpts? opts}) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> structured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) async =>
      {'intent': 'unknown'};

  @override
  Future<Map<String, dynamic>> vision(
    Uint8List imageBytes,
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) async =>
      {'intent': 'unknown'};
}

void main() {
  late IntentParser parser;

  setUp(() {
    parser = IntentParser(llm: FakeLLMProvider());
  });

  group('parseRule - regex layer', () {
    test('"what is next" → nextStep', () {
      final result = parser.parseRule('what is next');
      expect(result, isNotNull);
      expect(result!.type, IntentType.nextStep);
    });

    test('"next" → nextStep', () {
      final result = parser.parseRule('next');
      expect(result, isNotNull);
      expect(result!.type, IntentType.nextStep);
    });

    test('"repeat that" → repeatStep', () {
      final result = parser.parseRule('repeat that');
      // "repeat that" contains "repeat" which should match
      expect(result, isNotNull);
      expect(result!.type, IntentType.repeatStep);
    });

    test('"exit cooking mode" → exit', () {
      final result = parser.parseRule('exit cooking mode');
      expect(result, isNotNull);
      expect(result!.type, IntentType.exit);
    });

    test('"I used 200 grams of chicken breast" → adjustIngredient', () {
      // "I used X" now adjusts a recipe ingredient's actual amount rather than
      // logging a separate food (see adjustIngredient intent).
      final result = parser.parseRule('I used 200 grams of chicken breast');
      expect(result, isNotNull);
      expect(result!.type, IntentType.adjustIngredient);
      expect(result.grams, closeTo(200, 0.01));
      expect(result.food, 'chicken breast');
    });

    test('ambiguous utterance returns null', () {
      final result = parser.parseRule('hmm I am not sure what to do');
      expect(result, isNull);
    });

    test('"previous" → prevStep', () {
      final result = parser.parseRule('previous');
      expect(result, isNotNull);
      expect(result!.type, IntentType.prevStep);
    });

    test('"daily total" → dailyTotal', () {
      final result = parser.parseRule('daily total');
      expect(result, isNotNull);
      expect(result!.type, IntentType.dailyTotal);
    });

    test('"current macros" → currentMacros', () {
      final result = parser.parseRule('current macros');
      expect(result, isNotNull);
      expect(result!.type, IntentType.currentMacros);
    });

    test('"50g of rice" → logIngredient with decimal grams', () {
      final result = parser.parseRule('50g of rice');
      expect(result, isNotNull);
      expect(result!.type, IntentType.logIngredient);
      expect(result.grams, closeTo(50, 0.01));
      expect(result.food, 'rice');
    });
  });

  group('parse - async with LLM fallback', () {
    test('rule match does not call LLM', () async {
      final result = await parser.parse('what is next');
      expect(result.type, IntentType.nextStep);
    });

    test('no rule match falls back to LLM returning unknown', () async {
      final result = await parser.parse('blah blah blah something else');
      expect(result.type, IntentType.unknown);
    });
  });
}
