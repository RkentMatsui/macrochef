import 'dart:convert';

import 'package:drift/drift.dart';
import '../database.dart';
import '../../models/macros.dart';

class FoodCacheRepository {
  final AppDatabase db;
  FoodCacheRepository(this.db);

  /// Case-insensitive exact-name lookup. User overrides (userOverride=true) are
  /// preferred by ordering them first (desc on bool maps to 1 before 0).
  Future<FoodMacros?> find(String name) async {
    final row =
        await (db.select(db.foodCache)
              ..where((t) => t.name.lower().equals(name.toLowerCase()))
              ..orderBy([
                (t) => OrderingTerm.desc(t.userOverride),
                (t) => OrderingTerm.desc(t.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    return _toMacros(row);
  }

  /// Insert a non-override cache row (sourced from OFF/USDA/local DB/AI). Replaces any
  /// existing non-override rows for the same name first, so re-resolving a food
  /// doesn't pile up duplicate rows. User overrides are left untouched.
  Future<void> put(FoodMacros m) async {
    await db.transaction(() async {
      await (db.delete(db.foodCache)..where(
            (t) =>
                t.name.lower().equals(m.name.toLowerCase()) &
                t.userOverride.equals(false),
          ))
          .go();
      await db
          .into(db.foodCache)
          .insert(
            FoodCacheCompanion.insert(
              name: m.name,
              source: m.source.name,
              kcal100: m.perHundred.kcal,
              protein100: m.perHundred.protein,
              carb100: m.perHundred.carb,
              fat100: m.perHundred.fat,
              fibre100: Value(m.perHundred.fibre),
              sodium100: Value(m.perHundred.sodium),
              isEstimate: Value(m.isEstimate),
              gramsPerPiece: Value(m.gramsPerPiece),
              basisQuantity: Value(m.basis?.quantity),
              basisUnit: Value(m.basis?.unit),
              basisKcal: Value(m.basis?.macros.kcal),
              basisProtein: Value(m.basis?.macros.protein),
              basisCarb: Value(m.basis?.macros.carb),
              basisFat: Value(m.basis?.macros.fat),
              basisPhysicalGrams: Value(m.basisPhysicalGrams),
              basisNeedsReview: Value(m.basisNeedsReview),
              sourceUrl: Value(m.provenance?.url.toString()),
              sourceTitle: Value(m.provenance?.title),
              sourceRetrievedAt: Value(m.provenance?.retrievedAt),
              sourceInferredFields: Value(_encodeInferredFields(m.provenance)),
            ),
          );
    });
  }

  /// Remembers the typical grams of one piece/unit for a food (across all rows
  /// for that name, case-insensitive). No-op if the food isn't cached yet.
  Future<void> setGramsPerPiece(String name, double grams) async {
    await (db.update(db.foodCache)
          ..where((t) => t.name.lower().equals(name.toLowerCase())))
        .write(FoodCacheCompanion(gramsPerPiece: Value(grams)));
  }

  /// Insert or replace a user override. Deletes any existing rows for the same
  /// name (case-insensitive) and inserts a fresh override row — guaranteeing a
  /// single row per food name that always wins in [find].
  Future<void> upsertOverride(FoodMacros m) async {
    await db.transaction(() async {
      await (db.delete(
        db.foodCache,
      )..where((t) => t.name.lower().equals(m.name.toLowerCase()))).go();
      await db
          .into(db.foodCache)
          .insert(
            FoodCacheCompanion.insert(
              name: m.name,
              source: MacroSource.manual.name,
              kcal100: m.perHundred.kcal,
              protein100: m.perHundred.protein,
              carb100: m.perHundred.carb,
              fat100: m.perHundred.fat,
              fibre100: Value(m.perHundred.fibre),
              sodium100: Value(m.perHundred.sodium),
              isEstimate: Value(m.isEstimate),
              userOverride: const Value(true),
              gramsPerPiece: Value(m.gramsPerPiece),
              basisQuantity: Value(m.basis?.quantity),
              basisUnit: Value(m.basis?.unit),
              basisKcal: Value(m.basis?.macros.kcal),
              basisProtein: Value(m.basis?.macros.protein),
              basisCarb: Value(m.basis?.macros.carb),
              basisFat: Value(m.basis?.macros.fat),
              basisPhysicalGrams: Value(m.basisPhysicalGrams),
              basisNeedsReview: Value(m.basisNeedsReview),
              sourceUrl: Value(m.provenance?.url.toString()),
              sourceTitle: Value(m.provenance?.title),
              sourceRetrievedAt: Value(m.provenance?.retrievedAt),
              sourceInferredFields: Value(_encodeInferredFields(m.provenance)),
            ),
          );
    });
  }

  /// Returns all user-defined override rows, sorted alphabetically by name.
  Future<List<FoodMacros>> listOverrides() async {
    final rows =
        await (db.select(db.foodCache)
              ..where((t) => t.userOverride.equals(true))
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .get();
    return rows.map(_toMacros).toList();
  }

  /// Up to [limit] cached foods whose name contains [query] (case-insensitive),
  /// user overrides first. Empty query returns all overrides. Powers autocomplete.
  Future<List<FoodMacros>> search(String query, {int limit = 8}) async {
    if (query.trim().isEmpty) return listOverrides();
    final rows =
        await (db.select(db.foodCache)
              ..where((t) => t.name.lower().contains(query.toLowerCase()))
              ..orderBy([
                (t) => OrderingTerm.desc(t.userOverride),
                (t) => OrderingTerm.asc(t.name),
              ])
              ..limit(limit))
            .get();
    return rows.map(_toMacros).toList();
  }

  /// Deletes every auto-sourced cache row, keeping user overrides.
  /// Used by "Refresh food data" so stale/bad values re-resolve via the current
  /// lookup order. Returns the number of rows removed.
  Future<int> clearNonOverrides() {
    return (db.delete(
      db.foodCache,
    )..where((t) => t.userOverride.equals(false))).go();
  }

  /// Deletes all cached rows for the given name (case-insensitive).
  Future<void> deleteByName(String name) async {
    await (db.delete(
      db.foodCache,
    )..where((t) => t.name.lower().equals(name.toLowerCase()))).go();
  }

  FoodMacros _toMacros(FoodCacheData row) => FoodMacros(
    name: row.name,
    perHundred: PerHundred(
      kcal: row.kcal100,
      protein: row.protein100,
      carb: row.carb100,
      fat: row.fat100,
      fibre: row.fibre100,
      sodium: row.sodium100,
    ),
    source: MacroSource.values.byName(row.source),
    isEstimate: row.isEstimate,
    gramsPerPiece: row.gramsPerPiece,
    basis: _basis(row),
    basisNeedsReview: row.basisNeedsReview,
    provenance: _provenance(row),
    basisPhysicalGrams: row.basisPhysicalGrams,
  );

  String? _encodeInferredFields(FoodProvenance? provenance) {
    if (provenance == null) return null;
    final fields = provenance.inferredFields.toList()..sort();
    return jsonEncode(fields);
  }

  FoodProvenance? _provenance(FoodCacheData row) {
    final url = row.sourceUrl;
    final title = row.sourceTitle;
    final retrievedAt = row.sourceRetrievedAt;
    if (url == null || title == null || retrievedAt == null) return null;

    final parsedUrl = Uri.tryParse(url);
    if (parsedUrl == null) return null;
    final provenance = FoodProvenance(
      url: parsedUrl,
      title: title,
      retrievedAt: retrievedAt,
      inferredFields: _decodeInferredFields(row.sourceInferredFields),
    );
    return provenance.isValid ? provenance : null;
  }

  Set<String> _decodeInferredFields(String? encoded) {
    if (encoded == null || encoded.isEmpty) return const {};
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const {};
      return decoded.whereType<String>().toSet();
    } on FormatException {
      return const {};
    }
  }

  NutritionBasis? _basis(FoodCacheData row) {
    if (row.basisUnit == null ||
        row.basisQuantity == null ||
        row.basisKcal == null ||
        row.basisProtein == null ||
        row.basisCarb == null ||
        row.basisFat == null) {
      return null;
    }
    if (!row.basisQuantity!.isFinite || row.basisQuantity! <= 0) return null;
    return NutritionBasis(
      quantity: row.basisQuantity!,
      unit: row.basisUnit!,
      macros: MacroValues(
        kcal: row.basisKcal!,
        protein: row.basisProtein!,
        carb: row.basisCarb!,
        fat: row.basisFat!,
      ),
    );
  }
}
