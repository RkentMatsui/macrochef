import 'package:flutter_test/flutter_test.dart';
import 'package:macrochef/services/nutrition/onnx_minilm_embedder.dart';

void main() {
  test('is fixed to the all-MiniLM-L6-v2 output dimension', () {
    final embedder = OnnxMiniLmEmbedder(
      modelPath: 'unused',
      vocabPath: 'unused',
    );

    expect(embedder.dim, 384);
    expect(embedder.id, 'minilm-l6-v2-384');
  });

  test(
    'embed after dispose fails clearly without initializing native state',
    () {
      final embedder = OnnxMiniLmEmbedder(
        modelPath: 'unused',
        vocabPath: 'unused',
      );
      embedder.dispose();

      expect(
        embedder.embed('food'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'OnnxMiniLmEmbedder has been disposed',
          ),
        ),
      );
    },
  );
}
