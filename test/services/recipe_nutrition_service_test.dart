import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/food_cache_repository.dart';
import 'package:macrochef/data/repositories/log_repository.dart';
import 'package:macrochef/data/repositories/recipe_repository.dart';
import 'package:macrochef/data/repositories/target_repository.dart';
import 'package:macrochef/models/daily.dart';
import 'package:macrochef/models/food_unit_weight.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/services/daily_log_service.dart';
import 'package:macrochef/services/food_db/open_food_facts_client.dart';
import 'package:macrochef/services/food_db/usda_client.dart';
import 'package:macrochef/services/food_lookup.dart';
import 'package:macrochef/services/recipe_nutrition_service.dart';

// --- Fakes ---------------------------------------------------------------

class _NullCache implements FoodCacheRepository {
  @override
  Future<FoodMacros?> find(String name) async => null;
  @override
  Future<void> put(FoodMacros m) async {}
  @override
  Future<void> upsertOverride(FoodMacros m) async {}
  @override
  Future<List<FoodMacros>> listOverrides() async => [];
  @override
  Future<void> deleteByName(String name) async {}
  @override
  Future<int> clearNonOverrides() async => 0;
  @override
  Future<void> setGramsPerPiece(String name, double grams) async {}
  @override
  Future<List<FoodMacros>> search(String query, {int limit = 8}) async => [];
  @override
  AppDatabase get db => throw UnimplementedError();
}

class _NullOFF extends OpenFoodFactsClient {
  _NullOFF() : super();
  @override
  Future<PerHundred?> search(String q) async => null;

  @override
  Future<FoodMacros?> searchFood(String q) async => null;
}

class _NullUSDA extends UsdaClient {
  _NullUSDA() : super(apiKey: 'fake');
  @override
  Future<PerHundred?> search(String q) async => null;
}

class _NullLLM implements LLMProvider {
  @override
  Future<String> chat(List<ChatMessage> messages, {ChatOpts? opts}) =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> structured(
    String prompt,
    Map<String, dynamic> schema, {
    ChatOpts? opts,
  }) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> vision(
    Uint8List imageBytes,
    String prompt,
    Map<String, dynamic> schema, {
    ChatOpts? opts,
  }) => throw UnimplementedError();
}

/// Extends FoodLookup and overrides resolve() to return from a fixed map.
/// Does NOT route through the real pipeline — the real AI fallback always
/// returns non-null, which would break the unresolved-case test.
class FakeFoodLookup extends FoodLookup {
  final Map<String, FoodMacros?> responses;
  int resolveCalls = 0;
  FakeFoodLookup(this.responses)
    : super(
        cache: _NullCache(),
        off: _NullOFF(),
        usda: _NullUSDA(),
        llm: _NullLLM(),
      );
  @override
  Future<FoodMacros?> resolve(String foodName) async {
    resolveCalls++;
    return responses[foodName];
  }
}

class FakeRecipeRepository implements RecipeRepository {
  final Map<int, List<RecipeIngredient>> ingredients;
  final Map<int, int> servings;
  FakeRecipeRepository(this.ingredients, {Map<int, int>? servings})
    : servings = servings ?? {};

  @override
  Future<List<RecipeIngredient>> ingredientsFor(int recipeId) async =>
      ingredients[recipeId] ?? [];

  @override
  Future<int> servingsFor(int id) async => servings[id] ?? 1;

  @override
  Future<void> updateServings(int id, int s) async => servings[id] = s;

  final _nutCache = <int, ({String hash, String json})>{};
  @override
  Future<({String hash, String json})?> nutritionCache(int recipeId) async =>
      _nutCache[recipeId];
  @override
  Future<void> putNutritionCache(
    int recipeId,
    String ingredientsHash,
    String breakdownJson,
  ) async => _nutCache[recipeId] = (hash: ingredientsHash, json: breakdownJson);
  @override
  Future<void> deleteNutritionCache(int recipeId) async =>
      _nutCache.remove(recipeId);

  @override
  Future<void> delete(int id) async {}

  @override
  AppDatabase get db => throw UnimplementedError();
  @override
  Future<int> save(r) => throw UnimplementedError();
  @override
  Future<List<Recipe>> all() => throw UnimplementedError();
  @override
  Future<List<String>> allTitles() => throw UnimplementedError();
  @override
  Future<List<String>> stepsFor(int recipeId) => throw UnimplementedError();
  @override
  Future<void> updateFull(int id, r) => throw UnimplementedError();
  @override
  Future<bool> setIngredientQuantityByName(
    int recipeId,
    String foodQuery,
    double grams,
    String unit,
  ) => throw UnimplementedError();
}

class _NoopLogRepo implements LogRepository {
  @override
  AppDatabase get db => throw UnimplementedError();
  @override
  Future<void> add(LogEntriesCompanion entry) async {}
  @override
  Future<List<LogEntry>> forDate(String date) async => [];
  @override
  Future<List<LogEntry>> forDateRange(String start, String end) async => [];
  @override
  Future<LogEntry?> findById(int id) async => null;
  @override
  Future<void> update(int id, LogEntriesCompanion entry) async {}
  @override
  Future<void> delete(int id) async {}
}

class _NoopTargetRepo implements TargetRepository {
  @override
  AppDatabase get db => throw UnimplementedError();
  @override
  Future<DailyTarget?> get(String date) async => null;
  @override
  Future<void> setDefault(DailyTarget t) async {}
  @override
  Future<void> setManualForDate(String date, DailyTarget target) async {}
  @override
  Future<void> insertAdaptive(AdaptiveTargetRecord record) async {}
  @override
  Future<AdaptiveTargetRecord?> latestAdaptiveOnOrBefore(String date) async =>
      null;
  @override
  Future<AdaptiveTargetRecord?> latestAdaptive() async => null;
}

class FakeDailyLogService extends DailyLogService {
  String? lastDate, lastName;
  double? lastGrams;
  MacroValues? lastMacros;
  MacroSource? lastSource;
  int? lastRecipeId;
  double? lastPortionQuantity;
  String? lastPortionUnit;
  int callCount = 0;

  FakeDailyLogService()
    : super(logs: _NoopLogRepo(), targets: _NoopTargetRepo());

  @override
  Future<void> log(
    String date, {
    required String name,
    required double grams,
    required MacroValues macros,
    required MacroSource source,
    int? recipeId,
    double? portionQuantity,
    String? portionUnit,
    FoodUnitWeight? unitWeightEvidence,
  }) async {
    callCount++;
    lastDate = date;
    lastName = name;
    lastGrams = grams;
    lastMacros = macros;
    lastSource = source;
    lastRecipeId = recipeId;
    lastPortionQuantity = portionQuantity;
    lastPortionUnit = portionUnit;
  }
}

RecipeIngredient _ing(String name, String? qty, String? unit) =>
    RecipeIngredient(id: 0, recipeId: 1, name: name, quantity: qty, unit: unit);

// --- Tests ---------------------------------------------------------------

void main() {
  const chicken = FoodMacros(
    name: 'chicken',
    perHundred: PerHundred(kcal: 165, protein: 31, carb: 0, fat: 3.6),
    source: MacroSource.off,
    isEstimate: false,
  );
  const rice = FoodMacros(
    name: 'rice',
    perHundred: PerHundred(kcal: 130, protein: 2.7, carb: 28, fat: 0.3),
    source: MacroSource.usda,
    isEstimate: false,
  );

  RecipeNutritionService make(
    Map<String, FoodMacros?> lk,
    Map<int, List<RecipeIngredient>> ings, [
    FakeDailyLogService? logs,
    Map<int, int>? servings,
  ]) => RecipeNutritionService(
    lookup: FakeFoodLookup(lk),
    repo: FakeRecipeRepository(ings, servings: servings),
    logs: logs ?? FakeDailyLogService(),
  );

  test(
    'persists breakdown, reuses it on a fresh service, recomputes on change',
    () async {
      final lookup = FakeFoodLookup({'chicken': chicken});
      final repo = FakeRecipeRepository({
        1: [_ing('chicken', '100', 'g')],
      });
      RecipeNutritionService svc() => RecipeNutritionService(
        lookup: lookup,
        repo: repo,
        logs: FakeDailyLogService(),
      );

      final b1 = await svc().breakdownFor(1);
      expect(b1!.countedCount, 1);
      expect(b1.ingredients.first.source, MacroSource.off); // captured...
      final callsAfterFirst = lookup.resolveCalls;
      expect(callsAfterFirst, greaterThan(0));

      // A fresh service has an empty in-memory cache, so it must load the
      // PERSISTED breakdown (with its source) rather than re-resolve the pipeline.
      final b2 = await svc().breakdownFor(1);
      expect(b2!.total.kcal, b1.total.kcal);
      expect(b2.ingredients.first.source, MacroSource.off); // ...and survived
      expect(lookup.resolveCalls, callsAfterFirst); // no new lookups

      // Editing the ingredient list flips the signature → recompute.
      repo.ingredients[1] = [_ing('chicken', '200', 'g')];
      await svc().breakdownFor(1);
      expect(lookup.resolveCalls, greaterThan(callsAfterFirst));
    },
  );

  test('null when no ingredients resolve (non-gram unit skipped)', () async {
    final svc = make(
      {'chicken': chicken},
      {
        1: [_ing('chicken', '1', 'cup')],
      },
    );
    expect(await svc.nutritionFor(1), isNull);
  });

  test('null when lookup returns null for all', () async {
    final svc = make(
      {'mystery': null},
      {
        1: [_ing('mystery', '100', 'g')],
      },
    );
    expect(await svc.nutritionFor(1), isNull);
  });

  test('sums two gram-resolved ingredients', () async {
    final svc = make(
      {'chicken': chicken, 'rice': rice},
      {
        1: [_ing('chicken', '200', 'g'), _ing('rice', '150', 'g')],
      },
    );
    final r = await svc.nutritionFor(1);
    expect(r, isNotNull);
    expect(r!.total.kcal, closeTo(525, 1.0)); // 330 + 195
    expect(r.total.protein, closeTo(66.05, 0.1));
    expect(r.totalGrams, closeTo(350, 0.001));
    expect(r.perServing.kcal, closeTo(525, 1.0));
  });

  test(
    'basis volume portions scale recipe macros without claiming grams',
    () async {
      const shake = FoodMacros(
        name: 'shake',
        perHundred: PerHundred.zero,
        source: MacroSource.manual,
        isEstimate: false,
        basis: NutritionBasis(
          quantity: 250,
          unit: 'ml',
          macros: MacroValues(kcal: 180, protein: 20, carb: 8, fat: 6),
        ),
      );
      final svc = make(
        {'shake': shake},
        {
          1: [_ing('shake', '500', 'ml')],
        },
      );
      final r = await svc.nutritionFor(1);
      expect(r!.total.kcal, 360);
      expect(r.totalGrams, isNull);
      expect(r.gramsPerServing, isNull);
    },
  );

  test('fused number+unit quantity ("200g") still resolves', () async {
    // The parser sometimes leaves the unit fused into the quantity field with
    // an empty unit. GramParser recovers the number so the ingredient counts.
    final svc = make(
      {'chicken': chicken},
      {
        1: [_ing('chicken', '200g', '')],
      },
    );
    final r = await svc.nutritionFor(1);
    expect(r, isNotNull);
    expect(r!.totalGrams, closeTo(200, 0.001));
    expect(r.total.kcal, closeTo(330, 0.5));
  });

  test('kg converted to grams', () async {
    final svc = make(
      {'chicken': chicken},
      {
        1: [_ing('chicken', '0.2', 'kg')],
      },
    );
    final r = await svc.nutritionFor(1);
    expect(r!.totalGrams, closeTo(200, 0.001));
    expect(r.total.kcal, closeTo(330, 0.5));
  });

  test('skips ingredient with non-gram unit, keeps rest', () async {
    final svc = make(
      {'chicken': chicken},
      {
        1: [_ing('oil', '2', 'tbsp'), _ing('chicken', '100', 'g')],
      },
    );
    final r = await svc.nutritionFor(1);
    expect(r!.totalGrams, closeTo(100, 0.001));
    expect(r.total.kcal, closeTo(165, 0.5));
  });

  test('skips ingredient with null quantity', () async {
    final svc = make(
      {'chicken': chicken, 'rice': rice},
      {
        1: [_ing('chicken', null, 'g'), _ing('rice', '100', 'g')],
      },
    );
    final r = await svc.nutritionFor(1);
    expect(r!.totalGrams, closeTo(100, 0.001));
  });

  test('caches result (identical on repeat)', () async {
    final svc = make(
      {'chicken': chicken},
      {
        1: [_ing('chicken', '100', 'g')],
      },
    );
    final r1 = await svc.nutritionFor(1);
    final r2 = await svc.nutritionFor(1);
    expect(identical(r1, r2), isTrue);
  });

  test('logMeal sends manual source + recipeId + totalGrams', () async {
    final logs = FakeDailyLogService();
    final svc = make(
      {'chicken': chicken},
      {
        1: [_ing('chicken', '200', 'g')],
      },
      logs,
    );
    final m = (await svc.nutritionFor(1))!;
    await svc.logMeal(
      recipeId: 1,
      recipeTitle: 'Grilled Chicken',
      recipeMacros: m,
    );
    expect(logs.callCount, 1);
    expect(logs.lastSource, MacroSource.manual);
    expect(logs.lastRecipeId, 1);
    expect(logs.lastName, 'Grilled Chicken');
    expect(logs.lastGrams, closeTo(200, 0.001));
  });

  test('perServing divides total by servings', () async {
    final svc = make(
      {'chicken': chicken},
      {
        1: [_ing('chicken', '200', 'g')],
      },
      null,
      {1: 2},
    );
    final m = (await svc.nutritionFor(1))!;
    expect(m.perServing.kcal, closeTo(m.total.kcal / 2, 0.01));
    expect(m.perServing.protein, closeTo(m.total.protein / 2, 0.01));
  });

  test('logMealServings scales perServing by servings eaten', () async {
    final logs = FakeDailyLogService();
    final svc = make(
      {'chicken': chicken},
      {
        1: [_ing('chicken', '200', 'g')],
      },
      logs,
      {1: 2},
    );
    final m = (await svc.nutritionFor(1))!;
    await svc.logMealServings(
      recipeId: 1,
      recipeTitle: 'Chicken Bowl',
      recipeMacros: m,
      servingsEaten: 2,
    );
    expect(logs.callCount, 1);
    expect(logs.lastMacros!.kcal, closeTo(m.perServing.kcal * 2, 0.01));
    expect(logs.lastMacros!.protein, closeTo(m.perServing.protein * 2, 0.01));
    expect(logs.lastPortionQuantity, 2);
    expect(logs.lastPortionUnit, 'serving');
  });

  test(
    'logMealServings uses gramsPerServing (not kcal ratio) — zero-kcal regression',
    () async {
      // A recipe whose ingredients are all zero-calorie (e.g. plain water / salt).
      // totalGrams = 400, servings = 2, so gramsPerServing = 200.
      // Eating 2 servings must log 400 g, NOT 800 g (which the old kcal-ratio
      // reconstruction would produce when perServing.kcal == 0 → servings = 1).
      final logs = FakeDailyLogService();
      const zeroKcalMacros = RecipeMacros(
        total: MacroValues(kcal: 0, protein: 0, carb: 0, fat: 0),
        perServing: MacroValues(kcal: 0, protein: 0, carb: 0, fat: 0),
        totalGrams: 400,
        gramsPerServing: 200,
      );
      final svc = make({'chicken': chicken}, {}, logs);
      await svc.logMealServings(
        recipeId: 99,
        recipeTitle: 'Zero Cal Recipe',
        recipeMacros: zeroKcalMacros,
        servingsEaten: 2,
      );
      expect(logs.callCount, 1);
      // Must be 200 * 2 = 400, not 800 (the old bug: totalGrams * servingsEaten)
      expect(logs.lastGrams, closeTo(400, 0.001));
    },
  );

  test(
    'logMealServings uses zero grams for recipes with unknown physical weight',
    () async {
      final logs = FakeDailyLogService();
      const noWeightMacros = RecipeMacros(
        total: MacroValues(kcal: 180, protein: 20, carb: 8, fat: 6),
        perServing: MacroValues(kcal: 180, protein: 20, carb: 8, fat: 6),
        totalGrams: null,
        gramsPerServing: null,
      );
      final svc = make({'chicken': chicken}, {}, logs);
      await svc.logMealServings(
        recipeId: 99,
        recipeTitle: 'Shake',
        recipeMacros: noWeightMacros,
        servingsEaten: 2,
      );
      expect(logs.lastGrams, 0);
      expect(logs.lastPortionQuantity, 2);
      expect(logs.lastPortionUnit, 'serving');
    },
  );
}
