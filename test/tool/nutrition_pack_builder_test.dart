import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:macrochef/services/nutrition/embedder.dart';
import '../../tool/nutrition_pack_builder.dart';

class _FakeEmbedder implements Embedder {
  @override
  String get id => 'fixture-3';
  @override
  int get dim => 3;
  @override
  Future<Float32List> embed(String text) async =>
      Float32List.fromList([1, 2, 3]);
}

void main() {
  test(
    'parses quoted Foundation and SR rows with dataset energy rules',
    () async {
      final root = await Directory.systemTemp.createTemp('pack-fixture');
      addTearDown(() => root.delete(recursive: true));
      final foundation = Directory('${root.path}/foundation')..createSync();
      final sr = Directory('${root.path}/sr')..createSync();
      _writeFixture(foundation, 'foundation_food', foundationEnergy: true);
      _writeFixture(sr, 'sr_legacy_food', foundationEnergy: false, baseId: 10);
      final foods = await readFdcDatasets(foundation.path, sr.path);
      expect(
        foods.map((f) => f.name),
        containsAll(['Food, quoted', 'SR legacy food']),
      );
      expect(foods.first.kcal, 101); // Foundation 2048 wins over 2047/1008.
    },
  );

  test(
    'drops foods missing mandatory nutrients and writes fixed pack schema',
    () async {
      final root = await Directory.systemTemp.createTemp('pack-schema');
      addTearDown(() => root.delete(recursive: true));
      final foundation = Directory('${root.path}/foundation')..createSync();
      final sr = Directory('${root.path}/sr')..createSync();
      _writeFixture(
        foundation,
        'foundation_food',
        foundationEnergy: true,
        includeIncomplete: true,
      );
      _writeFixture(sr, 'sr_legacy_food', foundationEnergy: false, baseId: 10);
      final output = '${root.path}/pack.sqlite';
      await buildNutritionPack(
        foundation.path,
        sr.path,
        output,
        _FakeEmbedder(),
      );
      final db = sqlite3.open(output, mode: OpenMode.readOnly);
      addTearDown(db.dispose);
      expect(db.select('PRAGMA integrity_check').first.values.first, 'ok');
      expect(db.select('SELECT count(*) c FROM foods').first['c'], 2);
      expect(
        db.select('SELECT embedder_id,dim FROM meta').first['embedder_id'],
        'fixture-3',
      );
      expect(
        (db.select('SELECT vec FROM foods LIMIT 1').first['vec'] as Uint8List)
            .length,
        12,
      );
      expect(
        db
            .select(
              "SELECT count(*) c FROM foods_fts WHERE foods_fts MATCH 'quoted'",
            )
            .first['c'],
        1,
      );
    },
  );
}

void _writeFixture(
  Directory dir,
  String dataType, {
  required bool foundationEnergy,
  int baseId = 1,
  bool includeIncomplete = false,
}) {
  File('${dir.path}/food.csv').writeAsStringSync(
    'fdc_id,data_type,description\r\n$baseId,$dataType,"${baseId == 1 ? 'Food, quoted' : 'SR legacy food'}"\r\n'
    '${includeIncomplete ? '${baseId + 1},$dataType,Incomplete\r\n' : ''}',
  );
  File('${dir.path}/nutrient.csv').writeAsStringSync(
    'id,name,unit_name\r\n1003,Protein,G\r\n1004,Total lipid (fat),G\r\n1005,Carbohydrate, by difference,G\r\n1008,Energy,KCAL\r\n2047,Energy (Atwater General Factors),KCAL\r\n2048,Energy (Atwater Specific Factors),KCAL\r\n1079,Fiber, total dietary,G\r\n1093,Sodium, Na,MG\r\n',
  );
  final energy = foundationEnergy
      ? '1008,99\r\n$baseId,2047,100\r\n$baseId,2048,101'
      : '1008,88';
  File('${dir.path}/food_nutrient.csv').writeAsStringSync(
    'fdc_id,nutrient_id,amount\r\n$baseId,1003,2\r\n$baseId,1004,3\r\n$baseId,1005,4\r\n$baseId,$energy\r\n$baseId,1079,5\r\n$baseId,1093,6\r\n',
  );
}
