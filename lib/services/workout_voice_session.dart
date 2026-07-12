import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../data/repositories/training_repository.dart';
import '../models/chat.dart';
import '../models/workout_intent.dart';
import '../providers/llm/llm_provider.dart';
import '../providers/speech/speech_provider.dart';
import 'cooking_session.dart' show SessionState;
import 'training_service.dart';
import 'workout_intent_parser.dart';

/// One item in the workout script: the exercise and (when running a program
/// day) its prescription. `position` equals the item's index in the script.
class ScriptItem {
  final Exercise exercise;
  final TemplateExercise? prescription;
  const ScriptItem(this.exercise, this.prescription);
}

/// Mutable draft of the set currently being dictated. Plain Dart (no Flutter)
/// so it can live in the service layer. Weight is in [unit]; storage converts.
class DraftSet {
  int? reps;
  double? weight;
  String unit;
  int? durationSec;
  double? distanceM;
  double? rpe;

  DraftSet({this.unit = 'kg'});

  bool get isEmpty =>
      reps == null &&
      weight == null &&
      durationSec == null &&
      distanceM == null &&
      rpe == null;

  DraftSet copy() => DraftSet(unit: unit)
    ..reps = reps
    ..weight = weight
    ..durationSec = durationSec
    ..distanceM = distanceM
    ..rpe = rpe;
}

/// Hands-free workout state machine. Mirrors [CookingSession]: the UI owns the
/// listen loop and animates off [state]; this class never calls `listen`.
class WorkoutVoiceSession {
  final int sessionId;
  final int? dayId;
  final TrainingService training;
  final TrainingRepository repo;
  final SpeechProvider speech;
  final WorkoutIntentParser parser;
  final LLMProvider? llm;

  /// Unit new draft sets default to ('kg'|'lb') — the user's training default.
  final String defaultUnit;

  /// Seconds used for a "rest" command that carries no explicit number.
  final int defaultRestSec;

  /// Optional hooks so the UI can mirror rest alerts to a background
  /// notification (sound + vibration) that fires even if the app is suspended.
  /// [onRestScheduled] fires when a rest starts (with its length);
  /// [onRestCancelled] fires when the rest is consumed, cancelled, or the
  /// session ends, so the pending notification can be dropped.
  final void Function(Duration after)? onRestScheduled;
  final void Function()? onRestCancelled;

  late final ValueNotifier<SessionState> state;
  late final ValueNotifier<int> exerciseIndex;
  late final ValueNotifier<DraftSet> draft;

  final List<ScriptItem> _script = [];
  Timer? _rest;
  int? pendingRestSeconds; // last requested rest length (for the UI/tests)
  bool _awaitingEffort = false;
  bool exited = false;
  bool _disposed = false;

  WorkoutVoiceSession({
    required this.sessionId,
    required this.dayId,
    required this.training,
    required this.repo,
    required this.speech,
    required this.parser,
    this.llm,
    this.defaultUnit = 'kg',
    this.defaultRestSec = kDefaultRestSec,
    this.onRestScheduled,
    this.onRestCancelled,
  }) {
    state = ValueNotifier(SessionState.idle);
    exerciseIndex = ValueNotifier(0);
    draft = ValueNotifier(DraftSet(unit: defaultUnit));
  }

  /// A fresh empty draft carrying the user's default unit.
  DraftSet _newDraft() => DraftSet(unit: defaultUnit);

  int get scriptLength => _script.length;
  String? get currentExerciseName => _current?.exercise.name;
  String get draftSummary => _draftPhrase(draft.value);
  ScriptItem? get _current =>
      (exerciseIndex.value >= 0 && exerciseIndex.value < _script.length)
          ? _script[exerciseIndex.value]
          : null;

  /// Load the script. For a program day, join the prescription with its
  /// exercises (ordered). Ad-hoc sessions start with an empty script.
  Future<void> init() async {
    _script.clear();
    if (dayId != null) {
      final prescription = await repo.dayExercises(dayId!);
      for (final te in prescription) {
        final ex = await repo.exerciseById(te.exerciseId);
        if (ex != null) _script.add(ScriptItem(ex, te));
      }
    }
  }

  /// Announce the first exercise once (called by the screen after init).
  Future<void> begin() async {
    if (_script.isEmpty) {
      await _speak(
          'Empty workout. Say "start" and an exercise name to begin.');
      return;
    }
    await _announceCurrent();
  }

  Future<void> handleUtterance(String text) async {
    if (_awaitingEffort) {
      await _handleEffort(text);
      return;
    }
    state.value = SessionState.understanding;
    final intent = await parser.parse(text);

    switch (intent.type) {
      case WorkoutIntentType.currentExercise:
        await _announceCurrent();
        break;
      case WorkoutIntentType.repeatExercise:
        await _announceCurrent();
        break;
      case WorkoutIntentType.nextExercise:
        if (exerciseIndex.value < _script.length - 1) {
          exerciseIndex.value++;
          draft.value = _newDraft();
        }
        await _announceCurrent();
        break;
      case WorkoutIntentType.prevExercise:
        if (exerciseIndex.value > 0) {
          exerciseIndex.value--;
          draft.value = _newDraft();
        }
        await _announceCurrent();
        break;
      case WorkoutIntentType.selectExercise:
        await _handleSelect(intent);
        break;
      case WorkoutIntentType.setMetrics:
        await _handleMetrics(intent);
        break;
      case WorkoutIntentType.commitSet:
        await _handleCommit();
        break;
      case WorkoutIntentType.progressQuery:
        await _handleProgress();
        break;
      case WorkoutIntentType.targetQuery:
        await _announceCurrent();
        break;
      case WorkoutIntentType.lastTime:
        await _handleLastTime();
        break;
      case WorkoutIntentType.startRest:
        await _handleRest(intent);
        break;
      case WorkoutIntentType.finishWorkout:
        _awaitingEffort = true;
        await _speak('Nice work. How hard was that, 1 to 10? Or say skip.');
        break;
      case WorkoutIntentType.exit:
        exited = true;
        _rest?.cancel();
        onRestCancelled?.call();
        state.value = SessionState.idle;
        await speech.speak('Workout paused. See you next time.');
        break;
      case WorkoutIntentType.unknown:
        await _handleConversation(text);
        break;
    }
  }

  // ---- announcements ----------------------------------------------------

  Future<void> _announceCurrent() async {
    final item = _current;
    if (item == null) {
      await _speak('No exercise selected.');
      return;
    }
    final target = _targetPhrase(item);
    await _speak(
        '${item.exercise.name}.${target.isEmpty ? '' : ' $target'}');
  }

  /// A spoken target phrase from the prescription, gated by capability flags.
  String _targetPhrase(ScriptItem item) {
    final te = item.prescription;
    if (te == null) return '';
    final ex = item.exercise;
    final parts = <String>[];
    if (te.targetSets != null) parts.add('${te.targetSets} sets');
    if (ex.tracksReps && te.targetReps != null) {
      parts.add('of ${te.targetReps} reps');
    }
    if (ex.tracksWeight && te.targetWeightKg != null) {
      parts.add('at ${_fmt(te.targetWeightKg!)} kg');
    }
    if (ex.tracksDuration && te.targetDurationSec != null) {
      parts.add('for ${(te.targetDurationSec! / 60).round()} min');
    }
    if (ex.tracksDistance && te.targetDistanceM != null) {
      parts.add('${_fmt(te.targetDistanceM! / 1000)} km');
    }
    return parts.isEmpty ? '' : 'Target ${parts.join(' ')}.';
  }

  // ---- draft + commit ---------------------------------------------------

  Future<void> _handleSelect(WorkoutIntent intent) async {
    final query = intent.exerciseName?.trim().toLowerCase();
    if (query == null || query.isEmpty) {
      await _speak('Which exercise?');
      return;
    }
    final all = await repo.allExercises();
    Exercise? match;
    for (final e in all) {
      if (e.name.toLowerCase() == query) {
        match = e;
        break;
      }
    }
    match ??= all.cast<Exercise?>().firstWhere(
          (e) => e!.name.toLowerCase().contains(query),
          orElse: () => null,
        );
    if (match == null) {
      await _speak("I don't know an exercise called $query.");
      return;
    }
    _script.add(ScriptItem(match, null));
    exerciseIndex.value = _script.length - 1;
    draft.value = DraftSet();
    await _announceCurrent();
  }

  Future<void> _handleMetrics(WorkoutIntent intent) async {
    final item = _current;
    if (item == null) {
      await _speak('Pick an exercise first.');
      return;
    }
    final ex = item.exercise;
    final d = draft.value.copy();
    final ignored = <String>[];

    if (intent.reps != null) {
      if (ex.tracksReps) {
        d.reps = intent.reps;
      } else {
        ignored.add('reps');
      }
    }
    if (intent.weight != null) {
      if (ex.tracksWeight) {
        d.weight = intent.weight;
        if (intent.unit != null) d.unit = intent.unit!;
      } else {
        ignored.add('weight');
      }
    }
    if (intent.durationSec != null) {
      if (ex.tracksDuration) {
        d.durationSec = intent.durationSec;
      } else {
        ignored.add('duration');
      }
    }
    if (intent.distanceM != null) {
      if (ex.tracksDistance) {
        d.distanceM = intent.distanceM;
      } else {
        ignored.add('distance');
      }
    }
    if (intent.rpe != null) d.rpe = intent.rpe;

    draft.value = d;

    final readback = _draftPhrase(d);
    if (ignored.isNotEmpty) {
      await _speak(
          'That exercise doesn\'t track ${ignored.join(' or ')}. $readback');
    } else {
      await _speak('Got it. $readback');
    }
  }

  Future<void> _handleCommit() async {
    final item = _current;
    if (item == null) {
      await _speak('Pick an exercise first.');
      return;
    }
    final d = draft.value;
    if (d.isEmpty) {
      await _speak('Nothing to log yet. Tell me your reps or weight.');
      return;
    }
    final ex = item.exercise;
    final pos = exerciseIndex.value;
    final wkg = d.weight == null ? null : TrainingService.toKg(d.weight!, d.unit);
    final enteredUnit = ex.tracksWeight ? d.unit : null;

    final sets = await repo.setsForSession(sessionId);
    final incomplete = sets
        .where((s) => s.position == pos && !s.completed)
        .toList()
      ..sort((a, b) => a.setIndex.compareTo(b.setIndex));

    if (incomplete.isNotEmpty) {
      final t = incomplete.first;
      await repo.updateSet(
        t.id,
        SetEntriesCompanion(
          reps: Value(d.reps),
          weightKg: Value(wkg),
          durationSec: Value(d.durationSec),
          distanceM: Value(d.distanceM),
          rpe: Value(d.rpe),
          enteredUnit: Value(enteredUnit),
          completed: const Value(true),
        ),
      );
    } else {
      final count = sets.where((s) => s.position == pos).length;
      await training.logSet(
        sessionId: sessionId,
        exerciseId: ex.id,
        position: pos,
        setIndex: count,
        reps: d.reps,
        weightKg: d.weight,
        durationSec: d.durationSec,
        distanceM: d.distanceM,
        rpe: d.rpe,
        enteredUnit: enteredUnit,
      );
    }

    draft.value = DraftSet();
    await _speak('Logged. ${_draftPhrase(d)}');
  }

  /// Human-readable summary of a draft/logged set, gated to populated fields.
  String _draftPhrase(DraftSet d) {
    final parts = <String>[];
    if (d.reps != null) parts.add('${d.reps} reps');
    if (d.weight != null) parts.add('at ${_fmt(d.weight!)} ${d.unit}');
    if (d.durationSec != null) parts.add('${(d.durationSec! / 60).round()} min');
    if (d.distanceM != null) parts.add('${_fmt(d.distanceM! / 1000)} km');
    if (d.rpe != null) parts.add('RPE ${_fmt(d.rpe!)}');
    return parts.isEmpty ? 'No numbers yet.' : '${parts.join(', ')}.';
  }

  // ---- queries, rest, last-time, conversation ---------------------------

  Future<void> _handleProgress() async {
    final item = _current;
    if (item == null) {
      await _speak('No exercise selected.');
      return;
    }
    final pos = exerciseIndex.value;
    final sets = await repo.setsForSession(sessionId);
    final done = sets.where((s) => s.position == pos && s.completed).length;
    final target = item.prescription?.targetSets;
    if (target != null) {
      final left = target - done;
      await _speak('You\'ve done $done of $target sets. '
          '${left > 0 ? '$left to go.' : 'Target met.'}');
    } else {
      await _speak('You\'ve logged $done sets for ${item.exercise.name}.');
    }
  }

  Future<void> _handleRest(WorkoutIntent intent) async {
    final secs = intent.seconds ?? defaultRestSec;
    pendingRestSeconds = secs;
    _rest?.cancel();
    _rest = Timer(Duration(seconds: secs), announceRestOver);
    onRestScheduled?.call(Duration(seconds: secs));
    await _speak('Resting $secs seconds.');
  }

  /// Spoken when the rest timer elapses. Public so the UI can also surface it
  /// and tests can invoke it deterministically.
  Future<void> announceRestOver() async {
    if (_disposed) return;
    pendingRestSeconds = null;
    // The in-app announcement is firing now (app is foreground) — drop the
    // redundant background notification so the alert isn't doubled.
    onRestCancelled?.call();
    await _speak("Rest's over. Let's go.");
  }

  Future<void> _handleLastTime() async {
    final item = _current;
    if (item == null) {
      await _speak('No exercise selected.');
      return;
    }
    final ex = item.exercise;
    final history = await repo.setsForExercise(ex.id); // completed only, asc date
    if (history.isEmpty) {
      await _speak('No previous record for ${ex.name}.');
      return;
    }
    final lastDate = history.last.session.date;
    final lastSets =
        history.where((h) => h.session.date == lastDate).map((h) {
      final d = DraftSet(unit: h.set.enteredUnit ?? 'kg')
        ..reps = h.set.reps
        ..weight = h.set.weightKg
        ..durationSec = h.set.durationSec
        ..distanceM = h.set.distanceM
        ..rpe = h.set.rpe;
      return _draftPhrase(d);
    }).toList();
    final template =
        'Last time on $lastDate, ${ex.name}: ${lastSets.join(' ')}';

    final model = llm;
    if (model == null) {
      await _speak(template);
      return;
    }
    try {
      final answer = await model.chat([
        ChatMessage('system',
            'You are a concise gym coach. Rephrase this in one short sentence '
            'suitable to read aloud, plain text only: $template'),
        ChatMessage('user', 'How did I do last time on ${ex.name}?'),
      ]);
      final reply = answer.trim();
      await _speak(reply.isEmpty ? template : reply);
    } catch (_) {
      await _speak(template);
    }
  }

  Future<void> _handleConversation(String text) async {
    final model = llm;
    if (model == null) {
      await _speak("Sorry, I didn't understand that.");
      return;
    }
    try {
      final item = _current;
      final ctx = item == null
          ? 'The user is working out.'
          : 'The user is doing ${item.exercise.name}.';
      final answer = await model.chat([
        ChatMessage('system',
            'You are a friendly, concise gym assistant. $ctx Answer in 1-2 '
            'short sentences suitable to read aloud. Plain text only.'),
        ChatMessage('user', text),
      ]);
      final reply = answer.trim();
      await _speak(reply.isEmpty ? "Sorry, I didn't catch that." : reply);
    } catch (_) {
      await _speak("Sorry, I can't reach the assistant right now.");
    }
  }

  // ---- effort follow-up (filled by Task 5; stub keeps switch exhaustive) --

  Future<void> _handleEffort(String text) async {
    _awaitingEffort = false;
    final norm = WorkoutIntentParser.normalizeNumbers(text);
    final m = RegExp(r'(\d+)').firstMatch(norm);
    int? effort;
    if (m != null) {
      effort = int.parse(m.group(1)!);
      if (effort < 1) effort = 1;
      if (effort > 10) effort = 10;
    }
    await training.finishSession(sessionId, perceivedEffort: effort);
    exited = true;
    _rest?.cancel();
    onRestCancelled?.call();
    state.value = SessionState.idle;
    await speech.speak('Workout complete. Great job.');
  }

  // ---- helpers ----------------------------------------------------------

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  Future<void> _speak(String text) async {
    if (_disposed) return;
    state.value = SessionState.speaking;
    await speech.speak(text);
    if (_disposed) return;
    state.value = SessionState.idle;
  }

  void dispose() {
    _disposed = true;
    _rest?.cancel();
    onRestCancelled?.call();
    state.dispose();
    exerciseIndex.dispose();
    draft.dispose();
  }
}
