import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:macrochef/services/nutrition/embedder.dart';

class PackFood {
  final int id;
  final String name;
  final double kcal, protein, carb, fat;
  final double? fibre, sodium;
  const PackFood(
    this.id,
    this.name,
    this.kcal,
    this.protein,
    this.carb,
    this.fat,
    this.fibre,
    this.sodium,
  );
}

Future<List<PackFood>> readFdcDatasets(String foundation, String sr) async => [
  ...await _readDataset(Directory(foundation), foundation: true),
  ...await _readDataset(Directory(sr), foundation: false),
];

Future<List<PackFood>> _readDataset(
  Directory dir, {
  required bool foundation,
}) async {
  final foodsFile = _csv(dir, 'food.csv');
  final nutrientsFile = _csv(dir, 'nutrient.csv');
  final foodNutrientsFile = _csv(dir, 'food_nutrient.csv');
  final foodsRows = await _rows(foodsFile);
  final nutrientRows = await _rows(nutrientsFile);
  final foodNutrientRows = await _rows(foodNutrientsFile);
  // FDC food.csv data_type values: 'foundation_food' and 'sr_legacy_food'
  // (underscored). food.csv in the Foundation export also holds unrelated rows
  // (agricultural_acquisition, market_acquisition, sample_food, sub_sample_food)
  // that must be excluded — hence an exact match, not a substring.
  final allowedType = foundation ? 'foundation_food' : 'sr_legacy_food';
  final names = <int, String>{};
  for (final row in foodsRows) {
    final type = (row['data_type'] ?? '').toLowerCase();
    if (type != allowedType) continue;
    names[int.parse(row['fdc_id']!)] = row['description']!;
  }
  final units = <int, String>{};
  for (final row in nutrientRows) {
    units[int.parse(row['id']!)] = (row['unit_name'] ?? '').toLowerCase();
  }
  final values = <int, Map<int, double>>{};
  for (final row in foodNutrientRows) {
    final foodId = int.tryParse(row['fdc_id'] ?? '');
    final nutrientId = int.tryParse(row['nutrient_id'] ?? '');
    final amount = double.tryParse(row['amount'] ?? '');
    if (foodId == null ||
        nutrientId == null ||
        amount == null ||
        !names.containsKey(foodId)) {
      continue;
    }
    values.putIfAbsent(foodId, () => {})[nutrientId] = amount;
  }
  final result = <PackFood>[];
  for (final entry in names.entries) {
    final n = values[entry.key] ?? const <int, double>{};
    final energyIds = foundation ? const [2048, 2047, 1008] : const [1008];
    double? kcal;
    for (final id in energyIds) {
      if (n[id] != null && units[id] == 'kcal') {
        kcal = n[id];
        break;
      }
    }
    if (kcal == null || n[1003] == null || n[1005] == null || n[1004] == null) {
      continue;
    }
    result.add(
      PackFood(
        entry.key,
        entry.value,
        kcal,
        n[1003]!,
        n[1005]!,
        n[1004]!,
        n[1079],
        n[1093],
      ),
    );
  }
  return result;
}

File _csv(Directory root, String name) {
  final matches = root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.uri.pathSegments.last.toLowerCase() == name)
      .toList();
  if (matches.length != 1) {
    throw StateError(
      'Expected exactly one $name under ${root.path}, found ${matches.length}',
    );
  }
  return matches.single;
}

Future<List<Map<String, String>>> _rows(File file) async {
  final table = const CsvToListConverter(
    shouldParseNumbers: false,
    eol: '\n',
  ).convert(await file.readAsString());
  if (table.isEmpty) return [];
  final headers = table.first.map((v) => v.toString().trim()).toList();
  return [
    for (final raw in table.skip(1))
      if (raw.any((v) => v.toString().trim().isNotEmpty))
        {
          for (var i = 0; i < headers.length; i++)
            headers[i]: i < raw.length ? raw[i].toString().trim() : '',
        },
  ];
}

Future<void> buildNutritionPack(
  String foundation,
  String sr,
  String output,
  Embedder embedder,
) async {
  final foods = await readFdcDatasets(foundation, sr);
  final file = File(output);
  await file.parent.create(recursive: true);
  if (file.existsSync()) file.deleteSync();
  final db = sqlite3.open(output);
  try {
    db.execute(
      'PRAGMA journal_mode=OFF; PRAGMA synchronous=OFF; BEGIN; CREATE TABLE meta(embedder_id TEXT NOT NULL, dim INTEGER NOT NULL); CREATE TABLE foods(id INTEGER PRIMARY KEY, name TEXT NOT NULL, kcal REAL NOT NULL, protein REAL NOT NULL, carb REAL NOT NULL, fat REAL NOT NULL, fibre REAL, sodium REAL, vec BLOB NOT NULL); CREATE VIRTUAL TABLE foods_fts USING fts5(name, content="foods", content_rowid="id");',
    );
    db.execute('INSERT INTO meta(embedder_id,dim) VALUES(?,?)', [
      embedder.id,
      embedder.dim,
    ]);
    final insert = db.prepare('INSERT INTO foods VALUES(?,?,?,?,?,?,?,?,?)');
    try {
      for (final food in foods) {
        final vector = await embedder.embed(food.name);
        if (vector.length != embedder.dim) {
          throw StateError('Embedding dimension mismatch for ${food.name}');
        }
        insert.execute([
          food.id,
          food.name,
          food.kcal,
          food.protein,
          food.carb,
          food.fat,
          food.fibre,
          food.sodium,
          Uint8List.view(
            vector.buffer,
            vector.offsetInBytes,
            vector.lengthInBytes,
          ),
        ]);
      }
    } finally {
      insert.dispose();
    }
    db.execute(
      "INSERT INTO foods_fts(foods_fts) VALUES('rebuild'); COMMIT; VACUUM;",
    );
  } catch (_) {
    try {
      db.execute('ROLLBACK');
    } catch (_) {}
    rethrow;
  } finally {
    db.dispose();
  }
}
