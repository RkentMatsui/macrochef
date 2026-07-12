import '../models/chat.dart';
import '../models/recipe.dart';
import '../providers/llm/llm_provider.dart';
import '../data/repositories/recipe_repository.dart';
import 'gram_parser.dart';

class RecipeService {
  const RecipeService();

  Future<ParsedRecipe> parse(String rawText, LLMProvider llm) async {
    final schema = {
      'type': 'object',
      'properties': {
        'title': {'type': 'string'},
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
        'steps': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
      'required': ['title', 'ingredients', 'steps'],
    };

    final prompt =
        'Parse the following recipe text and extract the title, the '
        'ingredients, and the steps as a numbered list. For each ingredient '
        'return the name, a numeric quantity (digits only, e.g. "5" or "0.5" — '
        'never include the unit in this field), and the unit separately (e.g. '
        '"g", "kg", "cup", "tbsp", "piece"). If an amount has no unit, leave '
        'the unit empty.\n\n'
        'Recipe text:\n$rawText';

    final result = await llm.structured(prompt, schema,
        opts: const ChatOpts(maxTokens: 4096));

    final title = result['title'] as String? ?? 'Untitled Recipe';

    final rawIngredients = result['ingredients'] as List<dynamic>? ?? [];
    final ingredients =
        rawIngredients.map((i) => _normalizeIngredient(i as Map<String, dynamic>)).toList();

    final rawSteps = result['steps'] as List<dynamic>? ?? [];
    final steps = rawSteps.map((s) => s as String).toList();

    return ParsedRecipe(title: title, ingredients: ingredients, steps: steps);
  }

  /// Build an [Ingredient] from a raw parsed map, splitting a unit the model
  /// fused into the quantity ("5g" → quantity "5", unit "g") so the gram/piece
  /// resolvers can compute macros. Non-numeric quantities ("to taste") pass
  /// through untouched.
  static Ingredient _normalizeIngredient(Map<String, dynamic> ing) {
    final name = ing['name'] as String? ?? '';
    final rawQty = (ing['quantity'] as String?)?.trim();
    var unit = (ing['unit'] as String?)?.trim();

    final n = GramParser.leadingNumber(rawQty);
    if (n == null) {
      return Ingredient(name, quantity: rawQty, unit: unit);
    }
    final suffix = GramParser.trailingUnit(rawQty);
    if (suffix.isNotEmpty && (unit == null || unit.isEmpty)) unit = suffix;
    return Ingredient(name, quantity: _fmtNum(n), unit: unit);
  }

  /// Formats a parsed number without a trailing ".0" (5.0 → "5", 0.5 → "0.5").
  static String _fmtNum(double n) =>
      n == n.roundToDouble() ? n.toStringAsFixed(0) : n.toString();

  Future<int> save(ParsedRecipe r, RecipeRepository repo) async {
    return repo.save(r);
  }
}
