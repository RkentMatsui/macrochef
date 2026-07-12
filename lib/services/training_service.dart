import 'package:drift/drift.dart' show Value;

import '../data/database.dart';
import '../data/repositories/training_repository.dart';

const double _kgPerLb = 0.45359237;

/// Settings key for the default rest-timer length (seconds, stored as a string).
/// Used when a voice "rest" command carries no explicit number.
const kTrainingRestSecKey = 'training_default_rest_sec';
const kDefaultRestSec = 90;

/// Pure-Dart orchestration over [TrainingRepository] for the live session
/// lifecycle. No Flutter imports. Storage is canonical (kg, metres, seconds);
/// the unit the user typed is persisted per set so it round-trips exactly.
class TrainingService {
  final TrainingRepository repo;
  TrainingService(this.repo);

  /// Convert a user-entered weight value to canonical kilograms. 'kg' (or any
  /// non-'lb' unit) passes through; 'lb' is multiplied by the conversion factor.
  static double toKg(double value, String unit) {
    return unit == 'lb' ? value * _kgPerLb : value;
  }

  /// Start a fresh ad-hoc session for [date] (YYYY-MM-DD). Returns the new id.
  Future<int> startEmptySession(String date, {String? name}) {
    return repo.startSession(date: date, name: name);
  }

  /// Start a session pre-filled from a program day. Creates a session with
  /// `dayId` set, then seeds one incomplete [SetEntries] row per prescribed
  /// target set (`completed:false`). Each set is pre-filled from the last time
  /// the exercise was actually performed (its checked-off sets on the most
  /// recent completed session), so re-doing a day opens with the lifter's real
  /// numbers; when there's no history it falls back to the day's prescription
  /// (target load/reps/duration/distance). The session name is "Program · Day".
  /// Returns the new session id.
  Future<int> startFromDay(int dayId, String date) async {
    final day = await repo.dayById(dayId);
    final prescription = await repo.dayExercises(dayId);
    var name = day?.name ?? 'Workout';
    if (day != null) {
      final program = await repo.programById(day.templateId);
      if (program != null) name = '${program.name} · ${day.name}';
    }
    final sessionId = await repo.startSession(
      date: date,
      name: name,
      dayId: dayId,
    );
    for (var position = 0; position < prescription.length; position++) {
      final te = prescription[position];
      final sets = (te.targetSets ?? 1) < 1 ? 1 : (te.targetSets ?? 1);
      // Last performed sets for this exercise, indexed by set position. When the
      // lifter did more sets last time than prescribed we ignore the extras;
      // when they did fewer, later sets reuse the last performed one.
      final previous = await repo.previousSessionSetsFor(te.exerciseId);
      final targetReps = int.tryParse((te.targetReps ?? '').trim());
      for (var setIndex = 0; setIndex < sets; setIndex++) {
        final prev = setIndex < previous.length
            ? previous[setIndex]
            : (previous.isNotEmpty ? previous.last : null);
        await repo.addSet(SetEntriesCompanion.insert(
          sessionId: sessionId,
          exerciseId: te.exerciseId,
          position: position,
          setIndex: setIndex,
          reps: Value(prev?.reps ?? targetReps),
          weightKg: Value(prev?.weightKg ?? te.targetWeightKg),
          durationSec: Value(prev?.durationSec ?? te.targetDurationSec),
          distanceM: Value(prev?.distanceM ?? te.targetDistanceM),
          enteredUnit: Value(prev?.enteredUnit),
          completed: const Value(false),
        ));
      }
    }
    return sessionId;
  }

  /// Log a single set. [weightKg] is interpreted as already-canonical kg unless
  /// [enteredUnit] == 'lb', in which case it is converted before storage and the
  /// entered unit is recorded for exact round-trip.
  Future<int> logSet({
    required int sessionId,
    required int exerciseId,
    required int position,
    required int setIndex,
    int? reps,
    double? weightKg,
    int? durationSec,
    double? distanceM,
    double? rpe,
    String? enteredUnit,
    bool isWarmup = false,
    bool completed = true,
  }) {
    double? storedWeight = weightKg;
    if (storedWeight != null && enteredUnit == 'lb') {
      storedWeight = toKg(storedWeight, 'lb');
    }
    return repo.addSet(SetEntriesCompanion.insert(
      sessionId: sessionId,
      exerciseId: exerciseId,
      position: position,
      setIndex: setIndex,
      reps: Value(reps),
      weightKg: Value(storedWeight),
      durationSec: Value(durationSec),
      distanceM: Value(distanceM),
      rpe: Value(rpe),
      enteredUnit: Value(enteredUnit),
      isWarmup: Value(isWarmup),
      completed: Value(completed),
    ));
  }

  /// Finish a session: compute [durationSec] from the session's startedAt → now
  /// (unless the caller passed an explicit value) and stamp completedAt.
  Future<void> finishSession(
    int sessionId, {
    int? perceivedEffort,
    String? notes,
    int? durationSec,
  }) async {
    var computed = durationSec;
    if (computed == null) {
      final session = await repo.sessionById(sessionId);
      final startedAt = session?.startedAt;
      if (startedAt != null) {
        computed = DateTime.now().difference(startedAt).inSeconds;
        if (computed < 0) computed = 0;
      }
    }
    await repo.finishSession(
      sessionId,
      durationSec: computed,
      perceivedEffort: perceivedEffort,
      notes: notes,
    );
  }
}
