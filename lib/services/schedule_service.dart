import '../data/database.dart';
import '../data/repositories/training_repository.dart';

/// One planned slot for a date: which program day is scheduled, plus the
/// owning program's name for display ("Program · Day").
class PlannedSession {
  final ScheduleEntry entry;
  final TemplateDay day;
  final String programName;
  const PlannedSession({
    required this.entry,
    required this.day,
    required this.programName,
  });

  int get dayOfWeek => entry.dayOfWeek;
  int get dayId => day.id;
  String get name => '$programName · ${day.name}';
}

/// Planned-vs-actual consistency for a single week.
class WeekAdherence {
  /// Number of planned sessions across the 7 days of the week.
  final int planned;

  /// Number of those planned sessions that have a matching completed session
  /// on the same weekday.
  final int completed;

  const WeekAdherence({required this.planned, required this.completed});

  /// Fraction in 0..1 of planned sessions that were completed. Zero planned
  /// sessions yields 0.0 (nothing to adhere to). Mirrors the calorie
  /// adherence-ring fraction pattern (completed / planned, clamped).
  double get fraction {
    if (planned <= 0) return 0.0;
    return (completed / planned).clamp(0.0, 1.0);
  }
}

/// Pure-Dart logic mapping the weekly schedule onto concrete dates and computing
/// planned-vs-actual training consistency. No Flutter imports; all DB access is
/// via [TrainingRepository].
class ScheduleService {
  final TrainingRepository repo;
  ScheduleService(this.repo);

  /// Convert a [DateTime] to the schedule's day index: 0=Mon..6=Sun.
  static int dayIndexOf(DateTime date) => date.weekday - 1;

  /// Format a [DateTime] as YYYY-MM-DD (date-only, local).
  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// The Monday (00:00) of the week containing [date].
  static DateTime weekStartOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: dayIndexOf(d)));
  }

  /// Program days planned for the weekday of [date], in schedule order. Empty
  /// list means a rest day.
  Future<List<PlannedSession>> plannedForDate(DateTime date) async {
    final entries = await repo.scheduleForDay(dayIndexOf(date));
    final result = <PlannedSession>[];
    for (final entry in entries) {
      final day = await repo.dayById(entry.dayId);
      if (day == null) continue;
      final program = await repo.programById(day.templateId);
      result.add(PlannedSession(
        entry: entry,
        day: day,
        programName: program?.name ?? 'Program',
      ));
    }
    return result;
  }

  /// Planned-vs-actual consistency for the week starting at [weekStart]
  /// (normalized to that week's Monday). For each of the 7 days, counts planned
  /// sessions and how many were satisfied by a completed session on that day.
  /// A single completed session on a day satisfies one planned slot; extra
  /// completed sessions beyond the planned count are not counted (capped at the
  /// planned count per day).
  Future<WeekAdherence> adherenceForWeek(DateTime weekStart) async {
    final monday = weekStartOf(weekStart);
    final sunday = monday.add(const Duration(days: 6));
    final completedSessions =
        await repo.completedSessionsInRange(dateKey(monday), dateKey(sunday));

    // completed-session count per weekday index
    final completedByDay = <int, int>{};
    for (final s in completedSessions) {
      final parsed = DateTime.tryParse(s.date);
      if (parsed == null) continue;
      final idx = dayIndexOf(parsed);
      completedByDay[idx] = (completedByDay[idx] ?? 0) + 1;
    }

    var planned = 0;
    var completed = 0;
    for (var day = 0; day < 7; day++) {
      final dayPlanned = (await repo.scheduleForDay(day)).length;
      if (dayPlanned == 0) continue;
      planned += dayPlanned;
      final dayCompleted = completedByDay[day] ?? 0;
      completed += dayCompleted > dayPlanned ? dayPlanned : dayCompleted;
    }

    return WeekAdherence(planned: planned, completed: completed);
  }
}
