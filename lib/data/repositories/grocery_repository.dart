import 'package:drift/drift.dart';
import '../database.dart';
import '../../services/grocery_combiner.dart';

class GroceryRepository {
  final AppDatabase db;
  GroceryRepository(this.db);

  Future<List<GroceryItem>> all() => (db.select(db.groceryItems)
        ..orderBy([(g) => OrderingTerm.asc(g.name)]))
      .get();

  Future<void> replaceAll(List<GroceryDraft> drafts) async {
    await db.transaction(() async {
      await db.delete(db.groceryItems).go();
      for (final d in drafts) {
        await db.into(db.groceryItems).insert(GroceryItemsCompanion.insert(
              name: d.name, detail: Value(d.detail),
            ));
      }
    });
  }

  Future<void> setChecked(int id, bool checked) async {
    await (db.update(db.groceryItems)..where((g) => g.id.equals(id)))
        .write(GroceryItemsCompanion(checked: Value(checked)));
  }

  Future<void> clear() => db.delete(db.groceryItems).go();
}
