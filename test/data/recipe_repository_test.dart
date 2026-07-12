// test/data/recipe_repository_test.dart
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
    await repo.save(const ParsedRecipe(
        title: 'Chicken Bowl', ingredients: [], steps: [], servings: 1));
    await repo.save(const ParsedRecipe(
        title: 'Tortilla Wrap', ingredients: [], steps: [], servings: 1));
    final titles = await repo.allTitles();
    expect(titles, containsAll(['Chicken Bowl', 'Tortilla Wrap']));
    expect(titles.length, 2);
  });
}
