import 'dart:io';
import 'dart:typed_data';

import 'package:sqlite3/sqlite3.dart';

import '../../models/macros.dart';
import 'food_row.dart';

/// Read-only access to a downloaded nutrition pack.
abstract class LocalNutritionDb {
  /// FTS5 lexical prefilter over food names; returns up to [limit] candidates.
  List<FoodRow> ftsPrefilter(String query, {int limit});

  /// The stored embedding vector for a food id.
  Float32List vectorFor(int id);

  /// Metadata for the embedding vectors stored in this pack.
  String get embedderId;
  int get dim;
  int get count;

  Future<void> close();
}

/// Reads a downloaded `nutrition_pack.sqlite` (foods + FTS5 + per-row vectors).
class SqliteNutritionDb implements LocalNutritionDb {
  final Database _db;

  @override
  late final String embedderId;

  @override
  late final int dim;

  SqliteNutritionDb(this._db) {
    final metadata = _db
        .select('SELECT embedder_id, dim FROM meta LIMIT 1')
        .first;
    embedderId = metadata['embedder_id'] as String;
    dim = metadata['dim'] as int;
  }

  /// Open the pack file read-only.
  factory SqliteNutritionDb.open(String path) =>
      SqliteNutritionDb(sqlite3.open(path, mode: OpenMode.readOnly));

  static bool exists(String path) => File(path).existsSync();

  @override
  List<FoodRow> ftsPrefilter(String query, {int limit = 50}) {
    // Match all tokens; escape quotes for the FTS query string.
    final safe = query.replaceAll('"', ' ').trim();
    if (safe.isEmpty) return const [];
    final rows = _db.select(
      'SELECT f.id,f.name,f.kcal,f.protein,f.carb,f.fat,f.fibre,f.sodium '
      'FROM foods_fts JOIN foods f ON f.id = foods_fts.rowid '
      'WHERE foods_fts MATCH ? ORDER BY rank LIMIT ?',
      ['"$safe"*', limit],
    );
    return [for (final row in rows) _toRow(row)];
  }

  FoodRow _toRow(Row row) => FoodRow(
    id: row['id'] as int,
    name: row['name'] as String,
    per: PerHundred(
      kcal: (row['kcal'] as num).toDouble(),
      protein: (row['protein'] as num).toDouble(),
      carb: (row['carb'] as num).toDouble(),
      fat: (row['fat'] as num).toDouble(),
      fibre: (row['fibre'] as num?)?.toDouble(),
      sodium: (row['sodium'] as num?)?.toDouble(),
    ),
  );

  @override
  Float32List vectorFor(int id) {
    final rows = _db.select('SELECT vec FROM foods WHERE id = ?', [id]);
    if (rows.isEmpty) return Float32List(dim);
    final blob = rows.first['vec'] as Uint8List;
    return Float32List.view(blob.buffer, blob.offsetInBytes, dim);
  }

  @override
  int get count => _db.select('SELECT count(*) c FROM foods').first['c'] as int;

  @override
  Future<void> close() async => _db.dispose();
}
