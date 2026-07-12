import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/services/grocery_combiner.dart';

void main() {
  RecipeIngredient ing(String n, String? q, String? u) => RecipeIngredient(
        id: 0, recipeId: 0, name: n, quantity: q, unit: u,
      );

  test('combines duplicates by normalized name, concatenates quantities', () {
    final out = combineIngredients([
      ing('Flour', '200', 'g'),
      ing('flour', '1', 'cup'),
      ing('Eggs', '2', null),
    ]);
    expect(out.length, 2);
    final flour = out.firstWhere((d) => d.name.toLowerCase() == 'flour');
    expect(flour.detail, '200 g + 1 cup');
    final eggs = out.firstWhere((d) => d.name.toLowerCase() == 'eggs');
    expect(eggs.detail, '2');
  });
}
