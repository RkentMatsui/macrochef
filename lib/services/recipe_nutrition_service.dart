import 'dart:convert';

import '../models/macros.dart';
import '../models/recipe_breakdown.dart';
import '../data/repositories/recipe_repository.dart';
import '../services/food_lookup.dart';
import '../services/macro_calculator.dart';
import '../services/gram_parser.dart';
import '../services/daily_log_service.dart';
import '../state/providers.dart' show todayDate;

/// Resolves every recipe ingredient through the OFF->USDA->AI pipeline
/// (FoodLookup), scales each to grams (MacroCalculator), sums to a recipe total.
/// Caches in-memory keyed by recipeId AND persists the breakdown (with each
/// ingredient's source) to `RecipeNutritionCache`, keyed by a signature of the
/// ingredient list — so opening a recipe is instant and offline, and the
/// pipeline only re-runs when the ingredients actually change.
class RecipeNutritionService {
  final FoodLookup lookup;
  final RecipeRepository repo;
  final DailyLogService logs;

  final _cache = <int, RecipeMacros>{};
  final _breakdownCache = <int, RecipeBreakdown>{};

  RecipeNutritionService({
    required this.lookup,
    required this.repo,
    required this.logs,
  });

  /// Per-ingredient breakdown: every ingredient, in recipe order, tagged with
  /// why it did/didn't contribute. Returns null only when the recipe has no
  /// ingredients at all (callers can still render a breakdown whose
  /// countedCount == 0 to explain a zero total). Cached by recipeId (cleared
  /// via [invalidate]) so nutritionFor + the UI's breakdown load resolve the
  /// ingredient pipeline only once per recipe.
  Future<RecipeBreakdown?> breakdownFor(int recipeId) async {
    final cached = _breakdownCache[recipeId];
    if (cached != null) return cached;

    final ingredients = await repo.ingredientsFor(recipeId);
    if (ingredients.isEmpty) return null;

    // Signature of the current ingredient list. As long as it's unchanged we can
    // reuse the persisted breakdown instead of re-running the OFF→USDA→AI
    // pipeline (which offline means slow on-device LLM estimates) on every open.
    final signature = ingredients
        .map((i) => '${i.name}${i.quantity ?? ''}${i.unit ?? ''}')
        .join('');
    final stored = await repo.nutritionCache(recipeId);
    if (stored != null && stored.hash == signature) {
      try {
        final bd = RecipeBreakdown.fromJson(
            jsonDecode(stored.json) as Map<String, dynamic>);
        _breakdownCache[recipeId] = bd;
        return bd;
      } catch (_) {
        // Corrupt/old cache shape — fall through and recompute.
      }
    }

    final rows = <IngredientContribution>[];
    var total = MacroValues.zero;
    var totalGrams = 0.0;
    var counted = 0;

    for (final ing in ingredients) {
      final grams = GramParser.parseGrams(ing.quantity, ing.unit);

      // Plain gram/kg path.
      if (grams != null) {
        final food = await lookup.resolve(ing.name);
        if (food == null) {
          rows.add(IngredientContribution(
            name: ing.name,
            grams: grams,
            macros: null,
            status: ContributionStatus.noMatch,
          ));
          continue;
        }
        final m = MacroCalculator.forGrams(food.perHundred, grams);
        rows.add(IngredientContribution(
          name: ing.name,
          grams: grams,
          macros: m,
          status: ContributionStatus.counted,
          source: food.source,
        ));
        total = total + m;
        totalGrams += grams;
        counted++;
        continue;
      }

      // Piece/count path: "2 tortillas", "1 egg", "1 cup". Convert the count to
      // grams using a per-piece weight (remembered on the food, else AI-guessed
      // once and stored). Tolerates a count with a trailing unit ("2 eggs").
      final qty = GramParser.leadingNumber(ing.quantity);
      final food = qty == null ? null : await lookup.resolve(ing.name);
      if (qty != null && food != null) {
        final per = food.gramsPerPiece ??
            await lookup.estimatePieceWeight(ing.name, ing.unit ?? 'piece');
        if (per != null && per > 0) {
          final g = qty * per;
          final m = MacroCalculator.forGrams(food.perHundred, g);
          rows.add(IngredientContribution(
            name: ing.name,
            grams: g,
            macros: m,
            status: ContributionStatus.counted,
            source: food.source,
            gramsPerPiece: per,
            unit: ing.unit,
          ));
          total = total + m;
          totalGrams += g;
          counted++;
          continue;
        }
      }

      // Couldn't convert — surface it as not counted (unknown unit).
      rows.add(IngredientContribution(
        name: ing.name,
        grams: null,
        macros: null,
        status: ContributionStatus.unknownUnit,
      ));
    }

    final breakdown = RecipeBreakdown(
      ingredients: rows,
      total: total,
      totalGrams: totalGrams,
      countedCount: counted,
      totalCount: ingredients.length,
    );
    _breakdownCache[recipeId] = breakdown;
    // Persist so the next open — even after a restart — is instant and offline.
    await repo.putNutritionCache(
        recipeId, signature, jsonEncode(breakdown.toJson()));
    return breakdown;
  }

  /// Returns cached macros if present, else resolves all ingredients via
  /// [breakdownFor]. Returns null if the recipe has no ingredients or none
  /// could be resolved - callers should treat null as "no nutrition data".
  Future<RecipeMacros?> nutritionFor(int recipeId) async {
    if (_cache.containsKey(recipeId)) return _cache[recipeId];

    final breakdown = await breakdownFor(recipeId);
    if (breakdown == null || breakdown.countedCount == 0) return null;

    final servings = await repo.servingsFor(recipeId);
    final s = servings < 1 ? 1 : servings;
    final total = breakdown.total;
    final perServing = MacroValues(
      kcal: total.kcal / s,
      protein: total.protein / s,
      carb: total.carb / s,
      fat: total.fat / s,
    );
    final macros = RecipeMacros(
      total: total,
      perServing: perServing,
      totalGrams: breakdown.totalGrams,
      gramsPerServing: breakdown.totalGrams / s,
    );
    _cache[recipeId] = macros;
    return macros;
  }

  Future<void> logMealServings({
    required int recipeId,
    required String recipeTitle,
    required RecipeMacros recipeMacros,
    required double servingsEaten,
    String? date,
  }) async {
    final n = servingsEaten <= 0 ? 1.0 : servingsEaten;
    final m = recipeMacros.perServing;
    await logs.log(
      date ?? todayDate(),
      name: recipeTitle,
      grams: recipeMacros.gramsPerServing * n,
      macros: MacroValues(
        kcal: m.kcal * n,
        protein: m.protein * n,
        carb: m.carb * n,
        fat: m.fat * n,
      ),
      source: MacroSource.manual,
      recipeId: recipeId,
    );
  }

  /// Back-compat: log exactly one serving.
  Future<void> logMeal({
    required int recipeId,
    required String recipeTitle,
    required RecipeMacros recipeMacros,
  }) =>
      logMealServings(
        recipeId: recipeId,
        recipeTitle: recipeTitle,
        recipeMacros: recipeMacros,
        servingsEaten: 1,
      );

  void invalidate(int recipeId) {
    _cache.remove(recipeId);
    _breakdownCache.remove(recipeId);
    // Drop the persisted row too; a later recompute re-persists it. (Even if
    // this is skipped, an ingredient change flips the signature and forces a
    // recompute — this is just prompt cleanup.)
    repo.deleteNutritionCache(recipeId);
  }
}
