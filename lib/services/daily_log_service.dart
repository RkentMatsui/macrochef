import 'package:drift/drift.dart';
import '../models/macros.dart';
import '../models/daily.dart';
import '../data/database.dart';
import '../data/repositories/log_repository.dart';
import '../data/repositories/target_repository.dart';

class FoodContribution {
  final String name;
  final double kcal;
  final double protein;
  final int count;
  const FoodContribution({
    required this.name,
    required this.kcal,
    required this.protein,
    required this.count,
  });
}

/// A food the user logs often, captured with the exact portion (weight +
/// absolute macros + source) it was last logged with, so it can be re-logged
/// in one tap without re-resolving nutrition. Powers the "Frequent" quick-add
/// strip.
class FrequentFood {
  final String name;
  final double grams;
  final MacroValues macros;
  final MacroSource source;
  final int? recipeId;

  /// Number of times this food was logged in the lookback window.
  final int count;

  const FrequentFood({
    required this.name,
    required this.grams,
    required this.macros,
    required this.source,
    required this.recipeId,
    required this.count,
  });
}

class DailyLogService {
  final LogRepository logs;
  final TargetRepository targets;

  DailyLogService({required this.logs, required this.targets});

  Future<void> log(
    String date, {
    required String name,
    required double grams,
    required MacroValues macros,
    required MacroSource source,
    int? recipeId,
  }) async {
    await logs.add(LogEntriesCompanion.insert(
      date: date,
      foodName: name,
      grams: grams,
      kcal: macros.kcal,
      protein: macros.protein,
      carb: macros.carb,
      fat: macros.fat,
      fibre: Value(macros.fibre),
      source: source.name,
      recipeId: Value(recipeId),
    ));
  }

  /// Overwrites an existing entry's name, weight and macros. Date, source and
  /// recipeId are left untouched.
  Future<void> update(
    int id, {
    required String name,
    required double grams,
    required MacroValues macros,
  }) async {
    await logs.update(
      id,
      LogEntriesCompanion(
        foodName: Value(name),
        grams: Value(grams),
        kcal: Value(macros.kcal),
        protein: Value(macros.protein),
        carb: Value(macros.carb),
        fat: Value(macros.fat),
        fibre: Value(macros.fibre),
      ),
    );
  }

  Future<DailyTotals> totals(String date) async {
    final entries = await logs.forDate(date);
    var consumed = MacroValues.zero;
    for (final e in entries) {
      consumed = consumed +
          MacroValues(
            kcal: e.kcal,
            protein: e.protein,
            carb: e.carb,
            fat: e.fat,
            fibre: e.fibre,
          );
    }
    final target = await targets.get(date);
    return DailyTotals(consumed, target);
  }

  Future<void> setTarget(DailyTarget t) async {
    await targets.setDefault(t);
  }

  /// One [DailyTotals] per day in [start, end] inclusive, ascending. Empty days
  /// carry zero consumed but still carry that day's target. Entries for the
  /// whole window are fetched in a single query and summed per day in memory
  /// (instead of one query per day).
  Future<List<DailyTotals>> rangeTotals(String start, String end) async {
    final days = <String>[];
    var cursor = _parse(start);
    final last = _parse(end);
    while (!cursor.isAfter(last)) {
      days.add(_fmt(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }

    final entries = await logs.forDateRange(start, end);
    final byDate = <String, MacroValues>{};
    for (final e in entries) {
      final prev = byDate[e.date] ?? MacroValues.zero;
      byDate[e.date] = prev +
          MacroValues(kcal: e.kcal, protein: e.protein, carb: e.carb, fat: e.fat, fibre: e.fibre);
    }

    final out = <DailyTotals>[];
    for (final d in days) {
      final target = await targets.get(d);
      out.add(DailyTotals(byDate[d] ?? MacroValues.zero, target));
    }
    return out;
  }

  /// Aggregates entries in [start, end] by foodName: summed kcal + protein and
  /// occurrence count, sorted by kcal desc. Capped at [limit] (default 10).
  Future<List<FoodContribution>> topFoods(String start, String end,
      {int limit = 10}) async {
    final entries = await logs.forDateRange(start, end);
    final byName = <String, FoodContribution>{};
    for (final e in entries) {
      final prev = byName[e.foodName];
      byName[e.foodName] = FoodContribution(
        name: e.foodName,
        kcal: (prev?.kcal ?? 0) + e.kcal,
        protein: (prev?.protein ?? 0) + e.protein,
        count: (prev?.count ?? 0) + 1,
      );
    }
    final list = byName.values.toList()
      ..sort((a, b) => b.kcal.compareTo(a.kcal));
    return list.length > limit ? list.sublist(0, limit) : list;
  }

  /// The user's most-frequently-logged foods over the trailing [windowDays]
  /// ending at [reference] (a YYYY-MM-DD date), each carrying the exact portion
  /// it was *last* logged with so it can be re-logged verbatim. Ranked by
  /// occurrence count, ties broken by recency (latest entry id). Capped at
  /// [limit]. There is no per-entry timestamp, so "last logged" is the
  /// highest-id row for a given name (rows are inserted in chronological order).
  Future<List<FrequentFood>> frequentFoods(
    String reference, {
    int windowDays = 60,
    int limit = 12,
  }) async {
    final end = _parse(reference);
    final start = end.subtract(Duration(days: windowDays - 1));
    final entries = await logs.forDateRange(_fmt(start), _fmt(end));

    // name -> (most-recent entry by id, occurrence count)
    final byName = <String, ({LogEntry last, int count})>{};
    for (final e in entries) {
      final cur = byName[e.foodName];
      final last = (cur == null || e.id > cur.last.id) ? e : cur.last;
      byName[e.foodName] = (last: last, count: (cur?.count ?? 0) + 1);
    }

    final ranked = byName.values.toList()
      ..sort((a, b) {
        final c = b.count.compareTo(a.count);
        return c != 0 ? c : b.last.id.compareTo(a.last.id);
      });

    return ranked.take(limit).map((r) {
      final e = r.last;
      return FrequentFood(
        name: e.foodName,
        grams: e.grams,
        macros: MacroValues(
            kcal: e.kcal,
            protein: e.protein,
            carb: e.carb,
            fat: e.fat,
            fibre: e.fibre),
        source: MacroSource.values.firstWhere(
            (s) => s.name == e.source,
            orElse: () => MacroSource.manual),
        recipeId: e.recipeId,
        count: r.count,
      );
    }).toList();
  }

  /// Re-logs every entry from [fromDate] onto [toDate] verbatim (name, weight,
  /// macros, source, recipe link). Returns the number copied. Powers "Copy
  /// yesterday" so a typical day can be logged in one tap.
  Future<int> copyDay(String fromDate, String toDate) async {
    final entries = await logs.forDate(fromDate);
    for (final e in entries) {
      await log(
        toDate,
        name: e.foodName,
        grams: e.grams,
        macros: MacroValues(
            kcal: e.kcal,
            protein: e.protein,
            carb: e.carb,
            fat: e.fat,
            fibre: e.fibre),
        source: MacroSource.values.firstWhere(
            (s) => s.name == e.source,
            orElse: () => MacroSource.manual),
        recipeId: e.recipeId,
      );
    }
    return entries.length;
  }

  /// Re-logs a [FrequentFood] to [date] with its stored portion — instant and
  /// offline (no nutrition re-resolve, since the absolute macros are kept).
  Future<void> relog(String date, FrequentFood food) {
    return log(
      date,
      name: food.name,
      grams: food.grams,
      macros: food.macros,
      source: food.source,
      recipeId: food.recipeId,
    );
  }

  DateTime _parse(String s) {
    final p = s.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
