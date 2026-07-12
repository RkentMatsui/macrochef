import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/training_repository.dart';
import 'package:macrochef/services/schedule_service.dart';
import 'package:macrochef/services/training_service.dart';

void main() {
  late AppDatabase db;
  late TrainingRepository repo;
  late ScheduleService svc;
  late TrainingService training;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TrainingRepository(db);
    svc = ScheduleService(repo);
    training = TrainingService(repo);
  });
  tearDown(() => db.close());

  test('dayIndexOf maps Monday→0 .. Sunday→6', () {
    // 2026-06-15 is a Monday.
    expect(ScheduleService.dayIndexOf(DateTime(2026, 6, 15)), 0);
    expect(ScheduleService.dayIndexOf(DateTime(2026, 6, 21)), 6); // Sunday
  });

  test('weekStartOf returns the Monday of the week', () {
    // Wednesday 2026-06-17 → Monday 2026-06-15.
    final start = ScheduleService.weekStartOf(DateTime(2026, 6, 17));
    expect(ScheduleService.dateKey(start), '2026-06-15');
  });

  test('plannedForDate maps a date to its scheduled days', () async {
    final programId = await repo.createProgram(name: 'PPL');
    final pushDay = await repo.createDay(programId: programId, name: 'Push');
    await repo.setScheduleForDay(0, [pushDay]); // Monday = Push

    // 2026-06-15 is a Monday.
    final planned = await svc.plannedForDate(DateTime(2026, 6, 15));
    expect(planned.length, 1);
    expect(planned.single.dayId, pushDay);
    expect(planned.single.name, 'PPL · Push');

    // Tuesday has nothing planned.
    final tuesday = await svc.plannedForDate(DateTime(2026, 6, 16));
    expect(tuesday, isEmpty);
  });

  test('setScheduleForDay with empty list clears the day', () async {
    final programId = await repo.createProgram(name: 'PPL');
    final pushDay = await repo.createDay(programId: programId, name: 'Push');
    await repo.setScheduleForDay(0, [pushDay]);
    expect((await repo.scheduleForDay(0)).length, 1);
    await repo.setScheduleForDay(0, []);
    expect(await repo.scheduleForDay(0), isEmpty);
  });

  test('adherence with 2 of 3 planned done is 0.667', () async {
    final programId = await repo.createProgram(name: 'PPL');
    final push = await repo.createDay(programId: programId, name: 'Push');
    final pull = await repo.createDay(programId: programId, name: 'Pull');
    final legs = await repo.createDay(programId: programId, name: 'Legs');
    await repo.setScheduleForDay(0, [push]); // Mon
    await repo.setScheduleForDay(2, [pull]); // Wed
    await repo.setScheduleForDay(4, [legs]); // Fri

    // Week of Monday 2026-06-15. Complete Mon and Wed, skip Fri.
    final mon = await training.startEmptySession('2026-06-15');
    await training.finishSession(mon);
    final wed = await training.startEmptySession('2026-06-17');
    await training.finishSession(wed);

    final adherence =
        await svc.adherenceForWeek(DateTime(2026, 6, 17));
    expect(adherence.planned, 3);
    expect(adherence.completed, 2);
    expect(adherence.fraction, closeTo(0.667, 1e-3));
  });

  test('adherence is 0 when nothing is planned', () async {
    final adherence = await svc.adherenceForWeek(DateTime(2026, 6, 17));
    expect(adherence.planned, 0);
    expect(adherence.fraction, 0.0);
  });

  test('extra completed sessions on a day do not exceed planned count',
      () async {
    final programId = await repo.createProgram(name: 'PPL');
    final push = await repo.createDay(programId: programId, name: 'Push');
    await repo.setScheduleForDay(0, [push]); // Mon, 1 planned

    // Two completed sessions on the same Monday.
    final a = await training.startEmptySession('2026-06-15');
    await training.finishSession(a);
    final b = await training.startEmptySession('2026-06-15');
    await training.finishSession(b);

    final adherence = await svc.adherenceForWeek(DateTime(2026, 6, 15));
    expect(adherence.planned, 1);
    expect(adherence.completed, 1); // capped at planned count
    expect(adherence.fraction, 1.0);
  });
}
