import 'package:drift/drift.dart';
import '../database.dart';

/// The single DB gateway for the [DailyActivity] table. UI and services never
/// touch the database directly — they go through this repository.
///
/// One row per day, keyed by `date` (YYYY-MM-DD). [upsert] overwrites the day's
/// row. Activity is informational only; it never feeds calorie targets.
class DailyActivityRepository {
  final AppDatabase db;
  DailyActivityRepository(this.db);

  /// Insert or overwrite the activity row for [date]. Only the provided fields
  /// are written; passing null for a field stores null (clears it).
  Future<void> upsert(
    String date, {
    int? steps,
    int? activeMinutes,
    String source = 'manual',
  }) async {
    await db.into(db.dailyActivity).insert(
          DailyActivityCompanion.insert(
            date: date,
            steps: Value(steps),
            activeMinutes: Value(activeMinutes),
            source: Value(source),
          ),
          onConflict: DoUpdate(
            (_) => DailyActivityCompanion.custom(
              steps: Variable(steps),
              activeMinutes: Variable(activeMinutes),
              source: Variable(source),
            ),
            target: [db.dailyActivity.date],
          ),
        );
  }

  Future<DailyActivityData?> forDate(String date) {
    return (db.select(db.dailyActivity)..where((a) => a.date.equals(date)))
        .getSingleOrNull();
  }

  /// All activity rows in the inclusive date range [startDate, endDate],
  /// ascending by date.
  Future<List<DailyActivityData>> range(String startDate, String endDate) {
    return (db.select(db.dailyActivity)
          ..where((a) =>
              a.date.isBiggerOrEqualValue(startDate) &
              a.date.isSmallerOrEqualValue(endDate))
          ..orderBy([(a) => OrderingTerm.asc(a.date)]))
        .get();
  }
}
