import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';

const sources = {
  'foundation.zip':
      'https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_foundation_food_csv_2026-04-30.zip',
  'sr_legacy.zip':
      'https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip',
  'model.onnx':
      'https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/1110a243fdf4706b3f48f1d95db1a4f5529b4d41/onnx/model.onnx',
  'vocab.txt':
      'https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/1110a243fdf4706b3f48f1d95db1a4f5529b4d41/vocab.txt',
};

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/prepare_nutrition_sources.dart <cache-dir>',
    );
    exitCode = 64;
    return;
  }
  final cache = Directory(args.single);
  await cache.create(recursive: true);
  for (final source in sources.entries) {
    await _download(cache, source.key, source.value);
  }
  await _verify(
    File('${cache.path}/model.onnx'),
    90405214,
    '6fd5d72fe4589f189f8ebc006442dbb529bb7ce38f8082112682524616046452',
  );
  final vocab = File('${cache.path}/vocab.txt');
  if (vocab.lengthSync() != 231508) {
    throw StateError('Unexpected vocab size: ${vocab.lengthSync()}');
  }
  for (final pair in [
    ('foundation.zip', 'foundation'),
    ('sr_legacy.zip', 'sr_legacy'),
  ]) {
    final target = Directory('${cache.path}/${pair.$2}');
    if (!target.existsSync()) {
      await target.create(recursive: true);
      await extractFileToDisk('${cache.path}/${pair.$1}', target.path);
    }
  }
}

Future<void> _download(Directory cache, String name, String url) async {
  final destination = File('${cache.path}/$name');
  if (destination.existsSync() && destination.lengthSync() > 0) return;
  final partial = File('${destination.path}.partial');
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException(
        'Download failed (${response.statusCode})',
        uri: Uri.parse(url),
      );
    }
    await response.pipe(partial.openWrite());
    await partial.rename(destination.path);
  } finally {
    client.close();
  }
}

Future<void> _verify(File file, int bytes, String expected) async {
  if (file.lengthSync() != bytes) {
    throw StateError('Unexpected model size: ${file.lengthSync()}');
  }
  final actual = (await sha256.bind(file.openRead()).first).toString();
  if (actual != expected) throw StateError('Unexpected model SHA256: $actual');
}
