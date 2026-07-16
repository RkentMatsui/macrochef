import 'package:drift/drift.dart';

import '../database.dart';
import '../../models/daily.dart';

class TargetRepository {
  final AppDatabase db;
  TargetRepository(this.db);

  /// Resolves a target without allowing later adaptive calculations to rewrite
  /// historical days: exact manual override, then applicable adaptive record,
  /// then manual default.
  Future<DailyTarget?> get(String date) async {
    final manual = await (db.select(
      db.dailyTargetsTable,
    )..where((t) => t.scope.equals(date))).getSingleOrNull();
    if (manual != null) return _dailyTarget(manual);

    final adaptive = await latestAdaptiveOnOrBefore(date);
    if (adaptive != null) return adaptive.target;

    final defaultTarget = await (db.select(
      db.dailyTargetsTable,
    )..where((t) => t.scope.equals('default'))).getSingleOrNull();
    return defaultTarget == null ? null : _dailyTarget(defaultTarget);
  }

  Future<void> setDefault(DailyTarget t) async {
    await db
        .into(db.dailyTargetsTable)
        .insertOnConflictUpdate(
          DailyTargetsTableData(
            scope: 'default',
            kcal: t.kcal,
            protein: t.protein,
            carb: t.carb,
            fat: t.fat,
          ),
        );
  }

  /// Sets an exact manual override for [date]. It always wins during [get].
  Future<void> setManualForDate(String date, DailyTarget target) async {
    await db
        .into(db.dailyTargetsTable)
        .insertOnConflictUpdate(
          DailyTargetsTableData(
            scope: date,
            kcal: target.kcal,
            protein: target.protein,
            carb: target.carb,
            fat: target.fat,
          ),
        );
  }

  /// Stores one audit record per effective date. Re-inserting the same date
  /// updates that future target before it is applied, without touching earlier
  /// effective dates.
  Future<void> insertAdaptive(AdaptiveTargetRecord record) async {
    await db
        .into(db.adaptiveTargets)
        .insertOnConflictUpdate(
          AdaptiveTargetsCompanion.insert(
            effectiveFrom: record.effectiveFrom,
            calculatedThrough: record.calculatedThrough,
            kcal: record.target.kcal,
            protein: record.target.protein,
            carb: record.target.carb,
            fat: record.target.fat,
            windowStart: record.windowStart,
            qualifiedIntakeDays: record.qualifiedIntakeDays,
            weightObservationCount: record.weightObservationCount,
            estimatedMaintenanceKcal: record.estimatedMaintenanceKcal,
            appliedAdjustmentKcal: record.appliedAdjustmentKcal,
            reason: record.reason,
            createdAt: Value(record.createdAt),
          ),
        );
  }

  Future<AdaptiveTargetRecord?> latestAdaptiveOnOrBefore(String date) async {
    final row =
        await (db.select(db.adaptiveTargets)
              ..where((t) => t.effectiveFrom.isSmallerOrEqualValue(date))
              ..orderBy([
                (t) => OrderingTerm.desc(t.effectiveFrom),
                (t) => OrderingTerm.desc(t.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _adaptiveRecord(row);
  }

  Future<AdaptiveTargetRecord?> latestAdaptive() async {
    final row =
        await (db.select(db.adaptiveTargets)
              ..orderBy([
                (t) => OrderingTerm.desc(t.effectiveFrom),
                (t) => OrderingTerm.desc(t.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _adaptiveRecord(row);
  }

  DailyTarget _dailyTarget(DailyTargetsTableData row) => DailyTarget(
    kcal: row.kcal,
    protein: row.protein,
    carb: row.carb,
    fat: row.fat,
  );

  AdaptiveTargetRecord _adaptiveRecord(AdaptiveTarget row) =>
      AdaptiveTargetRecord(
        target: DailyTarget(
          kcal: row.kcal,
          protein: row.protein,
          carb: row.carb,
          fat: row.fat,
        ),
        calculatedThrough: row.calculatedThrough,
        effectiveFrom: row.effectiveFrom,
        windowStart: row.windowStart,
        qualifiedIntakeDays: row.qualifiedIntakeDays,
        weightObservationCount: row.weightObservationCount,
        estimatedMaintenanceKcal: row.estimatedMaintenanceKcal,
        appliedAdjustmentKcal: row.appliedAdjustmentKcal,
        reason: row.reason,
        createdAt: row.createdAt,
      );
}
