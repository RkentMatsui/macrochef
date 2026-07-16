import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/food_cache_repository.dart';
import 'package:macrochef/data/repositories/recipe_repository.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/models/recipe.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/services/food_db/open_food_facts_client.dart';
import 'package:macrochef/services/food_db/usda_client.dart';
import 'package:macrochef/services/food_lookup.dart';
import 'package:macrochef/state/providers.dart';
import 'package:macrochef/ui/recipes/recipes_screen.dart';

void main() {
  Future<({AppDatabase db, RecipeRepository repo, ProviderContainer container})>
  setup(
    WidgetTester tester, {
    AppDatabase? database,
    RecipeRepository? repository,
  }) async {
    final db = database ?? AppDatabase(NativeDatabase.memory());
    final repo = repository ?? RecipeRepository(db);
    final recipeId = await repo.save(
      const ParsedRecipe(
        title: 'Delete me',
        ingredients: [Ingredient('beans', quantity: '400', unit: 'g')],
        steps: ['Cook'],
      ),
    );
    expect(recipeId, greaterThan(0));
    await FoodCacheRepository(db).put(
      const FoodMacros(
        name: 'beans',
        perHundred: PerHundred(kcal: 100, protein: 7, carb: 18, fat: 1),
        source: MacroSource.manual,
        isEstimate: false,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recipeRepositoryProvider.overrideWithValue(repo),
        foodLookupProvider.overrideWith((ref) async => _foodLookup(db)),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RecipesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete me'));
    await tester.pumpAndSettle();
    return (db: db, repo: repo, container: container);
  }

  testWidgets('recipe deletion asks for confirmation and cancel retains detail', (
    tester,
  ) async {
    await setup(tester);

    await tester.tap(find.byTooltip('Delete recipe'));
    await tester.pumpAndSettle();

    expect(find.text('Delete recipe?'), findsOneWidget);
    expect(
      find.text(
        '"Delete me" will be removed permanently. Logged meals will stay in your history.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Delete me'), findsWidgets);
  });

  testWidgets(
    'confirmed deletion returns to a refreshed list and confirms success',
    (tester) async {
      await setup(tester);

      await tester.tap(find.byTooltip('Delete recipe'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Your recipe book is empty'), findsOneWidget);
      expect(find.text('Deleted "Delete me"'), findsOneWidget);
    },
  );

  testWidgets('failed deletion keeps detail visible and allows retry', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    await setup(tester, database: db, repository: _FailingRecipeRepository(db));

    await tester.tap(find.byTooltip('Delete recipe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete me'), findsWidgets);
    expect(find.text("Couldn't delete recipe. Try again."), findsOneWidget);
    expect(find.byTooltip('Delete recipe'), findsOneWidget);
  });

  testWidgets('renders a counted volume portion without physical grams', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = RecipeRepository(db);
    await repo.save(
      const ParsedRecipe(
        title: 'Cup soup',
        ingredients: [Ingredient('soup', quantity: '1', unit: 'cup')],
        steps: ['Heat'],
      ),
    );
    await FoodCacheRepository(db).put(
      const FoodMacros(
        name: 'soup',
        perHundred: PerHundred.zero,
        source: MacroSource.manual,
        isEstimate: false,
        basis: NutritionBasis(
          quantity: 1,
          unit: 'cup',
          macros: MacroValues(kcal: 120, protein: 6, carb: 18, fat: 3),
        ),
      ),
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recipeRepositoryProvider.overrideWithValue(repo),
        foodLookupProvider.overrideWith((ref) async => _foodLookup(db)),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RecipesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cup soup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 cup'), findsOneWidget);
  });

  testWidgets('renders a counted legacy cache row without macros', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = RecipeRepository(db);
    final recipeId = await repo.save(
      const ParsedRecipe(
        title: 'Cached soup',
        ingredients: [Ingredient('soup', quantity: '1', unit: 'cup')],
        steps: ['Heat'],
      ),
    );
    await db
        .into(db.recipeNutritionCache)
        .insert(
          RecipeNutritionCacheCompanion.insert(
            recipeId: Value(recipeId),
            ingredientsHash: 'soup\u00011\u0001cup',
            breakdownJson: jsonEncode({
              'ingredients': [
                {
                  'name': 'soup',
                  'quantity': 1,
                  'grams': null,
                  'macros': null,
                  'status': 'counted',
                  'unit': 'cup',
                },
              ],
              'total': {'kcal': 120, 'protein': 6, 'carb': 18, 'fat': 3},
              'totalGrams': 0,
              'countedCount': 1,
              'totalCount': 1,
              'allPhysicalGramsKnown': false,
            }),
          ),
        );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        recipeRepositoryProvider.overrideWithValue(repo),
        foodLookupProvider.overrideWith((ref) async => _foodLookup(db)),
      ],
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: RecipesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cached soup'));
    await tester.pumpAndSettle();

    expect(find.text('Nutrition unavailable'), findsOneWidget);
  });
}

FoodLookup _foodLookup(AppDatabase db) => FoodLookup(
  cache: FoodCacheRepository(db),
  off: OpenFoodFactsClient(),
  usda: UsdaClient(apiKey: ''),
  llm: _UnusedLlm(),
);

class _UnusedLlm implements LLMProvider {
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
    Uint8List imageBytes,
    String prompt,
    Map<String, dynamic> jsonSchema, {
    ChatOpts? opts,
  }) => throw UnimplementedError();
}

class _FailingRecipeRepository extends RecipeRepository {
  _FailingRecipeRepository(super.db);

  @override
  Future<void> delete(int id) => throw StateError('forced failure');
}
