import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:drift/drift.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('recipe servings defaults to 1', () async {
    final id = await db.into(db.recipes).insert(
          RecipesCompanion.insert(title: 'Soup'),
        );
    final row = await (db.select(db.recipes)..where((r) => r.id.equals(id)))
        .getSingle();
    expect(row.servings, 1);
  });

  test('foodCache userOverride defaults to false', () async {
    await db.into(db.foodCache).insert(FoodCacheCompanion.insert(
          name: 'x', source: 'usda',
          kcal100: 1, protein100: 1, carb100: 1, fat100: 1,
        ));
    final row = await db.select(db.foodCache).getSingle();
    expect(row.userOverride, false);
  });

  test('grocery items can be inserted and checked', () async {
    final id = await db.into(db.groceryItems).insert(
          GroceryItemsCompanion.insert(name: 'eggs', detail: const Value('6')),
        );
    await (db.update(db.groceryItems)..where((g) => g.id.equals(id)))
        .write(const GroceryItemsCompanion(checked: Value(true)));
    final row = await db.select(db.groceryItems).getSingle();
    expect(row.checked, true);
  });
}
