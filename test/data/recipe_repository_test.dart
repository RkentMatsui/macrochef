// test/data/recipe_repository_test.dart
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/recipe_repository.dart';
import 'package:macrochef/models/recipe.dart';

void main() {
  late AppDatabase db;
  late RecipeRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = RecipeRepository(db);
  });
  tearDown(() => db.close());

  test('allTitles returns saved recipe titles', () async {
    await repo.save(
      const ParsedRecipe(
        title: 'Chicken Bowl',
        ingredients: [],
        steps: [],
        servings: 1,
      ),
    );
    await repo.save(
      const ParsedRecipe(
        title: 'Tortilla Wrap',
        ingredients: [],
        steps: [],
        servings: 1,
      ),
    );
    final titles = await repo.allTitles();
    expect(titles, containsAll(['Chicken Bowl', 'Tortilla Wrap']));
    expect(titles.length, 2);
  });

  test(
    'delete removes recipe-owned rows and retains historical log values',
    () async {
      final recipeId = await repo.save(
        const ParsedRecipe(
          title: 'Delete me',
          ingredients: [Ingredient('beans', quantity: '400', unit: 'g')],
          steps: ['Cook'],
        ),
      );
      await repo.putNutritionCache(recipeId, 'hash', '{"ingredients":[]}');
      final logId = await db
          .into(db.logEntries)
          .insert(
            LogEntriesCompanion.insert(
              date: '2026-07-14',
              foodName: 'Delete me',
              grams: 350,
              kcal: 500,
              protein: 20,
              carb: 80,
              fat: 10,
              source: 'manual',
              recipeId: Value(recipeId),
            ),
          );

      await repo.delete(recipeId);

      expect(await repo.all(), isEmpty);
      expect(await repo.ingredientsFor(recipeId), isEmpty);
      expect(await repo.stepsFor(recipeId), isEmpty);
      expect(await repo.nutritionCache(recipeId), isNull);
      final log = await (db.select(
        db.logEntries,
      )..where((e) => e.id.equals(logId))).getSingle();
      expect(log.recipeId, isNull);
      expect(log.foodName, 'Delete me');
      expect(log.grams, 350);
      expect(log.kcal, 500);
      expect(log.protein, 20);
      expect(log.carb, 80);
      expect(log.fat, 10);
    },
  );

  test('delete rolls back all changes when recipe deletion fails', () async {
    final recipeId = await repo.save(
      const ParsedRecipe(
        title: 'Cannot delete',
        ingredients: [Ingredient('beans', quantity: '400', unit: 'g')],
        steps: ['Cook'],
      ),
    );
    await repo.putNutritionCache(recipeId, 'hash', '{"ingredients":[]}');
    final logId = await db
        .into(db.logEntries)
        .insert(
          LogEntriesCompanion.insert(
            date: '2026-07-14',
            foodName: 'Cannot delete',
            grams: 350,
            kcal: 500,
            protein: 20,
            carb: 80,
            fat: 10,
            source: 'manual',
            recipeId: Value(recipeId),
          ),
        );
    await db.customStatement('''
      CREATE TRIGGER fail_recipe_delete
      BEFORE DELETE ON recipes
      BEGIN
        SELECT RAISE(ABORT, 'forced failure');
      END;
    ''');

    await expectLater(repo.delete(recipeId), throwsA(isA<Exception>()));

    expect(await repo.all(), hasLength(1));
    expect(await repo.ingredientsFor(recipeId), hasLength(1));
    expect(await repo.stepsFor(recipeId), hasLength(1));
    expect(await repo.nutritionCache(recipeId), isNotNull);
    final log = await (db.select(
      db.logEntries,
    )..where((e) => e.id.equals(logId))).getSingle();
    expect(log.recipeId, recipeId);
  });
}
