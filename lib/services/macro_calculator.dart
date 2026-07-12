import '../models/macros.dart';

class MacroCalculator {
  static MacroValues forGrams(PerHundred p, double grams) {
    final f = grams / 100.0;
    return MacroValues(
      kcal: p.kcal * f,
      protein: p.protein * f,
      carb: p.carb * f,
      fat: p.fat * f,
      fibre: p.fibre != null ? p.fibre! * f : null,
    );
  }
}
