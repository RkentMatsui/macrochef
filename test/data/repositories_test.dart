import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/recipe_repository.dart';
import 'package:macrochef/data/repositories/settings_repository.dart';
import 'package:macrochef/data/repositories/target_repository.dart';
import 'package:macrochef/data/repositories/log_repository.dart';
import 'package:macrochef/models/recipe.dart';
import 'package:macrochef/models/daily.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('save recipe persists steps in order', () async {
    final repo = RecipeRepository(db);
    final id = await repo.save(const ParsedRecipe(
      title: 'Omelette',
      ingredients: [Ingredient('eggs', quantity: '3')],
      steps: ['Crack eggs', 'Whisk', 'Cook'],
    ));
    final steps = await repo.stepsFor(id);
    expect(steps, ['Crack eggs', 'Whisk', 'Cook']);
  });

  test('settings set then get returns latest value (upsert)', () async {
    final repo = SettingsRepository(db);
    await repo.set('llm_kind', 'claude');
    await repo.set('llm_kind', 'openai');
    expect(await repo.get('llm_kind'), 'openai');
    expect(await repo.get('missing'), isNull);
  });

  test('target get prefers date-specific over default', () async {
    final repo = TargetRepository(db);
    await repo.setDefault(const DailyTarget(
        kcal: 2000, protein: 150, carb: 200, fat: 60));
    expect((await repo.get('2026-06-14'))!.kcal, 2000);
  });

  test('log forDate returns only that day', () async {
    final repo = LogRepository(db);
    await repo.add(LogEntriesCompanion.insert(
      date: '2026-06-14', foodName: 'rice', grams: 100,
      kcal: 130, protein: 2.7, carb: 28, fat: 0.3, source: 'off',
    ));
    await repo.add(LogEntriesCompanion.insert(
      date: '2026-06-13', foodName: 'oats', grams: 50,
      kcal: 190, protein: 6.7, carb: 33, fat: 3.5, source: 'off',
    ));
    final today = await repo.forDate('2026-06-14');
    expect(today.length, 1);
    expect(today.first.foodName, 'rice');
  });

  test('save persists servings and updateServings changes it', () async {
    final repo = RecipeRepository(db);
    final id = await repo.save(const ParsedRecipe(
      title: 'Chili', ingredients: [Ingredient('beans', quantity: '400', unit: 'g')],
      steps: ['Cook'], servings: 4,
    ));
    var row = await (db.select(db.recipes)..where((r) => r.id.equals(id))).getSingle();
    expect(row.servings, 4);
    await repo.updateServings(id, 6);
    row = await (db.select(db.recipes)..where((r) => r.id.equals(id))).getSingle();
    expect(row.servings, 6);
  });

  test('servingsFor returns the recipe servings', () async {
    final repo = RecipeRepository(db);
    final id = await repo.save(const ParsedRecipe(
      title: 'Stew', ingredients: [], steps: [], servings: 3,
    ));
    expect(await repo.servingsFor(id), 3);
  });

  test('updateFull replaces title, servings, ingredients, and steps', () async {
    final repo = RecipeRepository(db);
    final id = await repo.save(const ParsedRecipe(
      title: 'Old Title',
      ingredients: [Ingredient('old ingredient', quantity: '1', unit: 'cup')],
      steps: ['Old step 1', 'Old step 2'],
      servings: 2,
    ));

    await repo.updateFull(
      id,
      const ParsedRecipe(
        title: 'New Title',
        ingredients: [
          Ingredient('chicken', quantity: '200', unit: 'g'),
          Ingredient('broccoli', quantity: '100', unit: 'g'),
        ],
        steps: ['Marinate chicken', 'Steam broccoli', 'Combine and serve'],
        servings: 5,
      ),
    );

    // Assert title and servings updated
    final row = await (db.select(db.recipes)..where((r) => r.id.equals(id))).getSingle();
    expect(row.title, 'New Title');
    expect(row.servings, 5);

    // Assert ingredients replaced
    final ings = await repo.ingredientsFor(id);
    expect(ings.map((i) => i.name).toList(), ['chicken', 'broccoli']);

    // Assert steps replaced in order
    final steps = await repo.stepsFor(id);
    expect(steps, ['Marinate chicken', 'Steam broccoli', 'Combine and serve']);
  });
}
