import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/food_cache_repository.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/providers/llm/llm_provider.dart';
import 'package:macrochef/services/food_db/open_food_facts_client.dart';
import 'package:macrochef/services/food_db/usda_client.dart';
import 'package:macrochef/services/food_lookup.dart';
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
