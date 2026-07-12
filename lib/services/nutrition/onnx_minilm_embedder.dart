import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:onnxruntime/onnxruntime.dart';

import 'embedder.dart';
import 'minilm_text_processing.dart';

/// all-MiniLM-L6-v2 sentence embeddings executed by ONNX Runtime.
///
/// The native session is initialized lazily. Call [dispose] when the owning
/// service is torn down; calls after disposal fail clearly rather than using a
/// released native handle.
class OnnxMiniLmEmbedder implements Embedder {
  static const _supportedInputNames = {
    'input_ids',
    'attention_mask',
    'token_type_ids',
  };

  final String modelPath;
  final String vocabPath;
  final int maxLength;

  @override
  int get dim => 384;

  OrtSession? _session;
  MiniLmTokenizer? _tokenizer;
  Future<void>? _initializing;
  bool _disposed = false;

  OnnxMiniLmEmbedder({
    required this.modelPath,
    required this.vocabPath,
    this.maxLength = 128,
  }) {
    if (maxLength < 2) {
      throw ArgumentError.value(maxLength, 'maxLength', 'must be at least 2');
    }
  }

  @override
  String get id => 'minilm-l6-v2-$dim';

  Future<void> _ensureInitialized() {
    if (_disposed) {
      return Future.error(StateError('OnnxMiniLmEmbedder has been disposed'));
    }
    if (_session != null && _tokenizer != null) return Future.value();
    return _initializing ??= _initialize().whenComplete(() {
      _initializing = null;
    });
  }

  Future<void> _initialize() async {
    final modelFile = File(modelPath);
    final vocabFile = File(vocabPath);
    if (!await modelFile.exists()) {
      throw StateError('MiniLM ONNX model does not exist: $modelPath');
    }
    if (!await vocabFile.exists()) {
      throw StateError('MiniLM vocabulary does not exist: $vocabPath');
    }

    final vocab = await vocabFile.readAsLines();
    final tokenizer = MiniLmTokenizer.fromVocab(vocab, maxLength: maxLength);

    OrtEnv.instance.init();
    final options = OrtSessionOptions();
    OrtSession? session;
    try {
      options.setSessionGraphOptimizationLevel(
        GraphOptimizationLevel.ortEnableAll,
      );
      // Load from bytes, not fromFile: the onnxruntime plugin mis-marshals the
      // model path to the native API on Windows desktop (UTF-16 byte order),
      // failing to open the file. fromBuffer copies the bytes and is
      // behaviour-identical on all platforms (same model → same vectors).
      session = OrtSession.fromBuffer(modelFile.readAsBytesSync(), options);
      _validateModelInputs(session.inputNames);
      if (session.outputNames.isEmpty) {
        throw StateError('MiniLM model declares no outputs');
      }
      if (_disposed) {
        throw StateError(
          'OnnxMiniLmEmbedder was disposed during initialization',
        );
      }
      _tokenizer = tokenizer;
      _session = session;
      session = null;
    } finally {
      session?.release();
      options.release();
    }
  }

  static void _validateModelInputs(List<String> inputNames) {
    final missing = const {
      'input_ids',
      'attention_mask',
    }.difference(inputNames.toSet());
    if (missing.isNotEmpty) {
      throw StateError(
        'MiniLM model is missing required inputs: ${missing.join(', ')}',
      );
    }
    final unsupported = inputNames.toSet().difference(_supportedInputNames);
    if (unsupported.isNotEmpty) {
      throw StateError(
        'MiniLM model has unsupported inputs: ${unsupported.join(', ')}',
      );
    }
  }

  @override
  Future<Float32List> embed(String text) async {
    await _ensureInitialized();
    if (_disposed) {
      throw StateError('OnnxMiniLmEmbedder has been disposed');
    }
    final session = _session!;
    final encoded = _tokenizer!.encode(text);
    OrtValueTensor? inputIds;
    OrtValueTensor? attentionMask;
    OrtValueTensor? tokenTypeIds;
    OrtRunOptions? runOptions;
    List<OrtValue?>? outputs;
    try {
      inputIds = OrtValueTensor.createTensorWithDataList(encoded.inputIds, [
        1,
        maxLength,
      ]);
      attentionMask = OrtValueTensor.createTensorWithDataList(
        encoded.attentionMask,
        [1, maxLength],
      );
      final inputs = <String, OrtValue>{
        'input_ids': inputIds,
        'attention_mask': attentionMask,
      };
      if (session.inputNames.contains('token_type_ids')) {
        tokenTypeIds = OrtValueTensor.createTensorWithDataList(
          Int64List(maxLength),
          [1, maxLength],
        );
        inputs['token_type_ids'] = tokenTypeIds;
      }

      runOptions = OrtRunOptions();
      final outputName = session.outputNames.contains('last_hidden_state')
          ? 'last_hidden_state'
          : session.outputNames.first;
      outputs = session.run(runOptions, inputs, [outputName]);
      if (outputs.isEmpty || outputs.first is! OrtValueTensor) {
        throw StateError('MiniLM output $outputName is not a tensor');
      }
      final tokenEmbeddings = _readLastHiddenState(
        (outputs.first! as OrtValueTensor).value,
      );
      return maskedMeanPoolAndNormalize(
        tokenEmbeddings,
        encoded.attentionMask,
        expectedDimension: dim,
      );
    } finally {
      for (final output in outputs ?? const <OrtValue?>[]) {
        output?.release();
      }
      runOptions?.release();
      tokenTypeIds?.release();
      attentionMask?.release();
      inputIds?.release();
    }
  }

  List<List<num>> _readLastHiddenState(Object? value) {
    if (value is! List || value.length != 1 || value.first is! List) {
      throw FormatException(
        'MiniLM output must have shape [1, sequence, $dim]',
      );
    }
    final batch = value.first as List;
    if (batch.length != maxLength) {
      throw FormatException(
        'MiniLM output sequence length ${batch.length} does not match '
        'input length $maxLength',
      );
    }
    final result = <List<num>>[];
    for (var token = 0; token < batch.length; token++) {
      final row = batch[token];
      if (row is! List ||
          row.length != dim ||
          row.any((item) => item is! num)) {
        throw FormatException(
          'MiniLM output token $token must contain exactly $dim numbers',
        );
      }
      result.add(row.cast<num>());
    }
    return result;
  }

  /// Releases the native session. The process-wide [OrtEnv] is intentionally
  /// retained because other app services may also own ONNX Runtime sessions.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _session?.release();
    _session = null;
    _tokenizer = null;
  }
}
