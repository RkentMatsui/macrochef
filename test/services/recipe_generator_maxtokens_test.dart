import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/services/recipe_generator_service.dart';

/// Records the ChatOpts it was called with so we can assert max_tokens.
class _SpyLlm implements LLMProvider {
  ChatOpts? lastOpts;
  @override
  Future<Map<String, dynamic>> structured(
      String prompt, Map<String, dynamic> schema,
      {ChatOpts? opts}) async {
    lastOpts = opts;
    return {
      'title': 'X',
      'servings': 1,
      'ingredients': [
        {'name': 'egg', 'quantity': '2', 'unit': 'piece'}
      ],
      'steps': ['Boil', 'Eat'],
      'kcal': 200,
      'protein': 12,
      'carb': 1,
      'fat': 14,
    };
  }

  @override
  Future<String> chat(List<ChatMessage> m, {ChatOpts? opts}) async => '';
  @override
  Future<Map<String, dynamic>> vision(
          Uint8List b, String p, Map<String, dynamic> s, {ChatOpts? opts}) async =>
      {};
}

void main() {
  test('recipe generation requests >=4096 max tokens so steps survive', () async {
    final spy = _SpyLlm();
    final svc = RecipeGeneratorService(spy);
    await svc.generate(
      prompt: 'high protein lunch',
      target: const MacroValues(kcal: 600, protein: 50, carb: 40, fat: 20),
      servings: 1,
    );
    expect(spy.lastOpts, isNotNull, reason: 'must pass ChatOpts');
    expect(spy.lastOpts!.maxTokens, greaterThanOrEqualTo(4096));
  });
}
