import 'dart:typed_data';

import 'cosine.dart';
import 'embedder.dart';
import 'food_row.dart';
import 'local_nutrition_db.dart';

/// Cosine at or above which a retrieved food is trusted as an exact match.
const double kDirectHitCosine = 0.82;

/// How many top matches to feed the LLM when grounding a miss.
const int kGroundingTopK = 5;

/// Hybrid retrieval: FTS5 prefilter, query embedding, then cosine re-ranking.
class NutritionRetriever {
  final LocalNutritionDb db;
  final Embedder embedder;

  NutritionRetriever({required this.db, required this.embedder});

  Future<List<NutritionMatch>> retrieve(
    String query, {
    int candidates = 50,
  }) async {
    final rows = db.ftsPrefilter(query, limit: candidates);
    if (rows.isEmpty) return const [];

    late final Float32List queryVector;
    try {
      final compatible = embedder.id == db.embedderId && embedder.dim == db.dim;
      if (!compatible) return _lexicalMatches(rows);
      queryVector = await embedder.embed(query);
    } on Object {
      return _lexicalMatches(rows);
    }

    final scored = [
      for (final row in rows)
        NutritionMatch(row, cosine(queryVector, db.vectorFor(row.id))),
    ]..sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }

  /// The single trusted exact match, or null below the direct-hit threshold.
  FoodRow? bestDirectHit(List<NutritionMatch> matches) {
    if (matches.isEmpty) return null;
    final best = matches.first;
    return best.score >= kDirectHitCosine ? best.row : null;
  }

  List<NutritionMatch> _lexicalMatches(List<FoodRow> rows) => [
    for (final row in rows) NutritionMatch(row, 0.0),
  ];
}
