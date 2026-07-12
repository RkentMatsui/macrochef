// Dev harness that BUILDS the production nutrition pack on a Flutter desktop
// runtime (Windows), where the real MiniLM ONNX embedder can run and host files
// are directly readable/writable (no OOM on the phone, no adb-pull).
//
//   flutter test integration_test/build_pack_test.dart -d windows \
//     --dart-define=CACHE=<absolute-cache-dir>
//
// CACHE must contain: foundation/, sr_legacy/ (extracted FDC CSVs),
// model.onnx, vocab.txt. Output: <CACHE>/nutrition_pack.sqlite.
//
// CAVEAT: building the FULL app for Windows also compiles the secure-storage
// (needs the VS C++ "ATL" component) and local-notifications (260-char path
// limit) plugins. If those block the build, build the pack instead from a
// throwaway minimal-deps project (only onnxruntime + sqlite3 + csv + unorm_dart)
// at a short path — that avoids both. The v1 pack was built that way on
// 2026-07-12 (8170 foods, 17,129,472 bytes).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:macrochef/services/nutrition/onnx_minilm_embedder.dart';
import '../tool/nutrition_pack_builder.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const cache = String.fromEnvironment('CACHE');

  testWidgets('build production nutrition pack', (tester) async {
    expect(cache, isNotEmpty, reason: 'pass --dart-define=CACHE=<dir>');
    final output = '$cache/nutrition_pack.sqlite';
    final embedder = OnnxMiniLmEmbedder(
      modelPath: '$cache/model.onnx',
      vocabPath: '$cache/vocab.txt',
    );
    try {
      await buildNutritionPack(
        '$cache/foundation',
        '$cache/sr_legacy',
        output,
        embedder,
      );
    } finally {
      embedder.dispose();
    }
    final size = File(output).lengthSync();
    // ignore: avoid_print
    print('PACK_BUILT path=$output bytes=$size');
    expect(size, greaterThan(1024 * 1024),
        reason: 'a real pack of ~8k foods should be > 1 MB');
  }, timeout: const Timeout(Duration(minutes: 40)));
}
