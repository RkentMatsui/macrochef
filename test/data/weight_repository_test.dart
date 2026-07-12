import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/weight_repository.dart';

void main() {
  late AppDatabase db;
  late WeightRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WeightRepository(db);
  });

  tearDown(() => db.close());

  test('upsert inserts a new entry', () async {
    await repo.upsert('2026-06-01', 80.0);
    final entry = await repo.forDate('2026-06-01');
    expect(entry, isNotNull);
    expect(entry!.kg, 80.0);
  });

  test('upsert replaces an existing entry for the same date', () async {
    await repo.upsert('2026-06-01', 80.0);
    await repo.upsert('2026-06-01', 81.5);
    final entry = await repo.forDate('2026-06-01');
    expect(entry!.kg, 81.5);
    final all = await repo.all();
    expect(all.length, 1); // still only one row
  });

  test('forDateRange returns entries in ascending date order', () async {
    await repo.upsert('2026-06-03', 82.0);
    await repo.upsert('2026-06-01', 80.0);
    await repo.upsert('2026-06-02', 81.0);

    final range = await repo.forDateRange('2026-06-01', '2026-06-03');
    expect(range.map((e) => e.date).toList(),
        ['2026-06-01', '2026-06-02', '2026-06-03']);
  });

  test('delete removes only the specified date', () async {
    await repo.upsert('2026-06-01', 80.0);
    await repo.upsert('2026-06-02', 81.0);

    await repo.delete('2026-06-01');

    final all = await repo.all();
    expect(all.length, 1);
    expect(all.first.date, '2026-06-02');
  });

  test('forDate returns null when no entry exists', () async {
    final entry = await repo.forDate('2099-01-01');
    expect(entry, isNull);
  });
}
