import 'dart:io';

import 'package:macrochef/services/nutrition/onnx_minilm_embedder.dart';
import 'nutrition_pack_builder.dart';

Future<void> main(List<String> args) async {
  if (args.length != 5) {
    stderr.writeln(
      'Usage: dart run tool/build_nutrition_pack.dart <foundation-dir> <sr-dir> <model.onnx> <vocab.txt> <output.sqlite>',
    );
    exitCode = 64;
    return;
  }
  final embedder = OnnxMiniLmEmbedder(modelPath: args[2], vocabPath: args[3]);
  try {
    await buildNutritionPack(args[0], args[1], args[4], embedder);
  } finally {
    embedder.dispose();
  }
  stdout.writeln('Built ${args[4]} (${File(args[4]).lengthSync()} bytes)');
}
