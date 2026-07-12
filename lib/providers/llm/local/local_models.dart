enum LocalModelState { notDownloaded, partial, downloaded }

/// Model family, so the native engine can pick the right MediaPipe chat template
/// / stop tokens. Kept flutter_gemma-agnostic here (mapped to `ModelType` inside
/// `flutter_gemma_engine.dart`) so this registry stays pure and unit-testable.
enum LocalArch { gemma, qwen, general }

/// A curated on-device model the user can download and run.
class LocalModel {
  final String id;
  final String displayName;
  final String fileName;
  final String url;
  final int sizeBytes;
  final LocalArch arch;

  /// Max sequence length (input + output tokens) the model is built for — the
  /// `ekv####` in the file name. Passed to the engine at load so long prompts
  /// (recipe instruction + JSON schema + the generated recipe) don't hit
  /// "reached max sequence length" and abort decoding mid-JSON.
  final int maxTokens;

  const LocalModel({
    required this.id,
    required this.displayName,
    required this.fileName,
    required this.url,
    required this.sizeBytes,
    required this.arch,
    required this.maxTokens,
  });
}

const String kDefaultLocalModelId = 'qwen2.5-1.5b';

/// Curated starter list — all publicly downloadable (no HuggingFace token) in the
/// MediaPipe `.task` format flutter_gemma 0.12.6 loads on Android. `sizeBytes` is
/// the exact LFS byte count so [resolveState] can tell a complete file from a
/// partial one. The `_multi-prefill-seq` / `ekv*` variants allow prompts longer
/// than 128 tokens (the recipe + JSON-schema prompts need this).
const List<LocalModel> localModels = [
  LocalModel(
    id: kDefaultLocalModelId,
    displayName: 'Qwen2.5 1.5B (Instruct, q8)',
    fileName: 'qwen2.5-1.5b-it-q8-ekv4096.task',
    url: 'https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct/resolve/main/Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.task',
    sizeBytes: 1598556720,
    arch: LocalArch.qwen,
    // Kept BELOW the model's ekv4096 KV-cache size on purpose: requesting the
    // full 4096 crashes MediaPipe in the decode rollback path
    // (llm_litert_executor.cc "Check failed: rolled_back_token_id.has_value()").
    // 2048 leaves rollback headroom while still fitting the recipe prompt
    // (~450 tokens) plus a full recipe JSON with room to spare.
    maxTokens: 2048,
  ),
  // NOTE: SmolLM-135M was dropped — at 135M params it can't produce valid,
  // complete recipe JSON (it rambles past its context instead of emitting clean
  // JSON and stopping), which fails the structured() cook flow. If a lighter
  // option is wanted later, add a capable small model (e.g. Qwen3 0.6B) rather
  // than a sub-0.5B one.
];

LocalModel? localModelById(String id) {
  for (final m in localModels) {
    if (m.id == id) return m;
  }
  return null;
}

/// Pure state resolution — filesystem facts are injected so this is unit-testable.
LocalModelState resolveState(
  LocalModel model, {
  required bool exists,
  required int sizeOnDisk,
}) {
  if (!exists) return LocalModelState.notDownloaded;
  if (sizeOnDisk >= model.sizeBytes) return LocalModelState.downloaded;
  return LocalModelState.partial;
}
