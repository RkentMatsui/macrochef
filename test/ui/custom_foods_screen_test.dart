import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/data/repositories/food_cache_repository.dart';
import 'package:macrochef/data/repositories/settings_repository.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/state/providers.dart';
import 'package:macrochef/ui/settings/custom_foods_screen.dart';

void main() {
  const basis = NutritionBasis(
    quantity: 250,
    unit: 'ml',
    macros: MacroValues(kcal: 180, protein: 20, carb: 8, fat: 6),
  );

  Future<({AppDatabase db, FoodCacheRepository foods})> pumpScreen(
    WidgetTester tester, {
    required bool basisNeedsReview,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    final foods = FoodCacheRepository(db);
    await foods.upsertOverride(
      FoodMacros(
        name: 'Protein milk',
        perHundred: PerHundred.zero,
        source: MacroSource.manual,
        isEstimate: false,
        gramsPerPiece: 42,
        basis: basis,
        basisNeedsReview: basisNeedsReview,
      ),
    );
    addTearDown(db.close);

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CustomFoodsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return (db: db, foods: foods);
  }

  testWidgets('editing a custom food preserves its exact nutrition basis', (
    tester,
  ) async {
    final setup = await pumpScreen(tester, basisNeedsReview: false);

    expect(find.textContaining('per 250 ml'), findsOneWidget);
    await tester.tap(find.text('Protein milk'));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) => widget is TextField && widget.controller?.text == '250',
      ),
      findsOneWidget,
    );
    for (final value in ['180', '20', '8', '6']) {
      expect(
        find.byWidgetPredicate(
          (widget) => widget is TextField && widget.controller?.text == value,
        ),
        findsOneWidget,
      );
    }
    expect(find.text('ml'), findsOneWidget);

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final saved = await setup.foods.find('Protein milk');
    expect(saved!.basis!.quantity, 250);
    expect(saved.basis!.unit, 'ml');
    expect(saved.basis!.macros.kcal, 180);
    expect(saved.basis!.macros.protein, 20);
    expect(saved.basis!.macros.carb, 8);
    expect(saved.basis!.macros.fat, 6);
    expect(saved.gramsPerPiece, 42);
    expect(
      await SettingsRepository(setup.db).get('foodunit:protein milk'),
      'ml|250',
    );
  });

  testWidgets('saving a reviewed basis clears its review marker', (
    tester,
  ) async {
    final setup = await pumpScreen(tester, basisNeedsReview: true);

    expect(find.text('Review serving basis'), findsOneWidget);
    await tester.tap(find.text('Protein milk'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect((await setup.foods.find('Protein milk'))!.basisNeedsReview, isFalse);
    expect(find.text('Review serving basis'), findsNothing);
  });
}
