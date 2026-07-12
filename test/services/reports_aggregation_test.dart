import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/log_repository.dart';
import 'package:macrochef/data/repositories/target_repository.dart';
import 'package:macrochef/models/daily.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/services/daily_log_service.dart';

void main() {
  late AppDatabase db;
  late DailyLogService svc;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    svc = DailyLogService(
      logs: LogRepository(db),
      targets: TargetRepository(db),
    );
  });

  tearDown(() async => db.close());

  Future<void> seed(String date, String name, MacroValues m) =>
      svc.log(date, name: name, grams: 100, macros: m, source: MacroSource.manual);

  test('rangeTotals returns one DailyTotals per day with that day target',
      () async {
    await svc.setTarget(const DailyTarget(kcal: 2000, protein: 150, carb: 200, fat: 60));
    await seed('2026-06-14', 'a', const MacroValues(kcal: 500, protein: 40, carb: 50, fat: 10));
    await seed('2026-06-15', 'b', const MacroValues(kcal: 700, protein: 60, carb: 40, fat: 20));

    final totals = await svc.rangeTotals('2026-06-14', '2026-06-15');
    expect(totals.length, 2);
    expect(totals[0].consumed.kcal, closeTo(500, 0.001));
    expect(totals[1].consumed.kcal, closeTo(700, 0.001));
    expect(totals[1].target!.kcal, closeTo(2000, 0.001));
  });

  test('rangeTotals fills empty days with zero consumed', () async {
    await seed('2026-06-15', 'b', const MacroValues(kcal: 700, protein: 60, carb: 40, fat: 20));
    final totals = await svc.rangeTotals('2026-06-13', '2026-06-15');
    expect(totals.length, 3);
    expect(totals[0].consumed.kcal, 0);
    expect(totals[2].consumed.kcal, closeTo(700, 0.001));
  });

  test('topFoods groups by name, sums kcal+protein, sorts desc', () async {
    await seed('2026-06-14', 'Chicken', const MacroValues(kcal: 300, protein: 50, carb: 0, fat: 6));
    await seed('2026-06-15', 'Chicken', const MacroValues(kcal: 300, protein: 50, carb: 0, fat: 6));
    await seed('2026-06-15', 'Rice', const MacroValues(kcal: 200, protein: 4, carb: 44, fat: 1));

    final top = await svc.topFoods('2026-06-14', '2026-06-15');
    expect(top.first.name, 'Chicken');
    expect(top.first.kcal, closeTo(600, 0.001));
    expect(top.first.protein, closeTo(100, 0.001));
    expect(top.first.count, 2);
    expect(top[1].name, 'Rice');
  });
}
