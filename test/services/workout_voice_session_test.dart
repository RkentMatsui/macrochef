import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/training_repository.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/providers/speech/speech_provider.dart';
import 'package:macrochef/services/training_service.dart';
import 'package:macrochef/services/workout_intent_parser.dart';
import 'package:macrochef/services/workout_voice_session.dart';

class FakeSpeech implements SpeechProvider {
  final List<String> spoken = [];
  String? get lastSpoken => spoken.isEmpty ? null : spoken.last;
  @override
  Future<void> init() async {}
  @override
  Future<void> startListening(void Function(String) onPartial,
      void Function(String) onFinal, {void Function()? onSpeechEnd}) async {}
  @override
  Future<void> stopListening() async {}
  @override
  Future<void> speak(String text) async => spoken.add(text);
  @override
  Future<void> stopSpeaking() async {}
  @override
  Future<void> dispose() async {}
}

class FakeLLMProvider implements LLMProvider {
  @override
  Future<String> chat(List<ChatMessage> m, {ChatOpts? opts}) async => 'ok';
  @override
  Future<Map<String, dynamic>> structured(String p, Map<String, dynamic> s,
          {ChatOpts? opts}) async =>
      {'intent': 'unknown'};
  @override
  Future<Map<String, dynamic>> vision(Uint8List b, String p, Map<String, dynamic> s,
          {ChatOpts? opts}) async =>
      throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  late TrainingRepository repo;
  late TrainingService training;
  late FakeSpeech speech;
  late WorkoutIntentParser parser;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TrainingRepository(db);
    training = TrainingService(repo);
    speech = FakeSpeech();
    parser = WorkoutIntentParser(llm: FakeLLMProvider());
  });
  tearDown(() => db.close());

  // Builds a one-program/one-day prescription: Bench 2x5, then Squat 1x5.
  Future<(int sessionId, int dayId, int benchId, int squatId)> seedDay() async {
    final benchId = await repo.insertExercise(ExercisesCompanion.insert(
      name: 'Bench Press',
      category: 'strength',
      tracksWeight: const Value(true),
      tracksReps: const Value(true),
    ));
    final squatId = await repo.insertExercise(ExercisesCompanion.insert(
      name: 'Back Squat',
      category: 'strength',
      tracksWeight: const Value(true),
      tracksReps: const Value(true),
    ));
    final programId = await repo.createProgram(name: 'PPL');
    final dayId = await repo.createDay(programId: programId, name: 'Push');
    await repo.setDayExercises(dayId, [
      TemplateExercisesCompanion.insert(
        dayId: dayId,
        exerciseId: benchId,
        position: 0,
        targetSets: const Value(2),
        targetReps: const Value('5'),
        targetWeightKg: const Value(60),
      ),
      TemplateExercisesCompanion.insert(
        dayId: dayId,
        exerciseId: squatId,
        position: 1,
        targetSets: const Value(1),
        targetReps: const Value('5'),
        targetWeightKg: const Value(100),
      ),
    ]);
    final sessionId = await training.startFromDay(dayId, '2026-06-17');
    return (sessionId, dayId, benchId, squatId);
  }

  WorkoutVoiceSession buildSession(int sessionId, int? dayId) =>
      WorkoutVoiceSession(
        sessionId: sessionId,
        dayId: dayId,
        training: training,
        repo: repo,
        speech: speech,
        parser: parser,
        llm: FakeLLMProvider(),
      );

  test('init loads the prescribed script and begin announces the first',
      () async {
    final (sessionId, dayId, _, _) = await seedDay();
    final s = buildSession(sessionId, dayId);
    await s.init();
    expect(s.scriptLength, 2);
    await s.begin();
    expect(speech.lastSpoken, contains('Bench Press'));
  });

  test('currentExercise announces the current exercise and target', () async {
    final (sessionId, dayId, _, _) = await seedDay();
    final s = buildSession(sessionId, dayId);
    await s.init();
    await s.handleUtterance("what's next");
    expect(speech.lastSpoken, contains('Bench Press'));
  });

  test('nextExercise advances and clamps at the end', () async {
    final (sessionId, dayId, _, _) = await seedDay();
    final s = buildSession(sessionId, dayId);
    await s.init();
    await s.handleUtterance('next exercise');
    expect(s.exerciseIndex.value, 1);
    expect(speech.lastSpoken, contains('Back Squat'));
    await s.handleUtterance('next exercise'); // clamp
    expect(s.exerciseIndex.value, 1);
  });

  test('prevExercise goes back and clamps at zero', () async {
    final (sessionId, dayId, _, _) = await seedDay();
    final s = buildSession(sessionId, dayId);
    await s.init();
    await s.handleUtterance('next exercise');
    await s.handleUtterance('previous exercise');
    expect(s.exerciseIndex.value, 0);
    await s.handleUtterance('previous exercise'); // clamp
    expect(s.exerciseIndex.value, 0);
  });

  test('setMetrics merges into the draft across turns, capability-gated',
      () async {
    final (sessionId, dayId, _, _) = await seedDay();
    final s = buildSession(sessionId, dayId);
    await s.init();
    await s.handleUtterance('6 reps');
    await s.handleUtterance('at 80 kilos');
    expect(s.draft.value.reps, 6);
    expect(s.draft.value.weight, 80);
    expect(s.draft.value.unit, 'kg');
  });

  test('commit updates the next incomplete prescribed set to completed',
      () async {
    final (sessionId, dayId, benchId, _) = await seedDay();
    final s = buildSession(sessionId, dayId);
    await s.init();
    await s.handleUtterance('5 reps at 60 kg');
    await s.handleUtterance('done');

    final sets = await repo.setsForSession(sessionId);
    final benchSets = sets.where((x) => x.exerciseId == benchId).toList();
    final completed = benchSets.where((x) => x.completed).toList();
    expect(completed.length, 1);
    expect(completed.single.reps, 5);
    expect(completed.single.weightKg, closeTo(60, 1e-6));
    // The day prescribed 2 bench sets; one incomplete should remain.
    expect(benchSets.where((x) => !x.completed).length, 1);
  });

  test('lb draft is stored as canonical kg on commit', () async {
    final (sessionId, dayId, benchId, _) = await seedDay();
    final s = buildSession(sessionId, dayId);
    await s.init();
    await s.handleUtterance('5 reps at 135 pounds');
    await s.handleUtterance('done');
    final sets = await repo.setsForSession(sessionId);
    final done = sets.firstWhere((x) => x.exerciseId == benchId && x.completed);
    expect(done.weightKg, closeTo(135 * 0.45359237, 1e-3));
    expect(done.enteredUnit, 'lb');
  });

  test('extra set beyond the prescription inserts a new completed row',
      () async {
    final (sessionId, dayId, benchId, _) = await seedDay();
    final s = buildSession(sessionId, dayId);
    await s.init();
    await s.handleUtterance('5 reps at 60 kg');
    await s.handleUtterance('done');
    await s.handleUtterance('5 reps at 60 kg');
    await s.handleUtterance('done');
    await s.handleUtterance('5 reps at 60 kg'); // 3rd > prescribed 2
    await s.handleUtterance('done');
    final sets = await repo.setsForSession(sessionId);
    final benchCompleted =
        sets.where((x) => x.exerciseId == benchId && x.completed).length;
    expect(benchCompleted, 3);
  });

  test('ad-hoc: select an exercise then log inserts a completed set', () async {
    final benchId = await repo.insertExercise(ExercisesCompanion.insert(
      name: 'Bench Press',
      category: 'strength',
      tracksWeight: const Value(true),
      tracksReps: const Value(true),
    ));
    final sessionId = await training.startEmptySession('2026-06-17');
    final s = buildSession(sessionId, null);
    await s.init();
    await s.handleUtterance('start bench press');
    expect(s.scriptLength, 1);
    await s.handleUtterance('5 reps at 60 kg');
    await s.handleUtterance('done');
    final sets = await repo.setsForSession(sessionId);
    expect(sets.where((x) => x.exerciseId == benchId && x.completed).length, 1);
  });

  test('progressQuery reports completed vs target sets', () async {
    final (sessionId, dayId, _, _) = await seedDay();
    final s = buildSession(sessionId, dayId);
    await s.init();
    await s.handleUtterance('5 reps at 60 kg');
    await s.handleUtterance('done');
    await s.handleUtterance('how many sets left');
    expect(speech.lastSpoken, contains('1'));
  });

  test('targetQuery speaks the prescription target', () async {
    final (sessionId, dayId, _, _) = await seedDay();
    final s = buildSession(sessionId, dayId);
    await s.init();
    await s.handleUtterance("what's the target");
    expect(speech.lastSpoken, contains('60'));
  });

  test('startRest stores seconds and announceRestOver speaks', () async {
    final (sessionId, dayId, _, _) = await seedDay();
    final s = buildSession(sessionId, dayId);
    await s.init();
    await s.handleUtterance('rest 90 seconds');
    expect(s.pendingRestSeconds, 90);
    await s.announceRestOver();
    expect(speech.lastSpoken!.toLowerCase(), contains('rest'));
  });

  test('finish asks for effort then records RPE and exits', () async {
    final (sessionId, dayId, _, _) = await seedDay();
    final s = buildSession(sessionId, dayId);
    await s.init();
    await s.handleUtterance('finish workout');
    expect(s.exited, isFalse); // waiting for effort
    await s.handleUtterance('8');
    expect(s.exited, isTrue);
    final session = await repo.sessionById(sessionId);
    expect(session!.completedAt, isNotNull);
    expect(session.perceivedEffort, 8);
  });

  test('finish with skip records no RPE but still completes', () async {
    final (sessionId, dayId, _, _) = await seedDay();
    final s = buildSession(sessionId, dayId);
    await s.init();
    await s.handleUtterance('finish workout');
    await s.handleUtterance('skip');
    expect(s.exited, isTrue);
    final session = await repo.sessionById(sessionId);
    expect(session!.completedAt, isNotNull);
    expect(session.perceivedEffort, isNull);
  });

  test('exit stops without finishing the session', () async {
    final (sessionId, dayId, _, _) = await seedDay();
    final s = buildSession(sessionId, dayId);
    await s.init();
    await s.handleUtterance('quit');
    expect(s.exited, isTrue);
    final session = await repo.sessionById(sessionId);
    expect(session!.completedAt, isNull);
  });

  test('defaultUnit seeds the draft unit', () async {
    final (sessionId, dayId, _, _) = await seedDay();
    final s = WorkoutVoiceSession(
      sessionId: sessionId,
      dayId: dayId,
      training: training,
      repo: repo,
      speech: speech,
      parser: parser,
      llm: FakeLLMProvider(),
      defaultUnit: 'lb',
    );
    await s.init();
    expect(s.draft.value.unit, 'lb');
  });

  test('rest with no number uses defaultRestSec', () async {
    final (sessionId, dayId, _, _) = await seedDay();
    final s = WorkoutVoiceSession(
      sessionId: sessionId,
      dayId: dayId,
      training: training,
      repo: repo,
      speech: speech,
      parser: parser,
      llm: FakeLLMProvider(),
      defaultRestSec: 120,
    );
    await s.init();
    await s.handleUtterance('rest');
    expect(s.pendingRestSeconds, 120);
  });
}
