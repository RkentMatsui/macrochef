import '../models/macros.dart';

class MacroCalculator {
  /// Whether this is credible nutrition expressed per 100 grams.
  ///
  /// The all-zero sentinel means "unknown" for basis-backed conversions, so it
  /// must not be used to invent a gram-based conversion. A basis-free food can
  /// still deliberately use zero values and is handled by its existing path.
  static bool hasUsablePerHundred(PerHundred p) {
    final core = [p.kcal, p.protein, p.carb, p.fat];
    if (core.any((value) => !value.isFinite || value < 0)) return false;
    if (p.kcal > 920 || p.protein > 100 || p.carb > 100 || p.fat > 100) {
      return false;
    }
    final fibre = p.fibre;
    if (fibre != null && (!fibre.isFinite || fibre < 0 || fibre > 100)) {
      return false;
    }
    return core.any((value) => value != 0);
  }

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
