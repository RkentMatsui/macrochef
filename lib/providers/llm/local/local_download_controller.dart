import 'package:flutter/foundation.dart';

import 'local_models.dart';
import 'local_model_manager.dart';

/// Snapshot of an on-device model's download / presence state.
class LocalDownloadState {
  final LocalModelState status;

  /// 0..1 while a download is in flight, null when idle.
  final double? progress;

  /// Last download error, if any.
  final String? error;

  const LocalDownloadState({
    this.status = LocalModelState.notDownloaded,
    this.progress,
    this.error,
  });

  bool get downloading => progress != null;
}

/// App-lifetime singleton that owns model downloads. Because it lives outside the
/// widget tree, a download keeps running — and its progress stays observable via
/// [state] — even when the Settings sheet that started it is dismissed or the
/// Settings tab is rebuilt. (Survives everything except a full app kill.)
///
/// The UI observes [state] with a `ValueListenableBuilder` so progress updates
/// don't depend on any widget's `setState`.
class LocalDownloadController {
  LocalDownloadController._();
  static final LocalDownloadController instance = LocalDownloadController._();

  final ValueNotifier<LocalDownloadState> state =
      ValueNotifier<LocalDownloadState>(const LocalDownloadState());

  final LocalModelManager _mgr = LocalModelManager();

  /// Id of the model currently downloading, so late progress callbacks from a
  /// superseded download don't clobber newer state.
  String? _activeId;

  /// Refresh presence state from disk. No-ops while a download is in flight so a
  /// stale disk check can't overwrite live progress.
  Future<void> refresh(LocalModel model) async {
    if (state.value.downloading) return;
    final s = await _mgr.stateOf(model);
    state.value = LocalDownloadState(status: s);
  }

  /// Download [model]. Single-flight: ignored if a download is already running.
  Future<void> download(LocalModel model) async {
    if (state.value.downloading) return;
    _activeId = model.id;
    state.value = const LocalDownloadState(progress: 0);
    try {
      await downloadLocalModel(model, onProgress: (p) {
        if (_activeId == model.id) {
          state.value = LocalDownloadState(progress: p);
        }
      });
      final s = await _mgr.stateOf(model);
      state.value = LocalDownloadState(status: s);
    } catch (e) {
      final s = await _mgr.stateOf(model);
      state.value = LocalDownloadState(status: s, error: '$e');
    } finally {
      if (_activeId == model.id) _activeId = null;
    }
  }

  /// Delete [model] from disk and refresh state.
  Future<void> delete(LocalModel model) async {
    await deleteLocalModel(model);
    await refresh(model);
  }
}
