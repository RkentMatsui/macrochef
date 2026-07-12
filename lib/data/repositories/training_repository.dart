import 'package:drift/drift.dart';
import '../database.dart';

/// The single DB gateway for all training tables. UI and services never touch
/// the database directly — they go through this repository.
class TrainingRepository {
  final AppDatabase db;
  TrainingRepository(this.db);

  // ---- Exercises ----------------------------------------------------------

  Future<List<Exercise>> allExercises() {
    return (db.select(db.exercises)
          ..orderBy([(e) => OrderingTerm.asc(e.name)]))
        .get();
  }

  Future<Exercise?> exerciseBySlug(String slug) {
    return (db.select(db.exercises)..where((e) => e.slug.equals(slug)))
        .getSingleOrNull();
  }

  Future<Exercise?> exerciseById(int id) {
    return (db.select(db.exercises)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertExercise(ExercisesCompanion exercise) {
    return db.into(db.exercises).insert(exercise);
  }

  /// Overwrite the editable fields of exercise [id] with [data]. Used by the
  /// exercise editor; only user-facing columns should be present in [data].
  Future<void> updateExercise(int id, ExercisesCompanion data) async {
    await (db.update(db.exercises)..where((e) => e.id.equals(id))).write(data);
  }

  /// Insert an editable custom copy of [source] (slug cleared, `isCustom` true).
  /// Named `"<name> (custom)"` so it doesn't collide with the built-in on the
  /// startup name-dedupe (which would otherwise fold the copy back into the
  /// catalog row). Lets a user tweak a built-in's muscles/metrics on their own
  /// copy, since built-ins are re-seeded on launch. Returns the new id.
  Future<int> duplicateAsCustom(Exercise source) {
    return insertExercise(ExercisesCompanion.insert(
      name: '${source.name} (custom)',
      category: source.category,
      primaryMuscle: Value(source.primaryMuscle),
      secondaryMuscles: Value(source.secondaryMuscles),
      equipment: Value(source.equipment),
      description: Value(source.description),
      tracksWeight: Value(source.tracksWeight),
      tracksReps: Value(source.tracksReps),
      tracksDuration: Value(source.tracksDuration),
      tracksDistance: Value(source.tracksDistance),
      isCustom: const Value(true),
    ));
  }

  /// How many logged sets and program-day rows reference exercise [id]. Callers
  /// use this to block deleting an exercise that history/programs depend on.
  Future<({int sets, int templates})> exerciseUsage(int id) async {
    final sets = await (db.select(db.setEntries)
          ..where((s) => s.exerciseId.equals(id)))
        .get();
    final templates = await (db.select(db.templateExercises)
          ..where((t) => t.exerciseId.equals(id)))
        .get();
    return (sets: sets.length, templates: templates.length);
  }

  /// Delete exercise [id]. Returns false without deleting when the exercise is
  /// still referenced by any logged set or program day (so history/programs
  /// aren't orphaned); returns true once it's removed.
  Future<bool> deleteExercise(int id) async {
    final usage = await exerciseUsage(id);
    if (usage.sets > 0 || usage.templates > 0) return false;
    await (db.delete(db.exercises)..where((e) => e.id.equals(id))).go();
    return true;
  }

  /// First exercise whose normalized name equals [name] (case-insensitive).
  Future<Exercise?> exerciseByName(String name) {
    return (db.select(db.exercises)
          ..where((e) => e.name.lower().equals(name.trim().toLowerCase()))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Upgrades a user's custom exercise [id] into a built-in by writing [data]
  /// (a companion built from the catalog seed, with `isCustom: false`). Lets a
  /// same-named custom row merge into the catalog instead of duplicating.
  Future<void> adoptCustomAsBuiltIn(int id, ExercisesCompanion data) async {
    await (db.update(db.exercises)..where((e) => e.id.equals(id))).write(data);
  }

  /// Removes duplicate exercises that share a normalized (lowercased/trimmed)
  /// name, keeping the "best" row: prefer a built-in (slug != null), then the
  /// one with a primaryMuscle, then the lowest id. Re-points any SetEntries and
  /// TemplateExercises from removed rows to the surviving row so history and
  /// programs are preserved. Returns the number of rows removed.
  Future<int> dedupeExercisesByName() async {
    return db.transaction(() async {
      final all = await (db.select(db.exercises)
            ..orderBy([(e) => OrderingTerm.asc(e.id)]))
          .get();
      final groups = <String, List<Exercise>>{};
      for (final e in all) {
        groups.putIfAbsent(e.name.trim().toLowerCase(), () => []).add(e);
      }
      var removed = 0;
      for (final group in groups.values) {
        if (group.length < 2) continue;
        group.sort((a, b) {
          final aSlug = a.slug != null ? 0 : 1;
          final bSlug = b.slug != null ? 0 : 1;
          if (aSlug != bSlug) return aSlug - bSlug;
          final aMus = a.primaryMuscle != null ? 0 : 1;
          final bMus = b.primaryMuscle != null ? 0 : 1;
          if (aMus != bMus) return aMus - bMus;
          return a.id - b.id;
        });
        final keep = group.first;
        for (final dup in group.skip(1)) {
          await (db.update(db.setEntries)
                ..where((s) => s.exerciseId.equals(dup.id)))
              .write(SetEntriesCompanion(exerciseId: Value(keep.id)));
          await (db.update(db.templateExercises)
                ..where((t) => t.exerciseId.equals(dup.id)))
              .write(TemplateExercisesCompanion(exerciseId: Value(keep.id)));
          await (db.delete(db.exercises)..where((e) => e.id.equals(dup.id)))
              .go();
          removed++;
        }
      }
      return removed;
    });
  }

  /// Updates only the how-to [description] of an exercise (used to backfill
  /// descriptions onto already-seeded built-ins).
  Future<void> updateExerciseDescription(int id, String? description) {
    return (db.update(db.exercises)..where((e) => e.id.equals(id)))
        .write(ExercisesCompanion(description: Value(description)));
  }

  /// Updates only the comma-separated [secondaryMuscles] of an exercise (used
  /// to backfill synergist data onto already-seeded built-ins).
  Future<void> updateExerciseSecondaryMuscles(int id, String? secondaryMuscles) {
    return (db.update(db.exercises)..where((e) => e.id.equals(id)))
        .write(ExercisesCompanion(secondaryMuscles: Value(secondaryMuscles)));
  }

  /// Updates only the [primaryMuscle] of an exercise (used to backfill a
  /// re-pointed muscle onto a built-in that was seeded before the catalog
  /// moved it — e.g. hip-adduction quads→adductors).
  Future<void> updateExercisePrimaryMuscle(int id, String? primaryMuscle) {
    return (db.update(db.exercises)..where((e) => e.id.equals(id)))
        .write(ExercisesCompanion(primaryMuscle: Value(primaryMuscle)));
  }

  // ---- Sessions -----------------------------------------------------------

  Future<int> startSession({
    required String date,
    String? name,
    int? dayId,
  }) {
    return db.into(db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            date: date,
            name: name ?? 'Workout',
            dayId: Value(dayId),
            startedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> finishSession(
    int id, {
    int? durationSec,
    int? perceivedEffort,
    String? notes,
  }) async {
    await (db.update(db.workoutSessions)..where((s) => s.id.equals(id))).write(
      WorkoutSessionsCompanion(
        completedAt: Value(DateTime.now()),
        durationSec: Value(durationSec),
        perceivedEffort: Value(perceivedEffort),
        notes: Value(notes),
      ),
    );
  }

  /// Delete a session and all of its logged sets in one transaction.
  Future<void> deleteSession(int id) async {
    await db.transaction(() async {
      await (db.delete(db.setEntries)..where((s) => s.sessionId.equals(id)))
          .go();
      await (db.delete(db.workoutSessions)..where((s) => s.id.equals(id))).go();
    });
  }

  Future<WorkoutSession?> sessionById(int id) {
    return (db.select(db.workoutSessions)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<WorkoutSession>> recentSessions({int limit = 20}) {
    return (db.select(db.workoutSessions)
          ..orderBy([(s) => OrderingTerm.desc(s.date)])
          ..orderBy([(s) => OrderingTerm.desc(s.id)])
          ..limit(limit))
        .get();
  }

  Stream<List<WorkoutSession>> watchSessions() {
    return (db.select(db.workoutSessions)
          ..orderBy([(s) => OrderingTerm.desc(s.date)])
          ..orderBy([(s) => OrderingTerm.desc(s.id)]))
        .watch();
  }

  // ---- Sets ---------------------------------------------------------------

  Future<int> addSet(SetEntriesCompanion entry) {
    return db.into(db.setEntries).insert(entry);
  }

  Future<void> updateSet(int id, SetEntriesCompanion entry) async {
    await (db.update(db.setEntries)..where((s) => s.id.equals(id))).write(entry);
  }

  Future<void> deleteSet(int id) async {
    await (db.delete(db.setEntries)..where((s) => s.id.equals(id))).go();
  }

  Future<List<SetEntry>> setsForSession(int sessionId) {
    return (db.select(db.setEntries)
          ..where((s) => s.sessionId.equals(sessionId))
          ..orderBy([
            (s) => OrderingTerm.asc(s.position),
            (s) => OrderingTerm.asc(s.setIndex),
          ]))
        .get();
  }

  /// Every completed set logged for [exerciseId] across all sessions, joined
  /// with its session so the session date is available. Only *checked-off* sets
  /// (`completed == true`) on completed sessions are returned, so seeded-but-
  /// unperformed prescriptions and auto-added pending rows don't pollute
  /// history, ordered by session date then set order. Used by progression
  /// analytics.
  Future<List<SetWithSession>> setsForExercise(int exerciseId) async {
    final query = db.select(db.setEntries).join([
      innerJoin(
        db.workoutSessions,
        db.workoutSessions.id.equalsExp(db.setEntries.sessionId),
      ),
    ])
      ..where(db.setEntries.exerciseId.equals(exerciseId) &
          db.setEntries.completed.equals(true) &
          db.workoutSessions.completedAt.isNotNull())
      ..orderBy([
        OrderingTerm.asc(db.workoutSessions.date),
        OrderingTerm.asc(db.setEntries.position),
        OrderingTerm.asc(db.setEntries.setIndex),
      ]);
    final rows = await query.get();
    return rows
        .map((r) => SetWithSession(
              set: r.readTable(db.setEntries),
              session: r.readTable(db.workoutSessions),
            ))
        .toList();
  }

  /// All sets from the most recent COMPLETED session that included [exerciseId],
  /// ordered by setIndex. Used to show a per-set "last time" reference in the
  /// logger so the lifter can chase progressive overload. Empty if never done.
  Future<List<SetEntry>> previousSessionSetsFor(int exerciseId) async {
    final rows = await setsForExercise(exerciseId); // completed sessions, asc
    if (rows.isEmpty) return [];
    final lastSessionId = rows.last.session.id; // latest date sorts last
    final sets = rows
        .where((r) => r.session.id == lastSessionId)
        .map((r) => r.set)
        .toList()
      ..sort((a, b) => a.setIndex.compareTo(b.setIndex));
    return sets;
  }

  /// The most recent checked-off working (non-warmup) set logged for
  /// [exerciseId] on a completed session. Used to pre-fill weight/reps when the
  /// lifter performs the exercise again, so they don't re-enter the same
  /// numbers. Null if the exercise has never been performed before.
  Future<SetEntry?> lastSetFor(int exerciseId) async {
    final query = db.select(db.setEntries).join([
      innerJoin(
        db.workoutSessions,
        db.workoutSessions.id.equalsExp(db.setEntries.sessionId),
      ),
    ])
      ..where(db.setEntries.exerciseId.equals(exerciseId) &
          db.setEntries.completed.equals(true) &
          db.workoutSessions.completedAt.isNotNull() &
          db.setEntries.isWarmup.equals(false))
      ..orderBy([
        OrderingTerm.desc(db.workoutSessions.date),
        OrderingTerm.desc(db.setEntries.position),
        OrderingTerm.desc(db.setEntries.setIndex),
      ])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.readTable(db.setEntries);
  }

  /// Every completed set in the inclusive date range, joined with its exercise
  /// (for `primaryMuscle`/category) and session (for date). Used for weekly
  /// volume-by-muscle aggregation.
  Future<List<SetWithExercise>> completedSetsInRange(
    String startDate,
    String endDate,
  ) async {
    final query = db.select(db.setEntries).join([
      innerJoin(
        db.workoutSessions,
        db.workoutSessions.id.equalsExp(db.setEntries.sessionId),
      ),
      innerJoin(
        db.exercises,
        db.exercises.id.equalsExp(db.setEntries.exerciseId),
      ),
    ])
      ..where(db.workoutSessions.completedAt.isNotNull() &
          db.setEntries.completed.equals(true) &
          db.workoutSessions.date.isBiggerOrEqualValue(startDate) &
          db.workoutSessions.date.isSmallerOrEqualValue(endDate));
    final rows = await query.get();
    return rows
        .map((r) => SetWithExercise(
              set: r.readTable(db.setEntries),
              exercise: r.readTable(db.exercises),
              session: r.readTable(db.workoutSessions),
            ))
        .toList();
  }

  // ---- Programs (WorkoutTemplates) ---------------------------------------

  Future<List<WorkoutTemplate>> allPrograms() {
    return (db.select(db.workoutTemplates)
          ..orderBy([
            (t) => OrderingTerm.asc(t.position),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<WorkoutTemplate?> programById(int id) {
    return (db.select(db.workoutTemplates)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> createProgram({
    required String name,
    String? notes,
    int position = 0,
  }) {
    return db.into(db.workoutTemplates).insert(
          WorkoutTemplatesCompanion.insert(
            name: name,
            notes: Value(notes),
            position: Value(position),
          ),
        );
  }

  Future<void> updateProgram(
    int id, {
    String? name,
    String? notes,
    int? position,
  }) async {
    await (db.update(db.workoutTemplates)..where((t) => t.id.equals(id))).write(
      WorkoutTemplatesCompanion(
        name: name == null ? const Value.absent() : Value(name),
        notes: Value(notes),
        position: position == null ? const Value.absent() : Value(position),
      ),
    );
  }

  /// Persist a new program ordering: writes `position = index` for each id in
  /// [orderedIds], in one transaction.
  Future<void> reorderPrograms(List<int> orderedIds) async {
    await db.transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (db.update(db.workoutTemplates)
              ..where((t) => t.id.equals(orderedIds[i])))
            .write(WorkoutTemplatesCompanion(position: Value(i)));
      }
    });
  }

  /// Delete a program and all of its days, those days' exercises, and any
  /// schedule entries referencing those days, in one transaction.
  Future<void> deleteProgram(int id) async {
    await db.transaction(() async {
      final days = await (db.select(db.templateDays)
            ..where((d) => d.templateId.equals(id)))
          .get();
      for (final day in days) {
        await (db.delete(db.templateExercises)
              ..where((te) => te.dayId.equals(day.id)))
            .go();
        await (db.delete(db.scheduleEntries)
              ..where((s) => s.dayId.equals(day.id)))
            .go();
      }
      await (db.delete(db.templateDays)..where((d) => d.templateId.equals(id)))
          .go();
      await (db.delete(db.workoutTemplates)..where((t) => t.id.equals(id)))
          .go();
    });
  }

  // ---- Days (TemplateDays) ------------------------------------------------

  Future<List<TemplateDay>> daysForProgram(int programId) {
    return (db.select(db.templateDays)
          ..where((d) => d.templateId.equals(programId))
          ..orderBy([
            (d) => OrderingTerm.asc(d.position),
            (d) => OrderingTerm.asc(d.id),
          ]))
        .get();
  }

  Future<TemplateDay?> dayById(int id) {
    return (db.select(db.templateDays)..where((d) => d.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> createDay({
    required int programId,
    required String name,
    int position = 0,
    String? notes,
  }) {
    return db.into(db.templateDays).insert(
          TemplateDaysCompanion.insert(
            templateId: programId,
            name: name,
            position: Value(position),
            notes: Value(notes),
          ),
        );
  }

  Future<void> updateDay(
    int id, {
    String? name,
    int? position,
    String? notes,
  }) async {
    await (db.update(db.templateDays)..where((d) => d.id.equals(id))).write(
      TemplateDaysCompanion(
        name: name == null ? const Value.absent() : Value(name),
        position: position == null ? const Value.absent() : Value(position),
        notes: Value(notes),
      ),
    );
  }

  /// Delete a day plus its exercises and any schedule entries referencing it.
  Future<void> deleteDay(int id) async {
    await db.transaction(() async {
      await (db.delete(db.templateExercises)..where((te) => te.dayId.equals(id)))
          .go();
      await (db.delete(db.scheduleEntries)..where((s) => s.dayId.equals(id)))
          .go();
      await (db.delete(db.templateDays)..where((d) => d.id.equals(id))).go();
    });
  }

  Future<List<TemplateExercise>> dayExercises(int dayId) {
    return (db.select(db.templateExercises)
          ..where((te) => te.dayId.equals(dayId))
          ..orderBy([(te) => OrderingTerm.asc(te.position)]))
        .get();
  }

  /// Replace the full ordered exercise prescription for [dayId] in one
  /// transaction (delete-then-insert). Each companion should omit `dayId` —
  /// it is set here from [dayId].
  Future<void> setDayExercises(
    int dayId,
    List<TemplateExercisesCompanion> exercises,
  ) async {
    await db.transaction(() async {
      await (db.delete(db.templateExercises)
            ..where((te) => te.dayId.equals(dayId)))
          .go();
      for (final ex in exercises) {
        await db.into(db.templateExercises).insert(
              ex.copyWith(dayId: Value(dayId)),
            );
      }
    });
  }

  // ---- Schedule -----------------------------------------------------------

  /// Replace the full set of days planned for [dayOfWeek] (0=Mon..6=Sun) in one
  /// transaction. An empty [dayIds] list clears the day (rest day).
  /// `position` is the index within [dayIds].
  Future<void> setScheduleForDay(
    int dayOfWeek,
    List<int> dayIds,
  ) async {
    await db.transaction(() async {
      await (db.delete(db.scheduleEntries)
            ..where((s) => s.dayOfWeek.equals(dayOfWeek)))
          .go();
      for (var i = 0; i < dayIds.length; i++) {
        await db.into(db.scheduleEntries).insert(
              ScheduleEntriesCompanion.insert(
                dayOfWeek: dayOfWeek,
                dayId: dayIds[i],
                position: Value(i),
              ),
            );
      }
    });
  }

  /// All schedule entries planned for [dayOfWeek] (0=Mon..6=Sun), ordered.
  Future<List<ScheduleEntry>> scheduleForDay(int dayOfWeek) {
    return (db.select(db.scheduleEntries)
          ..where((s) => s.dayOfWeek.equals(dayOfWeek))
          ..orderBy([(s) => OrderingTerm.asc(s.position)]))
        .get();
  }

  /// Every schedule entry across all days, ordered by day then position.
  Future<List<ScheduleEntry>> fullSchedule() {
    return (db.select(db.scheduleEntries)
          ..orderBy([
            (s) => OrderingTerm.asc(s.dayOfWeek),
            (s) => OrderingTerm.asc(s.position),
          ]))
        .get();
  }

  /// Completed sessions whose [WorkoutSessions.date] falls within the inclusive
  /// date range [startDate, endDate] (both YYYY-MM-DD). Used for adherence.
  Future<List<WorkoutSession>> completedSessionsInRange(
    String startDate,
    String endDate,
  ) {
    return (db.select(db.workoutSessions)
          ..where((s) =>
              s.completedAt.isNotNull() &
              s.date.isBiggerOrEqualValue(startDate) &
              s.date.isSmallerOrEqualValue(endDate))
          ..orderBy([(s) => OrderingTerm.asc(s.date)]))
        .get();
  }
}

/// A logged set paired with its parent session (carrying the session date).
class SetWithSession {
  final SetEntry set;
  final WorkoutSession session;
  const SetWithSession({required this.set, required this.session});
}

/// A logged set paired with its exercise (capability flags / muscle) and its
/// parent session (date).
class SetWithExercise {
  final SetEntry set;
  final Exercise exercise;
  final WorkoutSession session;
  const SetWithExercise({
    required this.set,
    required this.exercise,
    required this.session,
  });
}
