import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/food_cache_repository.dart';
import 'package:macrochef/data/repositories/log_repository.dart';
import 'package:macrochef/data/repositories/recipe_repository.dart';
import 'package:macrochef/data/repositories/target_repository.dart';
import 'package:macrochef/models/daily.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/models/recipe_breakdown.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/services/daily_log_service.dart';
import 'package:macrochef/services/food_db/open_food_facts_client.dart';
import 'package:macrochef/services/food_db/usda_client.dart';
import 'package:macrochef/services/food_lookup.dart';
import 'package:macrochef/services/recipe_nutrition_service.dart';
import 'package:macrochef/services/portion_calculator.dart';

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

class FakeFoodLookup extends FoodLookup {
  final Map<String, FoodMacros?> responses;
  final Map<String, double?> pieceWeights;
  FakeFoodLookup(this.responses, {this.pieceWeights = const {}})
    : super(
        cache: _NullCache(),
        off: _NullOFF(),
        usda: _NullUSDA(),
        llm: _NullLLM(),
      );
  @override
  Future<FoodMacros?> resolve(String foodName) async => responses[foodName];
  @override
  Future<double?> estimatePieceWeight(String foodName, String unit) async =>
      pieceWeights[foodName];
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

class _FakeLogs extends DailyLogService {
  _FakeLogs() : super(logs: _NoopLogRepo(), targets: _NoopTargetRepo());
}

RecipeIngredient _ing(String name, String? qty, String? unit) =>
    RecipeIngredient(id: 0, recipeId: 1, name: name, quantity: qty, unit: unit);

void main() {
  const chicken = FoodMacros(
    name: 'chicken',
    perHundred: PerHundred(kcal: 165, protein: 31, carb: 0, fat: 3.6),
    source: MacroSource.off,
    isEstimate: false,
  );

  RecipeNutritionService make(
    Map<String, FoodMacros?> lk,
    Map<int, List<RecipeIngredient>> ings, {
    Map<int, int>? servings,
    Map<String, double?> pieceWeights = const {},
  }) => RecipeNutritionService(
    lookup: FakeFoodLookup(lk, pieceWeights: pieceWeights),
    repo: FakeRecipeRepository(ings, servings: servings),
    logs: _FakeLogs(),
  );

  test(
    'breakdown marks counted, unknownUnit, noMatch and totals counted only',
    () async {
      final svc = make(
        {'chicken': chicken, 'mystery': null},
        {
          1: [
            _ing('chicken', '1500', 'g'),
            _ing('oil', '2', 'tbsp'),
            _ing('mystery', '50', 'g'),
          ],
        },
      );
      final b = await svc.breakdownFor(1);
      expect(b, isNotNull);
      expect(b!.totalCount, 3);
      expect(b.countedCount, 1);
      expect(b.ingredients[0].status, ContributionStatus.counted);
      expect(b.ingredients[0].grams, closeTo(1500, 0.001));
      expect(b.ingredients[0].macros!.kcal, closeTo(2475, 1.0));
      expect(b.ingredients[1].status, ContributionStatus.noMatch);
      expect(b.ingredients[1].grams, isNull);
      expect(b.ingredients[1].macros, isNull);
      expect(b.ingredients[2].status, ContributionStatus.noMatch);
      expect(b.ingredients[2].grams, isNull);
      expect(b.ingredients[2].macros, isNull);
      expect(b.total.kcal, closeTo(2475, 1.0));
      expect(b.totalGrams, closeTo(1500, 0.001));
    },
  );

  test(
    'breakdown returns non-null with countedCount 0 when nothing resolves',
    () async {
      final svc = make({}, {
        1: [_ing('oil', '2', 'tbsp')],
      });
      final b = await svc.breakdownFor(1);
      expect(b, isNotNull);
      expect(b!.countedCount, 0);
      expect(b.total.kcal, 0);
    },
  );

  test(
    'breakdown returns null only when the recipe has no ingredients',
    () async {
      final svc = make({}, {1: []});
      expect(await svc.breakdownFor(1), isNull);
    },
  );

  test('nutritionFor still returns null when nothing resolves', () async {
    final svc = make({}, {
      1: [_ing('oil', '2', 'tbsp')],
    });
    expect(await svc.nutritionFor(1), isNull);
  });

  test('nutritionFor total matches breakdown total', () async {
    final svc = make(
      {'chicken': chicken},
      {
        1: [_ing('chicken', '200', 'g')],
      },
    );
    final n = await svc.nutritionFor(1);
    final b = await svc.breakdownFor(1);
    expect(n!.total.kcal, closeTo(b!.total.kcal, 0.001));
    expect(n.totalGrams, closeTo(b.totalGrams, 0.001));
  });

  const tortilla = FoodMacros(
    name: 'tortilla',
    perHundred: PerHundred(kcal: 300, protein: 8, carb: 50, fat: 7),
    source: MacroSource.usda,
    isEstimate: false,
    gramsPerPiece: 50,
  );

  test('piece ingredient counted via known gramsPerPiece', () async {
    final svc = make(
      {'tortilla': tortilla},
      {
        1: [_ing('tortilla', '2', 'piece')],
      },
    );
    final b = await svc.breakdownFor(1);
    expect(b!.countedCount, 1);
    final c = b.ingredients[0];
    expect(c.status, ContributionStatus.counted);
    expect(c.quantity, 2);
    expect(c.grams, closeTo(100, 0.001)); // 2 × 50 g
    expect(c.gramsPerPiece, closeTo(50, 0.001));
    expect(c.unit, 'piece');
    expect(c.macros!.kcal, closeTo(300, 0.5)); // 100 g × 300/100
  });

  test(
    'piece ingredient without a stored weight is unresolved without AI estimation',
    () async {
      const noPieceTortilla = FoodMacros(
        name: 'tortilla',
        perHundred: PerHundred(kcal: 300, protein: 8, carb: 50, fat: 7),
        source: MacroSource.usda,
        isEstimate: false,
      );
      final svc = make(
        {'tortilla': noPieceTortilla},
        {
          1: [_ing('tortilla', '3', 'piece')],
        },
      );
      final b = await svc.breakdownFor(1);
      final c = b!.ingredients[0];
      expect(c.status, ContributionStatus.unknownUnit);
      expect(c.grams, isNull);
      expect(c.unresolvedReason, PortionUnresolvedReason.missingPhysicalWeight);
    },
  );

  test(
    'piece ingredient stays unknownUnit when weight cannot be estimated',
    () async {
      const noPieceTortilla = FoodMacros(
        name: 'tortilla',
        perHundred: PerHundred(kcal: 300, protein: 8, carb: 50, fat: 7),
        source: MacroSource.usda,
        isEstimate: false,
      );
      final svc = make(
        {'tortilla': noPieceTortilla},
        {
          1: [_ing('tortilla', '2', 'piece')],
        },
        // no pieceWeights → estimate returns null
      );
      final b = await svc.breakdownFor(1);
      expect(b!.countedCount, 0);
      expect(b.ingredients[0].status, ContributionStatus.unknownUnit);
    },
  );

  test('basis portions preserve requested volume and exact macros', () async {
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
        1: [_ing('shake', '250', 'ml')],
      },
    );
    final b = await svc.breakdownFor(1);
    final c = b!.ingredients.single;
    expect(c.status, ContributionStatus.counted);
    expect(c.quantity, 250);
    expect(c.unit, 'ml');
    expect(c.grams, isNull);
    expect(c.macros!.kcal, 180);
    expect(b.allPhysicalGramsKnown, isFalse);
  });

  test('basis portions convert cups and scale volume macros exactly', () async {
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
        1: [_ing('shake', '1', 'cup')],
      },
    );
    final c = (await svc.breakdownFor(1))!.ingredients.single;
    expect(c.quantity, 1);
    expect(c.unit, 'cup');
    expect(c.macros!.kcal, closeTo(172.8, 0.001));
  });

  test(
    'incompatible count units retain a structured unresolved reason',
    () async {
      const sliced = FoodMacros(
        name: 'sliced',
        perHundred: PerHundred.zero,
        source: MacroSource.manual,
        isEstimate: false,
        basis: NutritionBasis(
          quantity: 1,
          unit: 'piece',
          macros: MacroValues(kcal: 50, protein: 2, carb: 4, fat: 3),
        ),
      );
      final svc = make(
        {'sliced': sliced},
        {
          1: [_ing('sliced', '1', 'slice')],
        },
      );
      final c = (await svc.breakdownFor(1))!.ingredients.single;
      expect(c.status, ContributionStatus.unknownUnit);
      expect(c.unresolvedReason, PortionUnresolvedReason.incompatibleUnit);
      expect(c.quantity, 1);
      expect(c.unit, 'slice');
    },
  );

  test('breakdown JSON retains requested portions and reads old caches', () {
    const contribution = IngredientContribution(
      name: 'shake',
      quantity: 250,
      unit: 'ml',
      grams: null,
      macros: MacroValues(kcal: 180, protein: 20, carb: 8, fat: 6),
      status: ContributionStatus.counted,
    );
    const breakdown = RecipeBreakdown(
      ingredients: [contribution],
      total: MacroValues(kcal: 180, protein: 20, carb: 8, fat: 6),
      totalGrams: 0,
      countedCount: 1,
      totalCount: 1,
      allPhysicalGramsKnown: false,
    );
    final json = breakdown.toJson();
    expect(json['allPhysicalGramsKnown'], isFalse);
    expect((json['ingredients'] as List).single['quantity'], 250);
    final oldJson = Map<String, dynamic>.from(json)
      ..remove('allPhysicalGramsKnown');
    expect(RecipeBreakdown.fromJson(oldJson).allPhysicalGramsKnown, isTrue);
  });
}
