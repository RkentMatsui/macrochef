import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/training_repository.dart';
import 'package:macrochef/models/chat.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/services/exercise_library.dart';
import 'package:macrochef/services/program_generator_service.dart';

/// Faked LLM returning a fixed 3-day program. Records the last prompt so we can
/// assert the request fields are embedded.
class _FakeLlm implements LLMProvider {
  String? lastPrompt;
  ChatOpts? lastOpts;
  final Map<String, dynamic> response;
  _FakeLlm(this.response);

  @override
  Future<Map<String, dynamic>> structured(
      String prompt, Map<String, dynamic> jsonSchema,
      {ChatOpts? opts}) async {
    lastPrompt = prompt;
    lastOpts = opts;
    return response;
  }

  @override
  Future<String> chat(List<ChatMessage> messages, {ChatOpts? opts}) async => '';

  @override
  Future<Map<String, dynamic>> vision(
          Uint8List imageBytes, String prompt, Map<String, dynamic> jsonSchema,
          {ChatOpts? opts}) async =>
      throw UnimplementedError();
}

Map<String, dynamic> _threeDayProgram() => {
      'name': 'Test Program',
      'templates': [
        {
          'name': 'Push',
          'exercises': [
            {'name': 'Bench Press', 'sets': 3, 'reps': '8-12'},
            {'name': 'Overhead Press', 'sets': 3, 'reps': '8-12'},
          ],
        },
        {
          'name': 'Pull',
          'exercises': [
            {'name': 'barbell-row', 'sets': 3, 'reps': '8-12'},
            // Unknown movement → should become a custom exercise.
            {'name': 'Cosmic Cable Crunch Press', 'sets': 3, 'reps': '10-15'},
          ],
        },
        {
          'name': 'Legs',
          'exercises': [
            {'name': 'Back Squat', 'sets': 4, 'reps': '5'},
            {'name': 'Running', 'durationSec': 1200, 'distanceM': 3000},
          ],
        },
      ],
      'schedule': [
        {'dayOfWeek': 0, 'templateIndex': 0},
        {'dayOfWeek': 2, 'templateIndex': 1},
        {'dayOfWeek': 4, 'templateIndex': 2},
      ],
    };

void main() {
  late AppDatabase db;
  late TrainingRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = TrainingRepository(db);
    await seedExercises(repo);
  });
  tearDown(() => db.close());

  const request = ProgramRequest(
    goal: 'build muscle',
    experience: 'intermediate',
    equipment: 'full gym',
    daysPerWeek: 3,
    sessionMinutes: 60,
  );

  test('generate embeds request fields and parses the structured program',
      () async {
    final llm = _FakeLlm(_threeDayProgram());
    final svc = ProgramGeneratorService(llm);

    final program = await svc.generate(request);

    expect(program.templates.length, 3);
    expect(program.templates[0].name, 'Push');
    expect(program.templates[0].exercises.length, 2);
    expect(program.schedule.length, 3);
    expect(program.schedule[0], 0);
    expect(program.schedule[2], 1);
    expect(program.schedule[4], 2);

    expect(llm.lastPrompt, contains('build muscle'));
    expect(llm.lastPrompt, contains('intermediate'));
    expect(llm.lastPrompt, contains('full gym'));
    expect(llm.lastPrompt, contains('3-day'));

    // A multi-day program is large; it must request a generous token budget so
    // the JSON doesn't truncate to empty templates.
    expect(llm.lastOpts?.maxTokens, isNotNull);
    expect(llm.lastOpts!.maxTokens, greaterThanOrEqualTo(4096));
  });

  test('persist creates 1 program with 3 days + schedule; all exercises resolve',
      () async {
    final llm = _FakeLlm(_threeDayProgram());
    final svc = ProgramGeneratorService(llm);
    final program = await svc.generate(request);

    final dayIds = await svc.persist(program, repo);
    expect(dayIds.length, 3);

    // Exactly one program persisted, with a non-empty name.
    final programs = await repo.allPrograms();
    expect(programs.length, 1);
    final persisted = programs.single;
    expect(persisted.name, isNotEmpty);

    // The program has 3 days carrying the generated template names.
    final days = await repo.daysForProgram(persisted.id);
    expect(days.length, 3);
    expect(days.map((d) => d.name).toList(), ['Push', 'Pull', 'Legs']);

    // 3 schedule entries (one per planned weekday) mapping to the right days.
    final schedule = await repo.fullSchedule();
    expect(schedule.length, 3);
    expect(schedule.map((s) => s.dayOfWeek).toSet(), {0, 2, 4});
    // weekday index → dayId: Mon→Push, Wed→Pull, Fri→Legs.
    final byWeekday = {for (final s in schedule) s.dayOfWeek: s.dayId};
    expect(byWeekday[0], days[0].id); // Push
    expect(byWeekday[2], days[1].id); // Pull
    expect(byWeekday[4], days[2].id); // Legs

    // Every prescribed exercise resolved to a real exercise id.
    for (final dayId in dayIds) {
      final tes = await repo.dayExercises(dayId);
      expect(tes, isNotEmpty);
      for (final te in tes) {
        final ex = await repo.exerciseById(te.exerciseId);
        expect(ex, isNotNull);
      }
    }

    // The unmatched (fictional) exercise became a custom exercise.
    final all = await repo.allExercises();
    final custom =
        all.where((e) => e.name == 'Cosmic Cable Crunch Press').toList();
    expect(custom.length, 1);
    expect(custom.single.isCustom, isTrue);

    // Known names/slugs mapped onto seeded (non-custom) library entries.
    final bench = all.firstWhere((e) => e.name == 'Bench Press');
    expect(bench.isCustom, isFalse);
    final row = all.firstWhere((e) => e.slug == 'barbell-row');
    expect(row.isCustom, isFalse);
  });

  test('schedule entries with out-of-range indices are dropped', () async {
    final response = {
      'templates': [
        {
          'name': 'Full Body',
          'exercises': [
            {'name': 'Back Squat', 'sets': 3, 'reps': '5'},
          ],
        },
      ],
      'schedule': [
        {'dayOfWeek': 0, 'templateIndex': 0},
        {'dayOfWeek': 1, 'templateIndex': 5}, // out of range → dropped
        {'dayOfWeek': 9, 'templateIndex': 0}, // bad day → dropped
      ],
    };
    final svc = ProgramGeneratorService(_FakeLlm(response));
    final program = await svc.generate(request);
    expect(program.templates.length, 1);
    expect(program.schedule, {0: 0});
  });
}
