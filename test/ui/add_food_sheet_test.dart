import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/food_cache_repository.dart';
import 'package:macrochef/models/food_unit_weight.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/services/food_db/open_food_facts_client.dart';
import 'package:macrochef/services/food_db/usda_client.dart';
import 'package:macrochef/services/food_lookup.dart';
import 'package:macrochef/services/food_units.dart';
import 'package:macrochef/services/food_web_grounder.dart';
import 'package:macrochef/state/providers.dart';
import 'package:macrochef/ui/daily/daily_log_screen.dart';

void main() {
  testWidgets(
    'selecting a basis food defaults to its saved quantity and unit',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final cache = FoodCacheRepository(db);
      await cache.upsertOverride(
        const FoodMacros(
          name: 'Iced milk',
          perHundred: PerHundred.zero,
          source: MacroSource.manual,
          isEstimate: false,
          basis: NutritionBasis(
            quantity: 250,
            unit: 'ml',
            macros: MacroValues(kcal: 120, protein: 8, carb: 12, fat: 4),
          ),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          foodLookupProvider.overrideWith(
            (ref) async => FoodLookup(
              cache: cache,
              off: OpenFoodFactsClient(),
              usda: UsdaClient(apiKey: ''),
              llm: _UnusedLlm(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => showAddFoodSheet(ctx),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Iced milk');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Iced milk').last);
      await tester.pumpAndSettle();

      final quantity = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(quantity.controller!.text, '250');
      expect(find.text('ml'), findsWidgets);
    },
  );

  testWidgets('Today renders logged basis portions without fake grams', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db
        .into(db.logEntries)
        .insert(
          LogEntriesCompanion.insert(
            date: todayDate(),
            foodName: 'Iced milk',
            grams: 0,
            kcal: 120,
            protein: 8,
            carb: 12,
            fat: 4,
            source: 'manual',
            portionQuantity: const Value(250),
            portionUnit: const Value('ml'),
          ),
        );
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: DailyLogScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('250 ml', skipOffstage: false), findsOneWidget);
    expect(find.textContaining('25000 g'), findsNothing);
    expect(find.textContaining('0 g'), findsNothing);
  });

  testWidgets('manual food logs as one serving without grams', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showAddFoodSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Macros'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Gramless meal');
    await tester.enterText(find.byType(TextField).at(2), '420');
    final addButton = find.text('Add', skipOffstage: false);
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    final entry = await db.select(db.logEntries).getSingle();
    expect(entry.grams, 0);
    expect(entry.portionQuantity, 1);
    expect(entry.portionUnit, 'serving');
    expect(entry.kcal, 420);
  });

  testWidgets(
    'logging cached Potato wedges in grams scales nutrition without a serving error',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final cache = FoodCacheRepository(db);
      await cache.upsertOverride(
        const FoodMacros(
          name: 'Potato wedges',
          perHundred: PerHundred(kcal: 150, protein: 2, carb: 25, fat: 4),
          source: MacroSource.manual,
          isEstimate: false,
        ),
      );
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          foodLookupProvider.overrideWith(
            (ref) async => FoodLookup(
              cache: cache,
              off: OpenFoodFactsClient(),
              usda: UsdaClient(apiKey: ''),
              llm: _UnusedLlm(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showAddFoodSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Potato wedges');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Potato wedges').last);
      await tester.enterText(find.byType(TextField).at(1), '60');

      await tester.tap(find.text('Add', skipOffstage: false));
      await tester.pumpAndSettle();

      final entry = await db.select(db.logEntries).getSingle();
      expect(entry.grams, 60);
      expect(entry.kcal, 90);
      expect(entry.protein, 1.2);
      expect(entry.carb, 15);
      expect(entry.fat, 2.4);
      expect(find.text('Added Potato wedges · 60 g'), findsOneWidget);
      expect(find.textContaining('published g serving'), findsNothing);
    },
  );

  testWidgets('recovered average piece weight is marked and persisted', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final cache = FoodCacheRepository(db);
    await cache.upsertOverride(
      const FoodMacros(
        name: 'Potato wedges',
        perHundred: PerHundred(kcal: 150, protein: 2, carb: 25, fat: 4),
        source: MacroSource.manual,
        isEstimate: false,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        foodLookupProvider.overrideWith(
          (ref) async => FoodLookup(
            cache: cache,
            off: OpenFoodFactsClient(),
            usda: UsdaClient(apiKey: ''),
            llm: _UnusedLlm(),
            webGrounder: _UnitWeightGrounder(
              FoodUnitWeight(
                foodName: 'Potato wedges',
                unit: 'piece',
                gramsPerUnit: 85,
                kind: FoodUnitWeightKind.average,
                provenance: FoodProvenance(
                  url: Uri.parse('https://example.com/wedges'),
                  title: 'Average wedge weight',
                  retrievedAt: DateTime.utc(2026, 7, 18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showAddFoodSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Potato wedges');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Potato wedges').last);
    await tester.tap(find.byType(DropdownButton<FoodUnit>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('piece').last);
    await tester.enterText(find.byType(TextField).at(1), '2');

    await tester.tap(find.text('Add', skipOffstage: false));
    await tester.pumpAndSettle();

    final entry = await db.select(db.logEntries).getSingle();
    expect(entry.grams, 170);
    expect(entry.kcal, 255);
    expect(entry.portionWeightGramsPerUnit, 85);
    expect(entry.portionWeightIsEstimate, isTrue);
    expect(find.text('Added Potato wedges · 2 pieces ≈ 170 g'), findsOneWidget);
  });

  testWidgets('published recovered weight confirms without approximation', (
    tester,
  ) async {
    final db = await _openPotatoWedges(
      tester,
      unit: 'piece',
      amount: '2',
      grounder: _UnitWeightGrounder(
        _potatoWeight(FoodUnitWeightKind.published),
      ),
    );

    await tester.tap(find.text('Add', skipOffstage: false));
    await tester.pumpAndSettle();

    expect(find.text('Added Potato wedges · 2 pieces'), findsOneWidget);
    expect(find.textContaining('≈'), findsNothing);
    expect((await db.select(db.logEntries).getSingle()).grams, 170);
  });

  testWidgets('missing grams lookup keeps the generic missing-food message', (
    tester,
  ) async {
    await _openPotatoWedges(tester, cacheFood: false);

    await tester.tap(find.text('Add', skipOffstage: false));
    await tester.pumpAndSettle();

    expect(find.text('Could not find "Potato wedges".'), findsOneWidget);
  });

  testWidgets('missing piece lookup names the selected unit and suggests grams', (
    tester,
  ) async {
    await _openPotatoWedges(tester, cacheFood: false, unit: 'piece');

    await tester.tap(find.text('Add', skipOffstage: false));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Couldn\'t find a reliable weight for one piece of “Potato wedges”. Choose grams, try another result, or enter macros manually.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'unavailable recovery for a resolved grams portion shows the mass action',
    (tester) async {
      await _openPotatoWedges(
        tester,
        perHundred: PerHundred.zero,
        basis: const NutritionBasis(
          quantity: 1,
          unit: 'piece',
          macros: MacroValues(kcal: 150, protein: 2, carb: 25, fat: 4),
        ),
        grounder: _UnitWeightGrounder(null),
      );

      await tester.tap(find.text('Add', skipOffstage: false));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Couldn\'t find per-100 g nutrition or a reliable serving weight for “Potato wedges”. Try another result or enter macros manually.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('unavailable piece recovery names the selected unit', (
    tester,
  ) async {
    await _openPotatoWedges(
      tester,
      unit: 'piece',
      grounder: _UnitWeightGrounder(null),
    );

    await tester.tap(find.text('Add', skipOffstage: false));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Couldn\'t find a reliable weight for one piece of “Potato wedges”. Choose grams, try another result, or enter macros manually.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'duplicate submits during recovery make one request and log once',
    (tester) async {
      final gate = Completer<GroundedUnitWeightResult?>();
      final grounder = _UnitWeightGrounder(null, gate: gate);
      final db = await _openPotatoWedges(
        tester,
        unit: 'piece',
        grounder: grounder,
      );

      final add = find.text('Add', skipOffstage: false);
      await tester.tap(add);
      await tester.tap(add);
      await tester.pump();
      expect(grounder.requests, 1);

      gate.complete(
        GroundedUnitWeightResult.tryCreate(
          _potatoWeight(FoodUnitWeightKind.published),
        ),
      );
      await tester.pumpAndSettle();
      expect(grounder.requests, 1);
      expect(await db.select(db.logEntries).get(), hasLength(1));
    },
  );

  testWidgets('closing during recovery does not set state after dispose', (
    tester,
  ) async {
    final gate = Completer<GroundedUnitWeightResult?>();
    await _openPotatoWedges(
      tester,
      unit: 'piece',
      grounder: _UnitWeightGrounder(null, gate: gate),
    );

    await tester.tap(find.text('Add', skipOffstage: false));
    await tester.pump();
    await tester.binding.handlePopRoute();
    gate.complete(
      GroundedUnitWeightResult.tryCreate(
        _potatoWeight(FoodUnitWeightKind.published),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isA<Null>());
  });

  testWidgets('Add food sheet opens and renders the quantity + unit selector', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => showAddFoodSheet(ctx),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The sheet must actually render its content (regression: a bad Row layout
    // collapsed the whole sheet so nothing showed).
    expect(find.text('Log food'), findsOneWidget);
    expect(find.text('Look up'), findsOneWidget);
    // The unit dropdown (DropdownButton<FoodUnit>) must be present.
    expect(find.byWidgetPredicate((w) => w is DropdownButton), findsOneWidget);
    expect(tester.takeException(), isA<Null>());
  });
}

class _UnusedLlm implements LLMProvider {
  @override
  Future<String> chat(List messages, {opts}) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> structured(
    String prompt,
    Map<String, dynamic> jsonSchema, {
    opts,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> vision(
    bytes,
    String prompt,
    Map<String, dynamic> jsonSchema, {
    opts,
  }) => throw UnimplementedError();
}

class _UnitWeightGrounder extends FoodWebGrounder {
  final FoodUnitWeight? weight;
  final Completer<GroundedUnitWeightResult?>? gate;
  int requests = 0;

  _UnitWeightGrounder(this.weight, {this.gate});

  @override
  Future<GroundedFoodResult?> ground(String foodName) async => null;

  @override
  Future<GroundedUnitWeightResult?> groundUnitWeight(
    String foodName, {
    required String requestedUnit,
  }) async {
    requests++;
    final pending = gate;
    if (pending != null) return pending.future;
    final value = weight;
    return value == null ? null : GroundedUnitWeightResult.tryCreate(value);
  }
}

FoodUnitWeight _potatoWeight(FoodUnitWeightKind kind) => FoodUnitWeight(
  foodName: 'Potato wedges',
  unit: 'piece',
  gramsPerUnit: 85,
  kind: kind,
  provenance: FoodProvenance(
    url: Uri.parse('https://example.com/wedges'),
    title: 'Wedge weight',
    retrievedAt: DateTime.utc(2026, 7, 18),
  ),
);

Future<AppDatabase> _openPotatoWedges(
  WidgetTester tester, {
  String unit = 'g',
  String amount = '2',
  PerHundred perHundred = const PerHundred(
    kcal: 150,
    protein: 2,
    carb: 25,
    fat: 4,
  ),
  _UnitWeightGrounder? grounder,
  bool cacheFood = true,
  NutritionBasis? basis,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final cache = FoodCacheRepository(db);
  if (cacheFood) {
    await cache.upsertOverride(
      FoodMacros(
        name: 'Potato wedges',
        perHundred: perHundred,
        source: MacroSource.manual,
        isEstimate: false,
        basis: basis,
      ),
    );
  }
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      foodLookupProvider.overrideWith(
        (ref) async => FoodLookup(
          cache: cache,
          off: OpenFoodFactsClient(),
          usda: UsdaClient(apiKey: ''),
          llm: _UnusedLlm(),
          webGrounder: grounder,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showAddFoodSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, 'Potato wedges');
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
  if (cacheFood) await tester.tap(find.text('Potato wedges').last);
  if (unit != 'g' || basis != null) {
    await tester.tap(find.byType(DropdownButton<FoodUnit>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(unit).last);
  }
  await tester.enterText(find.byType(TextField).at(1), amount);
  return db;
}
