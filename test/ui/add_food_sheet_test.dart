import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/ui/daily/daily_log_screen.dart';

void main() {
  testWidgets('Add food sheet opens and renders the quantity + unit selector',
      (tester) async {
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
    expect(
      find.byWidgetPredicate((w) => w is DropdownButton),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
