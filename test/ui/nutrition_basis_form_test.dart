import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/services/food_units.dart';
import 'package:macrochef/ui/widgets/nutrition_basis_form.dart';

void main() {
  const initial = NutritionBasis(
    quantity: 250,
    unit: 'ml',
    macros: MacroValues(kcal: 180, protein: 20, carb: 8, fat: 6),
  );

  test('prefills the initial basis and changes units', () {
    final controller = NutritionBasisFormController(initial: initial);
    addTearDown(controller.dispose);

    expect(controller.quantity.text, '250');
    expect(controller.unit.label, 'ml');
    expect(controller.kcal.text, '180');
    expect(controller.protein.text, '20');
    expect(controller.carb.text, '8');
    expect(controller.fat.text, '6');

    controller.setUnit(kFoodUnits.firstWhere((unit) => unit.label == 'cup'));

    expect(controller.unit.label, 'cup');
  });

  test(
    'rejects zero and non-finite quantities without clearing typed values',
    () {
      final controller = NutritionBasisFormController(initial: initial);
      addTearDown(controller.dispose);
      controller.quantity.text = '0';

      expect(controller.buildBasis(), isNull);
      expect(controller.quantityError, isNotNull);
      expect(controller.quantity.text, '0');

      controller.quantity.text = 'NaN';

      expect(controller.buildBasis(), isNull);
      expect(controller.quantityError, isNotNull);
      expect(controller.quantity.text, 'NaN');
    },
  );

  test('rejects all-zero macros without clearing typed values', () {
    final controller = NutritionBasisFormController(initial: initial);
    addTearDown(controller.dispose);
    controller.kcal.text = '0';
    controller.protein.text = '0';
    controller.carb.text = '0';
    controller.fat.text = '0';

    expect(controller.buildBasis(), isNull);
    expect(controller.macroError, isNotNull);
    expect(controller.kcal.text, '0');
    expect(controller.protein.text, '0');
    expect(controller.carb.text, '0');
    expect(controller.fat.text, '0');
  });

  testWidgets('renders basis copy, quantity, units, and macro fields', (
    tester,
  ) async {
    final controller = NutritionBasisFormController(initial: initial);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NutritionBasisForm(controller: controller)),
      ),
    );

    expect(find.text('Macros are per'), findsOneWidget);
    expect(find.text('quantity'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<FoodUnit>), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Calories'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Protein'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Carbs'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Fat'), findsOneWidget);
  });
}
