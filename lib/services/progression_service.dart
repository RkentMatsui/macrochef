import '../data/database.dart';
import '../data/repositories/training_repository.dart';

/// One per-session datapoint for an exercise's progression chart.
class ProgressionPoint {
  /// Session date, YYYY-MM-DD.
  final String date;

  /// Best estimated 1RM across the session's working sets (kg). 0 if no
  /// weight/reps were logged.
  final double best1rm;

  /// Heaviest single set weight in the session (kg). 0 if none.
  final double topSetWeightKg;

  /// Total working-set volume in the session (Σ weight×reps, kg). 0 if none.
  final double totalVolume;

  const ProgressionPoint({
    required this.date,
    required this.best1rm,
    required this.topSetWeightKg,
    required this.totalVolume,
  });
}

/// The kind of personal record a [Pr] represents.
enum PrKind { weight, estimated1rm }

/// A personal-record event: the first time a metric exceeded its prior best.
class Pr {
  final PrKind kind;
  final double value;
  final String date;
  const Pr({required this.kind, required this.value, required this.date});
}

/// One per-session cardio datapoint (distance, duration, derived pace).
class CardioPoint {
  final String date;
  final double? distanceM;
  final int? durationSec;

  const CardioPoint({
    required this.date,
    required this.distanceM,
    required this.durationSec,
  });

  /// Pace in seconds per kilometre, or null when distance/duration are missing
  /// or distance is zero.
  double? get paceSecPerKm {
    final d = distanceM;
    final t = durationSec;
    if (d == null || t == null || d <= 0) return null;
    return t / (d / 1000.0);
  }
}

/// One exercise's contribution to a muscle's weekly work. [sets] is fractional:
/// a set counts 1.0 toward the exercise's primary muscle and 0.5 toward each of
/// its secondary movers (see [ProgressionService.kSecondarySetCredit]).
class MuscleExerciseShare {
  final String name;
  final double volume;
  final double sets;
  const MuscleExerciseShare({
    required this.name,
    required this.volume,
    required this.sets,
  });
}

/// Per-muscle weekly drill-down: total working-set volume, set count, the
/// most-recent training date this week, and the exercises that hit it (sorted
/// by descending volume). Used by the analytics muscle-map tap-to-drill sheet.
class MuscleBreakdown {
  final String muscle;
  final double volume;

  /// Fractional weekly working sets: 1.0 per set for the primary muscle, 0.5
  /// per set for each secondary mover (fractional set counting).
  final double sets;

  /// Latest session date (YYYY-MM-DD) this week that trained the muscle, or
  /// null if none.
  final String? lastTrained;
  final List<MuscleExerciseShare> exercises;

  const MuscleBreakdown({
    required this.muscle,
    required this.volume,
    required this.sets,
    required this.lastTrained,
    required this.exercises,
  });
}

/// Training consistency over a trailing window of weeks.
class ConsistencyStats {
  /// Total completed sessions counted in the window.
  final int totalSessions;

  /// Number of weeks in the window.
  final int weeks;

  /// Consecutive weeks (ending with the reference week) that have ≥1 session.
  final int currentStreakWeeks;

  const ConsistencyStats({
    required this.totalSessions,
    required this.weeks,
    required this.currentStreakWeeks,
  });

  /// Average sessions per week across the window.
  double get sessionsPerWeek => weeks <= 0 ? 0.0 : totalSessions / weeks;
}

/// Pure-Dart progression analytics over [SetEntries]. No Flutter imports; all DB
/// access goes through [TrainingRepository]. Weights/distances/durations are
/// canonical (kg / metres / seconds) — display conversion happens at the UI.
class ProgressionService {
  final TrainingRepository repo;
  ProgressionService(this.repo);

  /// Estimated one-rep max (Epley): `weightKg * (1 + reps/30)`. A single rep
  /// returns the weight itself.
  static double epley1rm(double weightKg, int reps) {
    if (reps <= 1) return weightKg;
    return weightKg * (1 + reps / 30.0);
  }

  /// Working-set volume: `weightKg * reps`, treating nulls as 0.
  static double setVolume(SetEntry s) =>
      (s.weightKg ?? 0) * (s.reps ?? 0);

  /// Whether a set actually did work — has reps, time, or distance. A
  /// bodyweight or timed set (e.g. hanging leg raise, plank) carries no external
  /// load, so its `setVolume` is 0; it must still count as a performed set
  /// toward a muscle's weekly set total instead of being dropped the way empty
  /// rows are.
  static bool setHasWork(SetEntry s) =>
      (s.reps ?? 0) > 0 || (s.durationSec ?? 0) > 0 || (s.distanceM ?? 0) > 0;

  /// The Monday (date-only) of the week containing [date].
  static DateTime _weekStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Per-session progression series for [exerciseId]: best est-1RM, top-set
  /// weight, and total volume, one point per session date (ascending). Warmup
  /// sets are excluded from the metrics.
  Future<List<ProgressionPoint>> exerciseSeries(int exerciseId) async {
    final rows = await repo.setsForExercise(exerciseId);
    // Group by session id, preserving first-seen (date-ascending) order.
    final order = <int>[];
    final bySession = <int, List<SetWithSession>>{};
    for (final r in rows) {
      final sid = r.session.id;
      if (!bySession.containsKey(sid)) {
        bySession[sid] = [];
        order.add(sid);
      }
      bySession[sid]!.add(r);
    }

    final points = <ProgressionPoint>[];
    for (final sid in order) {
      final sets = bySession[sid]!;
      var best1rm = 0.0;
      var topSet = 0.0;
      var volume = 0.0;
      for (final r in sets) {
        final s = r.set;
        if (s.isWarmup) continue;
        final w = s.weightKg;
        final reps = s.reps;
        if (w != null && reps != null) {
          final e = epley1rm(w, reps);
          if (e > best1rm) best1rm = e;
          if (w > topSet) topSet = w;
          volume += setVolume(s);
        }
      }
      points.add(ProgressionPoint(
        date: sets.first.session.date,
        best1rm: best1rm,
        topSetWeightKg: topSet,
        totalVolume: volume,
      ));
    }
    return points;
  }

  /// Detect personal records over [exerciseId]'s history: each time the max
  /// single-set weight or the max estimated-1RM rises above its prior best,
  /// chronologically. The first qualifying value establishes the baseline (and
  /// is itself a PR). Warmups excluded.
  Future<List<Pr>> detectPrs(int exerciseId) async {
    final rows = await repo.setsForExercise(exerciseId);
    var bestWeight = double.negativeInfinity;
    var best1rm = double.negativeInfinity;
    final prs = <Pr>[];
    for (final r in rows) {
      final s = r.set;
      if (s.isWarmup) continue;
      final w = s.weightKg;
      final reps = s.reps;
      if (w == null || reps == null) continue;
      if (w > bestWeight) {
        bestWeight = w;
        prs.add(Pr(kind: PrKind.weight, value: w, date: r.session.date));
      }
      final e = epley1rm(w, reps);
      if (e > best1rm) {
        best1rm = e;
        prs.add(
            Pr(kind: PrKind.estimated1rm, value: e, date: r.session.date));
      }
    }
    return prs;
  }

  /// Total working-set volume for the week containing [reference], grouped by
  /// each exercise's `primaryMuscle` (exercises without a muscle are grouped
  /// under `'other'`). Warmups excluded.
  Future<Map<String, double>> weeklyVolumeByMuscle(DateTime reference) async {
    final monday = _weekStart(reference);
    final sunday = monday.add(const Duration(days: 6));
    final rows = await repo.completedSetsInRange(
        _dateKey(monday), _dateKey(sunday));
    final byMuscle = <String, double>{};
    for (final r in rows) {
      if (r.set.isWarmup) continue;
      final vol = setVolume(r.set);
      if (vol <= 0) continue;
      final muscle = r.exercise.primaryMuscle ?? 'other';
      byMuscle[muscle] = (byMuscle[muscle] ?? 0) + vol;
    }
    return byMuscle;
  }

  /// Set-credit a secondary/synergist muscle receives per working set, versus
  /// 1.0 for the primary mover — the fractional-set-counting convention used by
  /// hypertrophy volume frameworks (e.g. RP). A bench press is 1 set for chest
  /// and 0.5 sets each for triceps and shoulders, so indirect volume counts
  /// toward those muscles' weekly targets and the heatmap doesn't under-report
  /// (helping avoid overworking synergists).
  static const double kSecondarySetCredit = 0.5;

  /// Parses an exercise's comma-separated `secondaryMuscles` into keys.
  static List<String> secondaryMusclesOf(String? csv) {
    if (csv == null || csv.trim().isEmpty) return const [];
    return csv
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Per-muscle drill-down for the week containing [reference]: total volume,
  /// fractional set count (primary 1.0 + secondary 0.5 each), the most-recent
  /// training date, and the exercises that hit each muscle (descending by
  /// volume). Warmups and empty (no reps/time/distance) sets are excluded, but
  /// load-free bodyweight/timed work still counts as a set; exercises without a
  /// `primaryMuscle` are grouped under `'other'`.
  Future<Map<String, MuscleBreakdown>> weeklyMuscleBreakdown(
      DateTime reference) async {
    final monday = _weekStart(reference);
    final sunday = monday.add(const Duration(days: 6));
    final rows = await repo.completedSetsInRange(
        _dateKey(monday), _dateKey(sunday));

    // muscle -> aggregates, with a nested exercise-name -> (vol, sets) map.
    final agg = <String, ({double vol, double sets, String? last})>{};
    final perEx = <String, Map<String, ({double vol, double sets})>>{};

    for (final r in rows) {
      if (r.set.isWarmup) continue;
      // Count any performed set (including load-free bodyweight/timed work);
      // volume stays 0 for those but the set still credits the muscle.
      if (!setHasWork(r.set)) continue;
      final vol = setVolume(r.set);
      final date = r.session.date;

      // Credit the primary mover a full set and each distinct secondary mover a
      // half set; volume is split the same way so a muscle's volume stat tracks
      // its set credit.
      final primary = r.exercise.primaryMuscle ?? 'other';
      final credit = <String, double>{primary: 1.0};
      for (final sec in secondaryMusclesOf(r.exercise.secondaryMuscles)) {
        if (sec == primary) continue;
        credit[sec] = (credit[sec] ?? 0) + kSecondarySetCredit;
      }

      for (final entry in credit.entries) {
        final muscle = entry.key;
        final c = entry.value;
        final cur = agg[muscle];
        final lastSoFar = cur?.last;
        agg[muscle] = (
          vol: (cur?.vol ?? 0) + vol * c,
          sets: (cur?.sets ?? 0) + c,
          last: lastSoFar == null || date.compareTo(lastSoFar) > 0
              ? date
              : lastSoFar,
        );
        final exMap = perEx.putIfAbsent(muscle, () => {});
        final exCur = exMap[r.exercise.name];
        exMap[r.exercise.name] = (
          vol: (exCur?.vol ?? 0) + vol * c,
          sets: (exCur?.sets ?? 0) + c,
        );
      }
    }

    final out = <String, MuscleBreakdown>{};
    for (final entry in agg.entries) {
      final exercises = perEx[entry.key]!
          .entries
          .map((e) => MuscleExerciseShare(
                name: e.key,
                volume: e.value.vol,
                sets: e.value.sets,
              ))
          .toList()
        ..sort((a, b) => b.volume.compareTo(a.volume));
      out[entry.key] = MuscleBreakdown(
        muscle: entry.key,
        volume: entry.value.vol,
        sets: entry.value.sets,
        lastTrained: entry.value.last,
        exercises: exercises,
      );
    }
    return out;
  }

  /// Consistency over the trailing [weeks] weeks ending with [now]'s week:
  /// total completed sessions, average sessions/week, and the current streak of
  /// consecutive weeks (ending now) with at least one session.
  Future<ConsistencyStats> consistency({
    required DateTime now,
    int weeks = 8,
  }) async {
    final thisMonday = _weekStart(now);
    final windowStart = thisMonday.subtract(Duration(days: 7 * (weeks - 1)));
    final windowEnd = thisMonday.add(const Duration(days: 6));
    final sessions = await repo.completedSessionsInRange(
        _dateKey(windowStart), _dateKey(windowEnd));

    // Count sessions per week index (0 = current week, increasing into past).
    final perWeek = <int, int>{};
    for (final s in sessions) {
      final parsed = DateTime.tryParse(s.date);
      if (parsed == null) continue;
      final sessMonday = _weekStart(parsed);
      final idx = thisMonday.difference(sessMonday).inDays ~/ 7;
      if (idx < 0 || idx >= weeks) continue;
      perWeek[idx] = (perWeek[idx] ?? 0) + 1;
    }

    var streak = 0;
    for (var i = 0; i < weeks; i++) {
      if ((perWeek[i] ?? 0) > 0) {
        streak++;
      } else {
        break;
      }
    }

    return ConsistencyStats(
      totalSessions: sessions.length,
      weeks: weeks,
      currentStreakWeeks: streak,
    );
  }

  /// Per-session cardio series for [exerciseId]: distance, duration, and derived
  /// pace, one point per session (date ascending). Sets within a session are
  /// summed for distance/duration.
  Future<List<CardioPoint>> cardioSeries(int exerciseId) async {
    final rows = await repo.setsForExercise(exerciseId);
    final order = <int>[];
    final bySession = <int, List<SetWithSession>>{};
    for (final r in rows) {
      final sid = r.session.id;
      if (!bySession.containsKey(sid)) {
        bySession[sid] = [];
        order.add(sid);
      }
      bySession[sid]!.add(r);
    }

    final points = <CardioPoint>[];
    for (final sid in order) {
      final sets = bySession[sid]!;
      double? dist;
      int? dur;
      for (final r in sets) {
        final d = r.set.distanceM;
        final t = r.set.durationSec;
        if (d != null) dist = (dist ?? 0) + d;
        if (t != null) dur = (dur ?? 0) + t;
      }
      points.add(CardioPoint(
        date: sets.first.session.date,
        distanceM: dist,
        durationSec: dur,
      ));
    }
    return points;
  }
}
