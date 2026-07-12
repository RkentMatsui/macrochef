import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('insert and read a recipe', () async {
    final id = await db.into(db.recipes).insert(
          RecipesCompanion.insert(title: 'Test Curry'),
        );
    final row = await (db.select(db.recipes)..where((r) => r.id.equals(id)))
        .getSingle();
    expect(row.title, 'Test Curry');
  });
}
