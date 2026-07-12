enum WorkoutIntentType {
  nextExercise,
  prevExercise,
  repeatExercise,
  currentExercise,
  selectExercise, // ad-hoc: "start bench press"
  setMetrics,     // carries any of reps/weight/unit/durationSec/distanceM/rpe
  commitSet,      // "done" / "next set" / "log it" / plain "next"
  progressQuery,  // "how many sets left", "what set am I on"
  targetQuery,    // "what's the target"
  lastTime,       // last-time coaching
  startRest,      // carries seconds
  finishWorkout,
  exit,           // pause/quit without finishing
  unknown,        // -> LLM Q&A fallback
}

/// One parsed voice command. A single utterance may set several metric fields
/// at once ("6 reps at 80 kilos" -> reps=6, weight=80, unit='kg').
class WorkoutIntent {
  final WorkoutIntentType type;
  final String? exerciseName; // selectExercise
  final int? reps;
  final double? weight; // in [unit]; null unit defaults to 'kg' downstream
  final String? unit; // 'kg' | 'lb'
  final int? durationSec;
  final double? distanceM;
  final double? rpe;
  final int? seconds; // startRest

  const WorkoutIntent(
    this.type, {
    this.exerciseName,
    this.reps,
    this.weight,
    this.unit,
    this.durationSec,
    this.distanceM,
    this.rpe,
    this.seconds,
  });
}
