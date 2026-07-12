import 'package:drift/drift.dart';
import '../database.dart';

class LogRepository {
  final AppDatabase db;
  LogRepository(this.db);

  Future<void> add(LogEntriesCompanion entry) async {
    await db.into(db.logEntries).insert(entry);
  }

  Future<List<LogEntry>> forDate(String date) {
    return (db.select(db.logEntries)..where((e) => e.date.equals(date))).get();
  }

  /// All entries whose date string falls in [start, end] inclusive.
  /// Relies on YYYY-MM-DD being lexically ordered. Ordered by date asc.
  Future<List<LogEntry>> forDateRange(String start, String end) {
    return (db.select(db.logEntries)
          ..where((e) =>
              e.date.isBiggerOrEqualValue(start) &
              e.date.isSmallerOrEqualValue(end))
          ..orderBy([(e) => OrderingTerm.asc(e.date)]))
        .get();
  }

  Future<void> update(int id, LogEntriesCompanion entry) async {
    await (db.update(db.logEntries)..where((e) => e.id.equals(id))).write(entry);
  }

  Future<void> delete(int id) async {
    await (db.delete(db.logEntries)..where((e) => e.id.equals(id))).go();
  }
}
