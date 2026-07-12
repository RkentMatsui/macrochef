import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/data/database.dart';
import 'package:macrochef/models/daily.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/state/providers.dart';
import 'package:macrochef/ui/reports/reports_screen.dart';

void main() {
  testWidgets('ReportsScreen renders sections and toggles range', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());

    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ]);
    addTearDown(container.dispose);

    final svc = container.read(dailyLogServiceProvider);
    await svc.setTarget(
        const DailyTarget(kcal: 2000, protein: 150, carb: 200, fat: 60));
    await svc.log(todayDate(),
        name: 'Chicken',
        grams: 200,
        macros: const MacroValues(kcal: 330, protein: 62, carb: 0, fat: 7),
        source: MacroSource.manual);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ReportsScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('Daily macro averages'), findsOneWidget);
    expect(find.text('Top foods'), findsOneWidget);
    expect(find.text('Chicken'), findsOneWidget);
    expect(find.text('1× logged'), findsOneWidget);

    await tester.tap(find.text('Last 30 days'));
    await tester.pumpAndSettle();
    expect(find.text('Calories'), findsOneWidget);
  });
}
