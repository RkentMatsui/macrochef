// On-device validation of the real MiniLM ONNX embedder — the one unit that
// cannot run on the host test VM (needs the native ONNX runtime) and had never
// actually executed anywhere.
//
//   flutter test integration_test/onnx_embedder_test.dart -d <deviceId>
//
// The model + vocab are fetched on-device into the app support dir on first run
// (cached across runs by the OS only while installed; `flutter test`
// uninstalls afterwards, so each fresh run re-downloads ~90 MB — needs Wi-Fi).
// This is a dev/validation harness, excluded from the host `flutter test` suite.
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:macrochef/services/nutrition/onnx_minilm_embedder.dart';

const _modelUrl =
    'https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/'
    '1110a243fdf4706b3f48f1d95db1a4f5529b4d41/onnx/model.onnx';
const _vocabUrl =
    'https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2/resolve/'
    '1110a243fdf4706b3f48f1d95db1a4f5529b4d41/vocab.txt';

Future<String> _ensure(String url, String path, int expectedBytes) async {
  final file = File(path);
  if (await file.exists() && await file.length() == expectedBytes) {
    return path;
  }
  await file.parent.create(recursive: true);
  final client = HttpClient();
  try {
    final resp = await (await client.getUrl(Uri.parse(url))).close();
    if (resp.statusCode != 200) {
      throw StateError('Download failed (${resp.statusCode}) for $url');
    }
    await resp.pipe(file.openWrite());
  } finally {
    client.close();
  }
  final got = await file.length();
  if (got != expectedBytes) {
    throw StateError('Downloaded $path is $got bytes, expected $expectedBytes');
  }
  return path;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  double dot(List<double> a, List<double> b) {
    var s = 0.0;
    for (var i = 0; i < a.length; i++) {
      s += a[i] * b[i];
    }
    return s;
  }

  testWidgets('MiniLM ONNX embedder runs on-device and embeds semantically',
      (tester) async {
    final dir = (await getApplicationSupportDirectory()).path;
    final modelPath =
        await _ensure(_modelUrl, p.join(dir, 'minilm', 'model.onnx'), 90405214);
    final vocabPath =
        await _ensure(_vocabUrl, p.join(dir, 'minilm', 'vocab.txt'), 231508);

    final embedder =
        OnnxMiniLmEmbedder(modelPath: modelPath, vocabPath: vocabPath);
    addTearDown(embedder.dispose);

    final chicken = await embedder.embed('chicken breast');
    expect(chicken.length, 384, reason: 'all-MiniLM-L6-v2 is 384-d');
    final norm = sqrt(chicken.fold<double>(0, (s, x) => s + x * x));
    expect(norm, closeTo(1.0, 1e-3), reason: 'vectors are L2-normalised');

    final grilledChicken = await embedder.embed('grilled chicken breast');
    final rice = await embedder.embed('white rice, cooked');
    final aubergine = await embedder.embed('aubergine');
    final eggplant = await embedder.embed('eggplant');

    final chickenGrilled = dot(chicken, grilledChicken);
    final chickenRice = dot(chicken, rice);
    final aubergineEggplant = dot(aubergine, eggplant);
    final aubergineRice = dot(aubergine, rice);

    // ignore: avoid_print
    print(
      'ONNX_SIM chicken~grilled=${chickenGrilled.toStringAsFixed(3)} '
      'chicken~rice=${chickenRice.toStringAsFixed(3)} '
      'aubergine~eggplant=${aubergineEggplant.toStringAsFixed(3)} '
      'aubergine~rice=${aubergineRice.toStringAsFixed(3)}',
    );

    expect(chickenGrilled, greaterThan(chickenRice),
        reason: 'a variant of a food beats an unrelated food');
    expect(aubergineEggplant, greaterThan(aubergineRice),
        reason: 'synonym retrieval: aubergine ranks eggplant above rice');
    // Note: bare-word synonyms sit well below kDirectHitCosine (0.82), so they
    // ground an estimate rather than direct-hit — the relative ordering above is
    // what the FTS-prefilter + re-rank relies on.
  }, timeout: const Timeout(Duration(minutes: 6)));
}
