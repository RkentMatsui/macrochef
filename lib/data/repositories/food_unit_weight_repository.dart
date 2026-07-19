import 'package:drift/drift.dart';

import '../../models/food_unit_weight.dart';
import '../../models/macros.dart';
import '../database.dart';

/// Normalizes the durable key without aliasing one unit label to another.
({String foodKey, String unit}) normalizeFoodUnitWeightKey(
  String foodName,
  String unit,
) => (foodKey: foodName.trim().toLowerCase(), unit: unit.trim().toLowerCase());

class FoodUnitWeightRepository {
  final AppDatabase db;
  FoodUnitWeightRepository(this.db);

  Future<FoodUnitWeight?> find(String foodName, String unit) async {
    final key = normalizeFoodUnitWeightKey(foodName, unit);
    final row =
        await (db.select(db.foodUnitWeights)..where(
              (t) => t.foodKey.equals(key.foodKey) & t.unit.equals(key.unit),
            ))
            .getSingleOrNull();
    return row == null ? null : _toWeight(row);
  }

  Future<void> upsert(FoodUnitWeight weight) async {
    final key = normalizeFoodUnitWeightKey(weight.foodName, weight.unit);
    await db
        .into(db.foodUnitWeights)
        .insertOnConflictUpdate(
          FoodUnitWeightsCompanion.insert(
            foodKey: key.foodKey,
            foodName: weight.foodName,
            unit: key.unit,
            gramsPerUnit: weight.gramsPerUnit,
            kind: weight.kind.name,
            sourceUrl: weight.provenance.url.toString(),
            sourceTitle: weight.provenance.title,
            sourceRetrievedAt: weight.provenance.retrievedAt,
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Unit-weight evidence is always auto-grounded, so a food-data refresh may
  /// discard every row without affecting manually owned nutrition rows.
  Future<int> clearAutoSourced() => db.delete(db.foodUnitWeights).go();

  FoodUnitWeight? _toWeight(FoodUnitWeightRow row) {
    final kind = FoodUnitWeightKind.values.where((k) => k.name == row.kind);
    if (kind.isEmpty) return null;
    final provenance = FoodProvenance(
      url: Uri.tryParse(row.sourceUrl) ?? Uri(),
      title: row.sourceTitle,
      retrievedAt: row.sourceRetrievedAt,
    );
    if (!provenance.isValid) return null;
    final result = FoodUnitWeight(
      foodName: row.foodName,
      unit: row.unit,
      gramsPerUnit: row.gramsPerUnit,
      kind: kind.single,
      provenance: provenance,
    );
    return result.isValid ? result : null;
  }
}
