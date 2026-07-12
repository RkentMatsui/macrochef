import '../database.dart';

class SettingsRepository {
  final AppDatabase db;
  SettingsRepository(this.db);

  Future<String?> get(String key) async {
    final row = await (db.select(db.settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) async {
    await db.into(db.settings).insertOnConflictUpdate(
          SettingsCompanion.insert(key: key, value: value),
        );
  }

  Future<void> delete(String key) async {
    await (db.delete(db.settings)..where((s) => s.key.equals(key))).go();
  }
}
