import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/models/macros.dart';
import 'package:macrochef/services/nutrition/embedder.dart';
import 'package:macrochef/services/nutrition/food_row.dart';
import 'package:macrochef/services/nutrition/local_nutrition_db.dart';
import 'package:macrochef/services/nutrition/nutrition_retriever.dart';

FoodRow _row(int id, String name) => FoodRow(
  id: id,
  name: name,
  per: const PerHundred(kcal: 100, protein: 10, carb: 5, fat: 2),
);

class FakeDb implements LocalNutritionDb {
  final List<FoodRow> candidates;
  final Map<int, Float32List> vectors;

  @override
  final String embedderId;

  @override
  final int dim;

  FakeDb(
    this.candidates,
    this.vectors, {
    this.embedderId = 'fake-2',
    this.dim = 2,
  });

  @override
  List<FoodRow> ftsPrefilter(String query, {int limit = 50}) => candidates;

  @override
  Float32List vectorFor(int id) => vectors[id] ?? Float32List(dim);

  @override
  int get count => candidates.length;

  @override
  Future<void> close() async {}
}

class FakeEmbedder implements Embedder {
  final Float32List vec;

  @override
  final String id;

  @override
  final int dim;

  FakeEmbedder(this.vec, {this.id = 'fake-2', this.dim = 2});

  @override
  Future<Float32List> embed(String text) async => vec;
}

class ThrowingEmbedder implements Embedder {
  @override
  final String id;

  @override
  final int dim;

  ThrowingEmbedder({this.id = 'fake-2', this.dim = 2});

  @override
  Future<Float32List> embed(String text) async {
    throw StateError('embedder unavailable');
  }
}

Float32List f(List<double> xs) => Float32List.fromList(xs);

void main() {
  test('re-ranks candidates by cosine, best first', () async {
    final db = FakeDb(
      [_row(1, 'rice'), _row(2, 'chicken')],
      {
        1: f([0, 1]),
        2: f([1, 0]),
      },
    );
    final retriever = NutritionRetriever(
      db: db,
      embedder: FakeEmbedder(f([1, 0])),
    );

    final out = await retriever.retrieve('chicken');

    expect(out.first.row.id, 2);
    expect(out.first.score, closeTo(1.0, 1e-6));
  });

  test(
    'mismatched embedder metadata preserves FTS order with zero scores',
    () async {
      final db = FakeDb(
        [_row(1, 'rice'), _row(2, 'chicken')],
        {
          1: f([1, 0]),
          2: f([0, 1]),
        },
        embedderId: 'other',
      );
      final retriever = NutritionRetriever(
        db: db,
        embedder: FakeEmbedder(f([0, 1])),
      );

      final out = await retriever.retrieve('rice');

      expect(out.map((match) => match.row.id), [1, 2]);
      expect(out.map((match) => match.score), [0.0, 0.0]);
      expect(retriever.bestDirectHit(out), isNull);
    },
  );

  test(
    'same embedder id with mismatched dim preserves FTS order with zero scores',
    () async {
      final db = FakeDb(
        [_row(1, 'rice'), _row(2, 'chicken')],
        {
          1: f([1, 0]),
          2: f([0, 1]),
        },
        dim: 3,
      );
      final retriever = NutritionRetriever(
        db: db,
        embedder: FakeEmbedder(f([0, 1])),
      );

      final out = await retriever.retrieve('rice');

      expect(out.map((match) => match.row.id), [1, 2]);
      expect(out.map((match) => match.score), [0.0, 0.0]);
      expect(retriever.bestDirectHit(out), isNull);
    },
  );

  test('empty prefilter returns an empty result', () async {
    final db = FakeDb([], {});
    final retriever = NutritionRetriever(
      db: db,
      embedder: FakeEmbedder(f([1, 0])),
    );

    expect(await retriever.retrieve('nothing'), isEmpty);
  });

  test('embedder failure preserves FTS order with zero scores', () async {
    final db = FakeDb(
      [_row(1, 'rice'), _row(2, 'chicken')],
      {
        1: f([1, 0]),
        2: f([0, 1]),
      },
    );
    final retriever = NutritionRetriever(db: db, embedder: ThrowingEmbedder());

    final out = await retriever.retrieve('rice');

    expect(out.map((match) => match.row.id), [1, 2]);
    expect(out.map((match) => match.score), [0.0, 0.0]);
    expect(retriever.bestDirectHit(out), isNull);
  });

  test('bestDirectHit returns a row only at or above the threshold', () {
    final retriever = NutritionRetriever(
      db: FakeDb([], {}),
      embedder: FakeEmbedder(f([1, 0])),
    );

    expect(kDirectHitCosine, 0.82);
    expect(
      retriever.bestDirectHit([NutritionMatch(_row(1, 'rice'), 0.82)])?.id,
      1,
    );
    expect(
      retriever.bestDirectHit([
        NutritionMatch(_row(2, 'chicken'), 0.819999999999),
      ]),
      isNull,
    );
  });

  test('grounding top-K is five', () {
    expect(kGroundingTopK, 5);
  });
}
