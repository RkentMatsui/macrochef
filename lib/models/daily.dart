import 'macros.dart';

class DailyTarget {
  final double kcal, protein, carb, fat;
  const DailyTarget({
    required this.kcal,
    required this.protein,
    required this.carb,
    required this.fat,
  });
}

class DailyTotals {
  final MacroValues consumed;
  final DailyTarget? target;
  const DailyTotals(this.consumed, this.target);
}
