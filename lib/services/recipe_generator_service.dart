import '../models/chat.dart';
import '../models/macros.dart';
import '../models/recipe.dart';
import '../providers/llm/llm_provider.dart';

class GeneratedRecipe {
  final ParsedRecipe recipe;
  final MacroValues perServing;
  const GeneratedRecipe({required this.recipe, required this.perServing});
}

class RecipeGeneratorService {
  final LLMProvider llm;
  RecipeGeneratorService(this.llm);

  Future<GeneratedRecipe> generate({
    required String prompt,
    required MacroValues target,
    required int servings,
    List<String> avoidTitles = const [],
    List<String> blacklist = const [],
    String? pinnedIngredient,
  }) async {
    final schema = {
      'type': 'object',
      'properties': {
        'title': {'type': 'string'},
        'servings': {'type': 'integer'},
        'ingredients': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
              'quantity': {'type': 'string'},
              'unit': {'type': 'string'},
            },
            'required': ['name'],
          },
        },
        'steps': {'type': 'array', 'items': {'type': 'string'}},
        'kcal': {'type': 'number'},
        'protein': {'type': 'number'},
        'carb': {'type': 'number'},
        'fat': {'type': 'number'},
      },
      'required': ['title', 'servings', 'ingredients', 'steps',
          'kcal', 'protein', 'carb', 'fat'],
    };
    final buf = StringBuffer()
      ..write('Create a recipe for $servings serving(s) that fits these '
          'per-serving macro targets: ${target.kcal.toStringAsFixed(0)} kcal, '
          '${target.protein.toStringAsFixed(0)} g protein, '
          '${target.carb.toStringAsFixed(0)} g carbs, '
          '${target.fat.toStringAsFixed(0)} g fat. ')
      ..write('User request: "$prompt". ');

    final pin = pinnedIngredient?.trim() ?? '';
    if (pin.isNotEmpty) {
      buf.write('Always include this ingredient: $pin. ');
    }
    if (blacklist.isNotEmpty) {
      buf.write('Never include these ingredients or obvious forms of them: '
          '${blacklist.join(', ')}. ');
    }
    if (avoidTitles.isNotEmpty) {
      buf.write('Do not produce any of these existing recipes; make something '
          'meaningfully different: ${avoidTitles.join('; ')}. ');
    }
    buf.write('Return JSON with title, servings, ingredients (name, quantity, '
        'unit), steps, and the per-serving kcal, protein, carb, fat.');

    final r = await llm.structured(buf.toString(), schema,
        opts: const ChatOpts(maxTokens: 4096));

    final ingredients = ((r['ingredients'] as List?) ?? [])
        .map((e) => Ingredient(
              (e['name'] ?? '').toString(),
              quantity: e['quantity']?.toString(),
              unit: e['unit']?.toString(),
            ))
        .toList();
    final steps =
        ((r['steps'] as List?) ?? []).map((e) => e.toString()).toList();
    final recipe = ParsedRecipe(
      title: (r['title'] ?? 'Generated recipe').toString(),
      ingredients: ingredients,
      steps: steps,
      servings: _toInt(r['servings'], servings),
    );
    final perServing = MacroValues(
      kcal: _toD(r['kcal']), protein: _toD(r['protein']),
      carb: _toD(r['carb']), fat: _toD(r['fat']),
    );
    return GeneratedRecipe(recipe: recipe, perServing: perServing);
  }

  double _toD(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
  int _toInt(dynamic v, int fallback) =>
      v is num ? v.toInt() : int.tryParse('$v') ?? fallback;
}
