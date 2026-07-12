import '../database.dart';
import '../../models/daily.dart';

class TargetRepository {
  final AppDatabase db;
  TargetRepository(this.db);

  /// Returns the date-specific target if present, else the 'default' target.
  Future<DailyTarget?> get(String date) async {
    final row = await (db.select(db.dailyTargetsTable)
          ..where((t) => t.scope.isIn([date, 'default'])))
        .get();
    if (row.isEmpty) return null;
    // Prefer the date-specific row over 'default'.
    final chosen = row.firstWhere(
      (r) => r.scope == date,
      orElse: () => row.first,
    );
    return DailyTarget(
      kcal: chosen.kcal,
      protein: chosen.protein,
      carb: chosen.carb,
      fat: chosen.fat,
    );
  }

  Future<void> setDefault(DailyTarget t) async {
    await db.into(db.dailyTargetsTable).insertOnConflictUpdate(
          DailyTargetsTableData(
            scope: 'default',
            kcal: t.kcal,
            protein: t.protein,
            carb: t.carb,
            fat: t.fat,
          ),
        );
  }
}
