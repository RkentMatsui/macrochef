import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/services/recipe_generator_service.dart';

class _FakeLlm implements LLMProvider {
  Map<String, dynamic>? lastSchema;
  String? lastPrompt;
  @override
  Future<Map<String, dynamic>> structured(
      String prompt, Map<String, dynamic> jsonSchema, {ChatOpts? opts}) async {
    lastPrompt = prompt; lastSchema = jsonSchema;
    return {
      'title': 'High-Protein Bowl',
      'servings': 2,
      'ingredients': [
        {'name': 'chicken breast', 'quantity': '300', 'unit': 'g'},
      ],
      'steps': ['Grill chicken', 'Assemble'],
      'kcal': 450, 'protein': 50, 'carb': 20, 'fat': 12,
    };
  }
  @override
  Future<String> chat(List<ChatMessage> messages, {ChatOpts? opts}) async => '';
  @override
  Future<Map<String, dynamic>> vision(
          Uint8List imageBytes, String prompt, Map<String, dynamic> jsonSchema,
          {ChatOpts? opts}) async =>
      throw UnimplementedError();
}

void main() {
  test('generate maps structured response and embeds target in prompt', () async {
    final llm = _FakeLlm();
    final svc = RecipeGeneratorService(llm);
    final res = await svc.generate(
      prompt: 'high protein, no dairy',
      target: const MacroValues(kcal: 600, protein: 55, carb: 40, fat: 15),
      servings: 2,
    );
    expect(res.recipe.title, 'High-Protein Bowl');
    expect(res.recipe.servings, 2);
    expect(res.recipe.ingredients.first.name, 'chicken breast');
    expect(res.perServing.protein, 50);
    expect(llm.lastPrompt, contains('high protein, no dairy'));
    expect(llm.lastPrompt, contains('600'));
  });

  test('embeds pinned ingredient, blacklist, and avoid-titles in the prompt',
      () async {
    final llm = _FakeLlm();
    final svc = RecipeGeneratorService(llm);
    await svc.generate(
      prompt: 'wrap',
      target: const MacroValues(kcal: 500, protein: 40, carb: 50, fat: 15),
      servings: 1,
      pinnedIngredient: 'tortilla',
      blacklist: ['cilantro', 'olives'],
      avoidTitles: ['Chicken Bowl', 'Beef Tacos'],
    );
    expect(llm.lastPrompt, contains('tortilla'));
    expect(llm.lastPrompt, contains('cilantro'));
    expect(llm.lastPrompt, contains('olives'));
    expect(llm.lastPrompt, contains('Chicken Bowl'));
    expect(llm.lastPrompt, contains('Beef Tacos'));
  });

  test('omits optional clauses when not supplied', () async {
    final llm = _FakeLlm();
    final svc = RecipeGeneratorService(llm);
    await svc.generate(
      prompt: 'salad',
      target: const MacroValues(kcal: 300, protein: 20, carb: 30, fat: 10),
      servings: 1,
    );
    expect(llm.lastPrompt, isNot(contains('Always include')));
    expect(llm.lastPrompt, isNot(contains('Never include')));
    expect(llm.lastPrompt, isNot(contains('Do not produce')));
  });
}
