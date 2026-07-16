part of '../database.dart';

Future<void> migrateLegacyNutritionBases(AppDatabase db) async {
  final candidates =
      await (db.select(db.foodCache)..where(
            (f) =>
                f.userOverride.equals(true) &
                f.gramsPerPiece.equals(100) &
                f.basisQuantity.isNull(),
          ))
          .get();
  for (final row in candidates) {
    final setting =
        await (db.select(
              db.settings,
            )..where((s) => s.key.equals('foodunit:${row.name.toLowerCase()}')))
            .getSingleOrNull();
    if (setting == null) continue;
    final parts = setting.value.split('|');
    final unit = foodUnitByLabel(parts.first);
    if (unit == null || unit.family == FoodUnitFamily.mass) continue;
    final parsed = parts.length > 1 ? double.tryParse(parts[1]) : null;
    final recovered = parsed != null && parsed.isFinite && parsed > 0;
    final quantity = recovered ? parsed : 1.0;
    await (db.update(db.foodCache)..where((f) => f.id.equals(row.id))).write(
      FoodCacheCompanion(
        basisQuantity: Value(quantity),
        basisUnit: Value(unit.label),
        basisKcal: Value(row.kcal100 * quantity),
        basisProtein: Value(row.protein100 * quantity),
        basisCarb: Value(row.carb100 * quantity),
        basisFat: Value(row.fat100 * quantity),
        basisNeedsReview: Value(!recovered),
        gramsPerPiece: const Value(null),
      ),
    );
  }
}
