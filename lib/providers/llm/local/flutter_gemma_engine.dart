import 'package:flutter_gemma/flutter_gemma.dart';
import 'local_engine.dart';
import 'local_models.dart';

/// Real Android/iOS engine backed by flutter_gemma (MediaPipe LLM Inference).
class FlutterGemmaEngine implements LocalEngine {
  /// Model family, used to pick the right MediaPipe [ModelType] so a non-Gemma
  /// model (e.g. Qwen) gets its own chat template / stop tokens.
  final LocalArch arch;

  /// Max sequence length the loaded model supports (its `ekv####` capacity).
  final int maxTokens;

  FlutterGemmaEngine({this.arch = LocalArch.gemma, this.maxTokens = 1024});

  InferenceModel? _model;

  ModelType get _modelType => switch (arch) {
        LocalArch.gemma => ModelType.gemmaIt,
        LocalArch.qwen => ModelType.qwen,
        LocalArch.general => ModelType.general,
      };

  @override
  Future<void> load(String modelPath, {LocalBackend backend = LocalBackend.cpu}) async {
    // Modern (non-deprecated) install flow. initialize() is idempotent, so it's
    // safe to call on every load; the single-flight guard in LocalLlmProvider
    // already ensures load() runs once per provider anyway.
    await FlutterGemma.initialize();
    // Register the already-downloaded file as the active inference model. With a
    // FileSource this references the file in place (no copy) and carries the
    // model family so the right MediaPipe chat template / stop tokens are used.
    await FlutterGemma.installModel(
      modelType: _modelType,
      fileType: ModelFileType.task,
    ).fromFile(modelPath).install();
    // maxTokens comes from the model's ekv capacity (4096 for Qwen, 1280 for
    // SmolLM) so long recipe + JSON-schema prompts don't hit "reached max
    // sequence length" and abort decoding mid-JSON.
    _model = await FlutterGemma.getActiveModel(
      maxTokens: maxTokens,
      preferredBackend: backend == LocalBackend.gpu
          ? PreferredBackend.gpu
          : PreferredBackend.cpu,
    );
  }

  @override
  Future<String> generate(String prompt, {LocalGenOpts opts = const LocalGenOpts()}) async {
    final model = _model;
    if (model == null) {
      throw StateError('FlutterGemmaEngine.generate called before load()');
    }
    final session = await model.createSession(temperature: opts.temperature);
    try {
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      return await session.getResponse();
    } finally {
      await session.close();
    }
  }

  @override
  Future<void> dispose() async {
    await _model?.close();
    _model = null;
  }
}
