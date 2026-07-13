import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/nutrition/local_nutrition_db.dart';
import 'package:sqlite3/sqlite3.dart';

/// Build a minimal in-memory pack matching the real schema, then read it back.
Database _buildPack() {
  final db = sqlite3.openInMemory();
  db.execute('''
    CREATE TABLE meta(embedder_id TEXT, dim INTEGER);
    CREATE TABLE foods(id INTEGER PRIMARY KEY, name TEXT, kcal REAL, protein REAL,
      carb REAL, fat REAL, fibre REAL, sodium REAL, vec BLOB);
    CREATE VIRTUAL TABLE foods_fts USING fts5(name, content='foods', content_rowid='id');
  ''');
  db.execute("INSERT INTO meta VALUES ('tfidf-4', 4)");

  void insert(int id, String name, List<double> vector) {
    final blob = Uint8List.view(Float32List.fromList(vector).buffer);
    final statement = db.prepare(
      'INSERT INTO foods(id,name,kcal,protein,carb,fat,fibre,sodium,vec) '
      'VALUES(?,?,?,?,?,?,?,?,?)',
    );
    statement.execute([id, name, 165, 31, 0, 3.6, null, null, blob]);
    statement.dispose();
  }

  insert(1, 'Chicken breast grilled', [1, 0, 0, 0]);
  insert(2, 'White rice cooked', [0, 1, 0, 0]);
  db.execute('INSERT INTO foods_fts(rowid, name) SELECT id, name FROM foods');
  return db;
}

void main() {
  test('reads metadata, macros, count, FTS hits, and vectors', () async {
    final ndb = SqliteNutritionDb(_buildPack());
    addTearDown(ndb.close);

    expect(ndb.embedderId, 'tfidf-4');
    expect(ndb.dim, 4);
    expect(ndb.count, 2);

    final hits = ndb.ftsPrefilter('chicken', limit: 10);
    expect(hits.map((row) => row.id), contains(1));
    expect(hits.first.per.protein, 31);

    final vector = ndb.vectorFor(1);
    expect(vector.length, 4);
    expect(vector[0], 1.0);
  });

  test(
    'safely handles multi-word prefixes and quote-containing input',
    () async {
      final ndb = SqliteNutritionDb(_buildPack());
      addTearDown(ndb.close);

      expect(ndb.ftsPrefilter('chicken bre').single.id, 1);
      expect(ndb.ftsPrefilter('"chicken" bre').single.id, 1);
    },
  );

  // Regression: real USDA descriptions interleave descriptors, so the words of
  // a natural query are almost never adjacent. A phrase-prefix query required
  // adjacency and returned nothing for essentially every real lookup — the RAG
  // "found nothing". The prefilter must AND per-word prefixes instead.
  test('matches non-adjacent words in real USDA descriptions', () async {
    final db = sqlite3.openInMemory();
    db.execute('''
      CREATE TABLE meta(embedder_id TEXT, dim INTEGER);
      CREATE TABLE foods(id INTEGER PRIMARY KEY, name TEXT, kcal REAL, protein REAL,
        carb REAL, fat REAL, fibre REAL, sodium REAL, vec BLOB);
      CREATE VIRTUAL TABLE foods_fts USING fts5(name, content='foods', content_rowid='id');
    ''');
    db.execute("INSERT INTO meta VALUES ('minilm-l6-v2-384', 384)");
    final blob = Uint8List.view(Float32List(384).buffer);
    final insert = db.prepare(
      'INSERT INTO foods(id,name,kcal,protein,carb,fat,fibre,sodium,vec) '
      'VALUES(?,?,165,31,0,3.6,null,null,?)',
    );
    insert.execute(
      [1, 'Chicken, broilers or fryers, breast, meat only, cooked, roasted', blob],
    );
    insert.execute([2, 'Rice, white, long-grain, regular, cooked', blob]);
    insert.dispose();
    db.execute('INSERT INTO foods_fts(rowid, name) SELECT id, name FROM foods');
    final ndb = SqliteNutritionDb(db);
    addTearDown(ndb.close);

    expect(ndb.ftsPrefilter('chicken breast').map((r) => r.id), contains(1));
    expect(ndb.ftsPrefilter('white rice').map((r) => r.id), contains(2));
    // Order-independent, and an absent word filters the row out.
    expect(ndb.ftsPrefilter('breast chicken').map((r) => r.id), contains(1));
    expect(ndb.ftsPrefilter('chicken tofu'), isEmpty);
    // Degenerate input must not throw.
    expect(ndb.ftsPrefilter(''), isEmpty);
    expect(ndb.ftsPrefilter('-'), isEmpty);
  });
}
