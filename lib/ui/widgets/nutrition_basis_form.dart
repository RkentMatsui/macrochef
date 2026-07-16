import 'package:flutter/material.dart';

import '../../models/macros.dart';
import '../../services/food_units.dart';

class NutritionBasisFormController extends ChangeNotifier {
  NutritionBasisFormController({NutritionBasis? initial})
    : quantity = TextEditingController(text: _format(initial?.quantity ?? 100)),
      kcal = TextEditingController(text: _format(initial?.macros.kcal ?? 0)),
      protein = TextEditingController(
        text: _format(initial?.macros.protein ?? 0),
      ),
      carb = TextEditingController(text: _format(initial?.macros.carb ?? 0)),
      fat = TextEditingController(text: _format(initial?.macros.fat ?? 0)),
      unit = foodUnitByLabel(initial?.unit ?? 'g') ?? kFoodUnits.first;

  final TextEditingController quantity;
  final TextEditingController kcal;
  final TextEditingController protein;
  final TextEditingController carb;
  final TextEditingController fat;
  late FoodUnit unit;
  String? quantityError;
  String? macroError;

  NutritionBasis? buildBasis() {
    final parsedQuantity = _parse(quantity);
    final macros = [_parse(kcal), _parse(protein), _parse(carb), _parse(fat)];

    quantityError = parsedQuantity == null || parsedQuantity <= 0
        ? 'Enter a quantity greater than zero.'
        : null;
    macroError = macros.any((value) => value == null || value < 0)
        ? 'Enter valid macro values.'
        : macros.every((value) => value == 0)
        ? 'Enter at least one macro value.'
        : null;
    notifyListeners();

    if (quantityError != null || macroError != null) return null;
    return NutritionBasis(
      quantity: parsedQuantity!,
      unit: unit.label,
      macros: MacroValues(
        kcal: macros[0]!,
        protein: macros[1]!,
        carb: macros[2]!,
        fat: macros[3]!,
      ),
    );
  }

  void setUnit(FoodUnit value) {
    if (unit.label == value.label) return;
    unit = value;
    notifyListeners();
  }

  @override
  void dispose() {
    quantity.dispose();
    kcal.dispose();
    protein.dispose();
    carb.dispose();
    fat.dispose();
    super.dispose();
  }

  static double? _parse(TextEditingController controller) {
    final value = double.tryParse(controller.text.trim());
    return value != null && value.isFinite ? value : null;
  }

  static String _format(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();
}

class NutritionBasisForm extends StatelessWidget {
  const NutritionBasisForm({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  final NutritionBasisFormController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Macros are per'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.quantity,
                  enabled: enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'quantity',
                    errorText: controller.quantityError,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<FoodUnit>(
                  value: controller.unit,
                  isExpanded: true,
                  onChanged: enabled
                      ? (value) {
                          if (value != null) controller.setUnit(value);
                        }
                      : null,
                  items: kFoodUnits
                      .map(
                        (unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit.label),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MacroField(
            controller: controller.kcal,
            label: 'Calories',
            enabled: enabled,
            errorText: controller.macroError,
          ),
          _MacroField(
            controller: controller.protein,
            label: 'Protein',
            enabled: enabled,
          ),
          _MacroField(
            controller: controller.carb,
            label: 'Carbs',
            enabled: enabled,
          ),
          _MacroField(
            controller: controller.fat,
            label: 'Fat',
            enabled: enabled,
          ),
        ],
      ),
    );
  }
}

class _MacroField extends StatelessWidget {
  const _MacroField({
    required this.controller,
    required this.label,
    required this.enabled,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, errorText: errorText),
      ),
    );
  }
}
