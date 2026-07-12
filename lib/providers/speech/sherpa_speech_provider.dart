import 'dart:async';
import 'dart:isolate';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'speech_provider.dart';
import 'voice_assets.dart';
import 'voice_worker.dart';

/// On-device speech using sherpa-onnx, all heavy inference on a **background
/// isolate** (keeps the UI thread free):
/// - ASR: offline Whisper base.en + Silero VAD.
/// - TTS: offline vits-ljs (synthesized in the worker; the main isolate only
///   plays the resulting WAV via audioplayers).
class SherpaSpeechProvider implements SpeechProvider {
  SherpaSpeechProvider();

  // ── Playback (main isolate) ────────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();

  // ── Mic (main isolate) ────────────────────────────────────────────────────
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _micSub;
  bool _listening = false;

  // ── Worker isolate ────────────────────────────────────────────────────────
  Isolate? _isolate;
  SendPort? _toWorker;
  ReceivePort? _fromWorker;
  Completer<void> _ready = Completer<void>();

  // Callbacks stored for the active listening turn.
  void Function(String)? _onFinal;
  void Function()? _onSpeechEnd;

  // ── init ──────────────────────────────────────────────────────────────────

  // A single in-flight init future so concurrent callers share one load and we
  // never spawn a second worker.
  Future<void>? _initInFlight;

  @override
  Future<void> init() async {
    // Reuse a warm worker (models already loaded). Previously init() re-spawned
    // the isolate and reloaded ~234 MB of ONNX models on *every* cook session
    // (and leaked the old isolate) — this made each "Preparing cooking session"
    // pay the full load. Now the load happens once per app run.
    if (_toWorker != null && _ready.isCompleted) return;
    // Share one in-flight load across concurrent callers; clear on completion so
    // a failed load (e.g. pack not ready yet) can be retried.
    return _initInFlight ??=
        _doInit().whenComplete(() => _initInFlight = null);
  }

  Future<void> _doInit() async {
    final assets = await VoiceAssets.ensure();

    // Duck (not interrupt) other audio while the assistant speaks. Without an
    // explicit AudioContext the default focus request can cause our TTS WAV to
    // be dropped when music is already playing.
    await _player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.speech,
          usageType: AndroidUsageType.assistant,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          },
        ),
      ),
    );
    // Worker writes synthesized WAVs here; computed on main (path_provider does
    // not work inside a plain isolate) and passed to the worker.
    _pendingOut = (await getApplicationSupportDirectory()).path;

    // Store paths so _onWorkerMessage can send them when the SendPort arrives.
    _pendingEnc = assets.whisperEncoder;
    _pendingDec = assets.whisperDecoder;
    _pendingTok = assets.whisperTokens;
    _pendingVad = assets.vadModel;
    _pendingTtsModel = assets.ttsModel;
    _pendingTtsLexicon = assets.ttsLexicon;
    _pendingTtsTokens = assets.ttsTokens;

    // Spawn recognition + TTS worker.
    _ready = Completer<void>();
    final fromWorker = _fromWorker = ReceivePort();

    _isolate = await Isolate.spawn(voiceWorkerMain, fromWorker.sendPort);

    fromWorker.listen(_onWorkerMessage);

    // First message from worker is its SendPort.
    // (handled in _onWorkerMessage below — wait for ready)
    await _ready.future;
  }

  void _onWorkerMessage(dynamic message) {
    if (message is SendPort) {
      // First message: the worker's SendPort.
      _toWorker = message;
      // Send init command now that we have the worker's port.
      _toWorker!.send({
        'cmd': 'init',
        'enc': _pendingEnc,
        'dec': _pendingDec,
        'tok': _pendingTok,
        'vad': _pendingVad,
        'ttsModel': _pendingTtsModel,
        'ttsLexicon': _pendingTtsLexicon,
        'ttsTokens': _pendingTtsTokens,
        'out': _pendingOut,
      });
      return;
    }

    if (message is! Map) return;
    final event = message['event'] as String?;

    switch (event) {
      case 'ready':
        if (!_ready.isCompleted) _ready.complete();

      case 'transcribing':
        if (_listening) _onSpeechEnd?.call();

      case 'final':
        final text = (message['text'] as String? ?? '').trim();
        if (text.isEmpty) return;
        if (_listening && _onFinal != null) {
          // Stop mic first, then deliver — cooking loop re-arms via
          // startListening which sends 'reset' before restarting the mic.
          _stopMic().then((_) => _onFinal?.call(text));
        }

      case 'tts':
        final reqId = message['reqId'] as int;
        final path = (message['path'] as String?) ?? '';
        _ttsCompleters.remove(reqId)?.complete(path);

      case 'error':
        debugPrint('[STT] worker error: ${message['message']}');
    }
  }

  // Paths passed from init() to _onWorkerMessage (crosses the SendPort receive).
  String _pendingEnc = '';
  String _pendingDec = '';
  String _pendingTok = '';
  String _pendingVad = '';
  String _pendingTtsModel = '';
  String _pendingTtsLexicon = '';
  String _pendingTtsTokens = '';
  String _pendingOut = '';

  // TTS request tracking (worker synthesizes; completer fires on the WAV path).
  int _ttsReq = 0;
  final Map<int, Completer<String>> _ttsCompleters = {};

  // ── startListening ────────────────────────────────────────────────────────

  @override
  Future<void> startListening(
    void Function(String partial) onPartial,
    void Function(String finalText) onFinal, {
    void Function()? onSpeechEnd,
  }) async {
    if (_listening) return;
    if (!await _recorder.hasPermission()) return;

    _onFinal = onFinal;
    _onSpeechEnd = onSpeechEnd;
    _listening = true;

    // Signal the worker to clear state for a new utterance.
    _toWorker?.send({'cmd': 'reset'});

    final micStream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _micSub = micStream.listen(
      (Uint8List data) {
        if (!_listening) return;
        final samples = _pcm16ToFloat32(data);
        _toWorker?.send({'cmd': 'audio', 'samples': samples});
      },
      onError: (Object e) => debugPrint('[STT] mic stream error: $e'),
    );

    // Note: Whisper is offline / batch — no live partials. onPartial is never
    // called. This matches the contract (partials are optional).
  }

  // ── stopListening ─────────────────────────────────────────────────────────

  @override
  Future<void> stopListening() async {
    await _stopMic();
    _toWorker?.send({'cmd': 'reset'});
  }

  Future<void> _stopMic() async {
    _listening = false;
    await _micSub?.cancel();
    _micSub = null;
    if (await _recorder.isRecording()) {
      await _recorder.stop();
    }
  }

  // ── speak / stopSpeaking (TTS synthesized in the worker isolate) ──────────

  @override
  Future<void> speak(String text) async {
    final worker = _toWorker;
    if (worker == null || text.trim().isEmpty) return;
    final reqId = ++_ttsReq;
    final completer = Completer<String>();
    _ttsCompleters[reqId] = completer;
    worker.send({'cmd': 'tts', 'text': text, 'reqId': reqId});

    String path;
    try {
      path = await completer.future.timeout(const Duration(seconds: 20));
    } catch (e) {
      _ttsCompleters.remove(reqId);
      debugPrint('[TTS] synth failed/timeout: $e');
      return;
    }
    if (path.isEmpty) return;

    final done = _player.onPlayerComplete.first;
    await _player.play(DeviceFileSource(path));
    await done;
  }

  @override
  Future<void> stopSpeaking() async {
    await _player.stop();
  }

  // ── dispose ───────────────────────────────────────────────────────────────

  @override
  Future<void> dispose() async {
    await _stopMic();
    _toWorker?.send({'cmd': 'dispose'});
    _isolate?.kill(priority: Isolate.immediate);
    _fromWorker?.close();
    _isolate = null;
    _toWorker = null;
    _fromWorker = null;
    for (final c in _ttsCompleters.values) {
      if (!c.isCompleted) c.complete('');
    }
    _ttsCompleters.clear();
    await _player.dispose();
    await _recorder.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  /// Converts PCM-16 LE bytes to normalised float32 samples.
  ///
  /// Uses [ByteData.sublistView] (not [ByteData.view]) because the `record`
  /// package may deliver chunks as views into a larger buffer with a non-zero
  /// offsetInBytes — [ByteData.view] would read from the wrong offset.
  static Float32List _pcm16ToFloat32(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    final n = bytes.lengthInBytes ~/ 2;
    final out = Float32List(n);
    for (var i = 0; i < n; i++) {
      out[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }
}
