// On-device validation of the nutrition-pack FTS5 prefilter against the phone's
// own native sqlite3 (the same engine the downloaded pack uses at runtime).
// Proves the multi-word fix works on-device, without needing the ~107 MB pack:
//
//   flutter test integration_test/fts_prefilter_test.dart -d <deviceId>
//
// Regression guard for the bug where a phrase-prefix MATCH ('"chicken breast"*')
// required the query words to be adjacent, so real USDA descriptions (which
// interleave descriptors) matched nothing and "the RAG found nothing".
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:macrochef/services/nutrition/local_nutrition_db.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FTS prefilter matches non-adjacent words on-device',
      (tester) async {
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
    insert.execute([3, 'Oil, olive, salad or cooking', blob]);
    insert.dispose();
    db.execute('INSERT INTO foods_fts(rowid, name) SELECT id, name FROM foods');
    final ndb = SqliteNutritionDb(db);
    addTearDown(ndb.close);

    List<int> ids(String q) => ndb.ftsPrefilter(q).map((r) => r.id).toList();

    // ignore: avoid_print
    print('ONDEVICE_FTS chicken breast=${ids('chicken breast')} '
        'white rice=${ids('white rice')} olive oil=${ids('olive oil')} '
        'breast chicken=${ids('breast chicken')} chicken tofu=${ids('chicken tofu')}');

    expect(ids('chicken breast'), contains(1));
    expect(ids('white rice'), contains(2));
    expect(ids('olive oil'), contains(3));
    expect(ids('breast chicken'), contains(1)); // order-independent
    expect(ids('chicken tofu'), isEmpty); // AND: absent word excludes
    expect(ids(''), isEmpty);
    expect(ids('-'), isEmpty);
  });
}
