import 'package:drift/drift.dart';
import '../database.dart';
import '../../models/recipe.dart';

class RecipeRepository {
  final AppDatabase db;
  RecipeRepository(this.db);

  Future<int> save(ParsedRecipe r) async {
    return db.transaction(() async {
      final id = await db
          .into(db.recipes)
          .insert(RecipesCompanion.insert(title: r.title, servings: Value(r.servings)));
      for (final ing in r.ingredients) {
        await db.into(db.recipeIngredients).insert(
              RecipeIngredientsCompanion.insert(
                recipeId: id,
                name: ing.name,
                quantity: Value(ing.quantity),
                unit: Value(ing.unit),
              ),
            );
      }
      for (var i = 0; i < r.steps.length; i++) {
        await db.into(db.recipeSteps).insert(
              RecipeStepsCompanion.insert(
                recipeId: id,
                position: i,
                stepText: r.steps[i],
              ),
            );
      }
      return id;
    });
  }

  Future<List<Recipe>> all() => (db.select(db.recipes)
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .get();

  Future<List<String>> allTitles() async =>
      (await all()).map((r) => r.title).toList();

  Future<List<String>> stepsFor(int recipeId) async {
    final rows = await (db.select(db.recipeSteps)
          ..where((s) => s.recipeId.equals(recipeId))
          ..orderBy([(s) => OrderingTerm.asc(s.position)]))
        .get();
    return rows.map((e) => e.stepText).toList();
  }

  Future<List<RecipeIngredient>> ingredientsFor(int recipeId) async {
    return (db.select(db.recipeIngredients)
          ..where((r) => r.recipeId.equals(recipeId))
          ..orderBy([(r) => OrderingTerm.asc(r.id)]))
        .get();
  }

  Future<void> updateServings(int id, int servings) async {
    final n = servings < 1 ? 1 : servings;
    await (db.update(db.recipes)..where((r) => r.id.equals(id)))
        .write(RecipesCompanion(servings: Value(n)));
  }

  Future<int> servingsFor(int id) async {
    final row = await (db.select(db.recipes)..where((r) => r.id.equals(id)))
        .getSingleOrNull();
    return row?.servings ?? 1;
  }

  /// Sets the quantity+unit of the first ingredient of [recipeId] whose name
  /// contains [foodQuery] (case-insensitive). Returns true if one matched.
  /// Used by the cooking voice flow ("I used 1325g of chicken") to override an
  /// ingredient's actual amount without rebuilding the whole recipe.
  Future<bool> setIngredientQuantityByName(
    int recipeId,
    String foodQuery,
    double grams,
    String unit,
  ) async {
    final q = foodQuery.trim().toLowerCase();
    if (q.isEmpty) return false;
    final ings = await ingredientsFor(recipeId);
    RecipeIngredient? target;
    for (final ing in ings) {
      if (ing.name.toLowerCase().contains(q)) {
        target = ing;
        break;
      }
    }
    if (target == null) return false;
    final qtyStr = grams == grams.roundToDouble()
        ? grams.toStringAsFixed(0)
        : grams.toString();
    await (db.update(db.recipeIngredients)
          ..where((t) => t.id.equals(target!.id)))
        .write(RecipeIngredientsCompanion(
      quantity: Value(qtyStr),
      unit: Value(unit),
    ));
    return true;
  }

  /// Cached nutrition breakdown for [recipeId] — the ingredient-list signature
  /// it was computed from and the serialized breakdown — or null if none.
  Future<({String hash, String json})?> nutritionCache(int recipeId) async {
    final row = await (db.select(db.recipeNutritionCache)
          ..where((t) => t.recipeId.equals(recipeId)))
        .getSingleOrNull();
    return row == null
        ? null
        : (hash: row.ingredientsHash, json: row.breakdownJson);
  }

  /// Store (or replace) the cached breakdown for [recipeId].
  Future<void> putNutritionCache(
    int recipeId,
    String ingredientsHash,
    String breakdownJson,
  ) async {
    await db.into(db.recipeNutritionCache).insertOnConflictUpdate(
          RecipeNutritionCacheCompanion(
            recipeId: Value(recipeId),
            ingredientsHash: Value(ingredientsHash),
            breakdownJson: Value(breakdownJson),
          ),
        );
  }

  /// Drop the cached breakdown for [recipeId] (e.g. after an ingredient edit).
  Future<void> deleteNutritionCache(int recipeId) async {
    await (db.delete(db.recipeNutritionCache)
          ..where((t) => t.recipeId.equals(recipeId)))
        .go();
  }

  Future<void> updateFull(int id, ParsedRecipe r) async {
    await db.transaction(() async {
      await (db.update(db.recipes)..where((t) => t.id.equals(id))).write(
          RecipesCompanion(
              title: Value(r.title), servings: Value(r.servings < 1 ? 1 : r.servings)));
      await (db.delete(db.recipeIngredients)..where((t) => t.recipeId.equals(id))).go();
      for (final ing in r.ingredients) {
        await db.into(db.recipeIngredients).insert(RecipeIngredientsCompanion.insert(
            recipeId: id, name: ing.name,
            quantity: Value(ing.quantity), unit: Value(ing.unit)));
      }
      await (db.delete(db.recipeSteps)..where((t) => t.recipeId.equals(id))).go();
      for (var i = 0; i < r.steps.length; i++) {
        await db.into(db.recipeSteps).insert(RecipeStepsCompanion.insert(
            recipeId: id, position: i, stepText: r.steps[i]));
      }
    });
  }
}
