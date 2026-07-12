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

  test('setIngredientQuantityByName updates the matching ingredient only',
      () async {
    final id = await repo.save(ParsedRecipe(
      title: 'Chicken bowl',
      servings: 1,
      ingredients: [
        Ingredient('Chicken breast', quantity: '200', unit: 'g'),
        Ingredient('Rice', quantity: '100', unit: 'g'),
      ],
      steps: ['cook'],
    ));

    final matched =
        await repo.setIngredientQuantityByName(id, 'chicken', 1325, 'g');
    expect(matched, isTrue);

    final ings = await repo.ingredientsFor(id);
    final chicken =
        ings.firstWhere((i) => i.name.toLowerCase().contains('chicken'));
    final rice = ings.firstWhere((i) => i.name.toLowerCase().contains('rice'));
    expect(chicken.quantity, '1325');
    expect(chicken.unit, 'g');
    expect(rice.quantity, '100'); // untouched
  });

  test('returns false when no ingredient name matches', () async {
    final id = await repo.save(ParsedRecipe(
      title: 'X',
      servings: 1,
      ingredients: [Ingredient('Rice', quantity: '100', unit: 'g')],
      steps: ['cook'],
    ));
    expect(
        await repo.setIngredientQuantityByName(id, 'beef', 300, 'g'), isFalse);
  });
}
