import '../../models/macros.dart';

/// One food from the local nutrition pack.
class FoodRow {
  final int id;
  final String name; // USDA description
  final PerHundred per;
  const FoodRow({required this.id, required this.name, required this.per});
}

/// A retrieved food with its similarity score (0.0 when semantic re-rank was
/// skipped — e.g. embedder/pack mismatch — so it can never count as a direct hit).
class NutritionMatch {
  final FoodRow row;
  final double score;
  const NutritionMatch(this.row, this.score);
}
