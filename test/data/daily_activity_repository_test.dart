import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/daily_activity_repository.dart';

void main() {
  late AppDatabase db;
  late DailyActivityRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DailyActivityRepository(db);
  });
  tearDown(() => db.close());

  test('upsert + forDate round-trip', () async {
    await repo.upsert('2026-06-17', steps: 8000, activeMinutes: 45);
    final row = await repo.forDate('2026-06-17');
    expect(row, isNotNull);
    expect(row!.steps, 8000);
    expect(row.activeMinutes, 45);
    expect(row.source, 'manual');
  });

  test('forDate returns null when no row exists', () async {
    expect(await repo.forDate('2026-01-01'), isNull);
  });

  test('upsert overwrites the existing row for a date', () async {
    await repo.upsert('2026-06-17', steps: 5000, activeMinutes: 30);
    await repo.upsert('2026-06-17', steps: 12000, activeMinutes: 60);

    final row = await repo.forDate('2026-06-17');
    expect(row!.steps, 12000);
    expect(row.activeMinutes, 60);

    // Still exactly one row for that date.
    final all = await repo.range('2026-06-17', '2026-06-17');
    expect(all.length, 1);
  });

  test('range returns rows in the inclusive window, ascending by date', () async {
    await repo.upsert('2026-06-15', steps: 3000);
    await repo.upsert('2026-06-17', steps: 9000);
    await repo.upsert('2026-06-20', steps: 7000);

    final rows = await repo.range('2026-06-16', '2026-06-19');
    expect(rows.length, 1);
    expect(rows.single.date, '2026-06-17');

    final wider = await repo.range('2026-06-15', '2026-06-20');
    expect(wider.map((r) => r.date).toList(),
        ['2026-06-15', '2026-06-17', '2026-06-20']);
  });
}
