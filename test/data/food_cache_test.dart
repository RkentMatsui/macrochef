import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/food_cache_repository.dart';
import 'package:macrochef/models/macros.dart';

void main() {
  late AppDatabase db;
  late FoodCacheRepository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = FoodCacheRepository(db);
  });
  tearDown(() => db.close());

  FoodMacros food(String n, double k, MacroSource s, {bool override = false}) =>
      FoodMacros(
        name: n,
        perHundred: PerHundred(kcal: k, protein: 1, carb: 1, fat: 1),
        source: s,
        isEstimate: false,
      );

  test('override wins over a stale cached row', () async {
    await repo.put(food('tofu', 70, MacroSource.off));
    await repo.upsertOverride(food('tofu', 144, MacroSource.manual));
    final got = await repo.find('tofu');
    expect(got!.perHundred.kcal, 144);
    expect(got.source, MacroSource.manual);
  });

  test('upsertOverride replaces duplicates (single row remains)', () async {
    await repo.upsertOverride(food('tofu', 100, MacroSource.manual));
    await repo.upsertOverride(food('tofu', 200, MacroSource.manual));
    final rows = await db.select(db.foodCache).get();
    expect(rows.where((r) => r.name.toLowerCase() == 'tofu').length, 1);
    expect((await repo.find('tofu'))!.perHundred.kcal, 200);
  });

  test(
    'find returns most-recently-inserted row when no override exists',
    () async {
      await repo.put(food('oats', 350, MacroSource.off));
      await repo.put(food('oats', 380, MacroSource.usda));
      final got = await repo.find('oats');
      // The second put has a higher id and should win.
      expect(got!.perHundred.kcal, 380);
    },
  );

  test('listOverrides returns only user overrides', () async {
    await repo.put(food('rice', 130, MacroSource.off));
    await repo.upsertOverride(food('tofu', 144, MacroSource.manual));
    final list = await repo.listOverrides();
    expect(list.map((f) => f.name), ['tofu']);
  });

  test('put replaces prior non-override rows (no duplicate pile-up)', () async {
    await repo.put(food('oats', 350, MacroSource.off));
    await repo.put(food('oats', 380, MacroSource.usda));
    await repo.put(food('oats', 379, MacroSource.ai));
    final rows = await db.select(db.foodCache).get();
    expect(rows.where((r) => r.name.toLowerCase() == 'oats').length, 1);
    expect((await repo.find('oats'))!.perHundred.kcal, 379);
  });

  test('put does not delete a user override for the same name', () async {
    await repo.upsertOverride(food('tofu', 144, MacroSource.manual));
    await repo.put(food('tofu', 70, MacroSource.off));
    expect((await repo.find('tofu'))!.source, MacroSource.manual);
    expect((await repo.find('tofu'))!.perHundred.kcal, 144);
  });

  test('clearNonOverrides removes auto rows but keeps overrides', () async {
    await repo.put(food('rice', 130, MacroSource.off));
    await repo.put(food('oats', 350, MacroSource.usda));
    await repo.upsertOverride(food('tofu', 144, MacroSource.manual));
    final removed = await repo.clearNonOverrides();
    expect(removed, 2);
    expect(await repo.find('rice'), isNull);
    expect((await repo.find('tofu'))!.source, MacroSource.manual);
  });

  test('fibre100 round-trips through put and find', () async {
    await repo.put(
      FoodMacros(
        name: 'oats-fibre',
        perHundred: const PerHundred(
          kcal: 380,
          protein: 13,
          carb: 66,
          fat: 7,
          fibre: 10.6,
        ),
        source: MacroSource.usda,
        isEstimate: false,
      ),
    );
    final got = await repo.find('oats-fibre');
    expect(got, isNotNull);
    expect(got!.perHundred.fibre, closeTo(10.6, 0.001));
  });

  test('put with null fibre stores null', () async {
    await repo.put(
      FoodMacros(
        name: 'null-fibre',
        perHundred: const PerHundred(kcal: 100, protein: 5, carb: 10, fat: 2),
        source: MacroSource.off,
        isEstimate: false,
      ),
    );
    final got = await repo.find('null-fibre');
    expect(got, isNotNull);
    expect(got!.perHundred.fibre, isNull);
  });

  test('fibre100 round-trips through upsertOverride', () async {
    await repo.upsertOverride(
      FoodMacros(
        name: 'broccoli',
        perHundred: const PerHundred(
          kcal: 34,
          protein: 2.8,
          carb: 6.6,
          fat: 0.4,
          fibre: 2.6,
        ),
        source: MacroSource.manual,
        isEstimate: false,
      ),
    );
    final got = await repo.find('broccoli');
    expect(got, isNotNull);
    expect(got!.perHundred.fibre, closeTo(2.6, 0.001));
  });

  test('gramsPerPiece round-trips and setGramsPerPiece updates it', () async {
    await repo.put(
      FoodMacros(
        name: 'tortilla',
        perHundred: const PerHundred(kcal: 300, protein: 8, carb: 50, fat: 7),
        source: MacroSource.usda,
        isEstimate: false,
        gramsPerPiece: 50,
      ),
    );
    expect((await repo.find('tortilla'))!.gramsPerPiece, 50);
    await repo.setGramsPerPiece('tortilla', 42);
    expect((await repo.find('tortilla'))!.gramsPerPiece, 42);
  });

  test('nutrition basis round-trips through put and override', () async {
    const basis = NutritionBasis(
      quantity: 250,
      unit: 'ml',
      macros: MacroValues(kcal: 120, protein: 6, carb: 10, fat: 4),
    );
    await repo.upsertOverride(
      FoodMacros(
        name: 'milk',
        perHundred: PerHundred.zero,
        source: MacroSource.manual,
        isEstimate: false,
        basis: basis,
        basisPhysicalGrams: 260,
      ),
    );
    final got = await repo.find('milk');
    expect(got!.basis!.quantity, 250);
    expect(got.basis!.unit, 'ml');
    expect(got.basis!.macros.kcal, 120);
    expect(got.basisPhysicalGrams, 260);
  });

  test('web provenance round-trips through cache and override', () async {
    final provenance = FoodProvenance(
      url: Uri.parse('https://example.com/nutrition'),
      title: 'Example nutrition label',
      retrievedAt: DateTime.utc(2026, 7, 15, 9, 30),
      inferredFields: {'sodium', 'fibre'},
    );
    final food = FoodMacros(
      name: 'grounded food',
      perHundred: const PerHundred(kcal: 100, protein: 5, carb: 10, fat: 2),
      source: MacroSource.ai,
      isEstimate: true,
      provenance: provenance,
    );

    await repo.put(food);
    var result = await repo.find('grounded food');
    expect(result!.provenance!.url, provenance.url);
    expect(result.provenance!.title, provenance.title);
    expect(result.provenance!.retrievedAt.toUtc(), provenance.retrievedAt);
    expect(result.provenance!.inferredFields, {'fibre', 'sodium'});

    await repo.upsertOverride(food);
    result = await repo.find('grounded food');
    expect(result!.provenance!.url, provenance.url);
  });

  test('a cache row without provenance remains valid', () async {
    await repo.put(food('plain food', 100, MacroSource.usda));
    expect((await repo.find('plain food'))!.provenance, isNull);
  });
}
