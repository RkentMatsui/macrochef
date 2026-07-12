import 'package:drift/drift.dart';
import '../database.dart';

class WeightRepository {
  final AppDatabase db;
  WeightRepository(this.db);

  Future<void> upsert(String date, double kg) async {
    await db.into(db.weightEntries).insert(
          WeightEntriesCompanion.insert(date: date, kg: kg),
          onConflict: DoUpdate(
            (_) => WeightEntriesCompanion.custom(
              kg: Variable(kg),
            ),
            target: [db.weightEntries.date],
          ),
        );
  }

  Future<WeightEntry?> forDate(String date) {
    return (db.select(db.weightEntries)..where((w) => w.date.equals(date)))
        .getSingleOrNull();
  }

  Future<List<WeightEntry>> forDateRange(String start, String end) {
    return (db.select(db.weightEntries)
          ..where((w) =>
              w.date.isBiggerOrEqualValue(start) &
              w.date.isSmallerOrEqualValue(end))
          ..orderBy([(w) => OrderingTerm.asc(w.date)]))
        .get();
  }

  Future<List<WeightEntry>> all() {
    return (db.select(db.weightEntries)
          ..orderBy([(w) => OrderingTerm.asc(w.date)]))
        .get();
  }

  Future<void> delete(String date) async {
    await (db.delete(db.weightEntries)..where((w) => w.date.equals(date))).go();
  }
}
