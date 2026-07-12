import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Entry point for the speech recognition background isolate.
///
/// Message protocol (main → worker):
///   {'cmd':'init', 'enc':String, 'dec':String, 'tok':String, 'vad':String}
///     → constructs CircularBuffer + VAD + OfflineRecognizer; replies {'event':'ready'}
///   {'cmd':'audio', 'samples':Float32List}
///     → pushes to circular buffer, drains 512-sample VAD windows;
///       for each completed speech segment, replies {'event':'final','text':String}
///   {'cmd':'tts', 'text':String, 'reqId':int}
///     → synthesize speech to a WAV file; replies {'event':'tts','path':String,'reqId':int}
///   {'cmd':'reset'}
///     → vad.reset() + cb.reset() (start a new listening turn)
///   {'cmd':'dispose'}
///     → free all resources, then Isolate.exit()
///
/// Replies (worker → main):
///   {'event':'ready'}
///   {'event':'transcribing'}            — a phrase ended; decode is starting
///   {'event':'final', 'text': String}  — non-empty trimmed transcript
///   {'event':'error', 'message': String}
/// Whisper emits canned phrases when fed non-speech/noise ("Thank you.",
/// "you", "Thanks for watching", music notes, bracketed tags, etc.). Drop
/// those, plus results that are only punctuation or a single short token, so
/// static doesn't get acted on.
bool _isHallucination(String text) {
  var t = text.toLowerCase().trim();
  // Strip surrounding punctuation/symbols/whitespace.
  t = t.replaceAll(RegExp(r'''^[\s.,!?;:'"\-–—…♪♫\[\]()]+|[\s.,!?;:'"\-–—…♪♫\[\]()]+$'''), '');
  if (t.isEmpty) return true;
  if (t.length <= 1) return true; // single char like "." or "a"
  const blocked = {
    'you',
    'thank you',
    'thank you very much',
    'thanks',
    'thanks for watching',
    'thanks for watching!',
    'please subscribe',
    'subscribe',
    'bye',
    'bye bye',
    'okay',
    'ok',
    'hmm',
    'mm',
    'mhm',
    'uh',
    'um',
    'yeah',
    'blank_audio',
    'silence',
    'music',
    'music playing',
    'applause',
  };
  return blocked.contains(t);
}

void voiceWorkerMain(SendPort mainSendPort) {
  // MUST be the first line — FFI bindings are per-isolate.
  sherpa.initBindings();

  final workerPort = ReceivePort();
  // Send our SendPort back so the main isolate can reach us.
  mainSendPort.send(workerPort.sendPort);

  sherpa.CircularBuffer? cb;
  sherpa.VoiceActivityDetector? vad;
  sherpa.OfflineRecognizer? recognizer;
  sherpa.OfflineTts? tts;
  String outDir = '';

  const int vadWindowSize = 512;

  workerPort.listen((dynamic message) {
    try {
      final msg = message as Map<dynamic, dynamic>;
      final cmd = msg['cmd'] as String;

      switch (cmd) {
        case 'init':
          final enc = msg['enc'] as String;
          final dec = msg['dec'] as String;
          final tok = msg['tok'] as String;
          final vadPath = msg['vad'] as String;
          outDir = msg['out'] as String;

          cb = sherpa.CircularBuffer(capacity: 30 * 16000);

          // Emit which model is about to load. These native constructors are
          // synchronous FFI calls that can't report progress or even an error if
          // they stall — so the last stage seen before a timeout tells us which
          // model hung.
          mainSendPort.send({'event': 'progress', 'stage': 'vad'});
          vad = sherpa.VoiceActivityDetector(
            config: sherpa.VadModelConfig(
              sileroVad: sherpa.SileroVadModelConfig(
                model: vadPath,
                // Stricter than defaults so background static/noise doesn't
                // trip the detector: higher speech-probability threshold and a
                // longer minimum speech length to reject brief noise blips.
                threshold: 0.6,
                minSilenceDuration: 0.6,
                minSpeechDuration: 0.30,
                windowSize: vadWindowSize,
              ),
              sampleRate: 16000,
              numThreads: 1,
              provider: 'cpu',
              debug: false,
            ),
            bufferSizeInSeconds: 30,
          );

          mainSendPort.send({'event': 'progress', 'stage': 'asr'});
          recognizer = sherpa.OfflineRecognizer(
            sherpa.OfflineRecognizerConfig(
              feat: const sherpa.FeatureConfig(
                sampleRate: 16000,
                featureDim: 80,
              ),
              model: sherpa.OfflineModelConfig(
                whisper: sherpa.OfflineWhisperModelConfig(
                  encoder: enc,
                  decoder: dec,
                  language: 'en',
                  task: 'transcribe',
                ),
                tokens: tok,
                modelType: 'whisper',
                numThreads: 2,
                provider: 'cpu',
                debug: false,
              ),
            ),
          );

          mainSendPort.send({'event': 'progress', 'stage': 'tts'});
          tts = sherpa.OfflineTts(
            sherpa.OfflineTtsConfig(
              model: sherpa.OfflineTtsModelConfig(
                vits: sherpa.OfflineTtsVitsModelConfig(
                  model: msg['ttsModel'] as String,
                  lexicon: msg['ttsLexicon'] as String,
                  tokens: msg['ttsTokens'] as String,
                ),
                numThreads: 2,
                provider: 'cpu',
              ),
              // upstream typo: maxNumSenetences
              maxNumSenetences: 1,
            ),
          );

          mainSendPort.send({'event': 'ready'});

        case 'tts':
          final synth = tts;
          if (synth == null) return;
          final text = (msg['text'] as String).trim();
          final reqId = msg['reqId'];
          if (text.isEmpty) {
            mainSendPort.send({'event': 'tts', 'path': '', 'reqId': reqId});
            return;
          }
          final audio = synth.generate(text: text, sid: 0, speed: 1.0);
          final path = '$outDir/tts_$reqId.wav';
          sherpa.writeWave(
            filename: path,
            samples: audio.samples,
            sampleRate: audio.sampleRate,
          );
          mainSendPort.send({'event': 'tts', 'path': path, 'reqId': reqId});

        case 'audio':
          final buf = cb;
          final detector = vad;
          final asr = recognizer;
          if (buf == null || detector == null || asr == null) return;

          final samples = msg['samples'] as Float32List;
          buf.push(samples);

          while (buf.size >= vadWindowSize) {
            // get() uses named params: startIndex and n
            final window = buf.get(startIndex: buf.head, n: vadWindowSize);
            buf.pop(vadWindowSize);
            // acceptWaveform on VAD is positional
            detector.acceptWaveform(window);
            while (!detector.isEmpty()) {
              final seg = detector.front();
              detector.pop();
              // Speech ended — tell the UI we're transcribing (decode below
              // blocks this isolate for ~1-3s; the main thread shows a
              // "processing" animation meanwhile).
              mainSendPort.send({'event': 'transcribing'});
              final s = asr.createStream();
              // acceptWaveform on OfflineStream uses named params
              s.acceptWaveform(samples: seg.samples, sampleRate: 16000);
              asr.decode(s);
              final text = asr.getResult(s).text.trim();
              s.free();
              if (text.isNotEmpty && !_isHallucination(text)) {
                mainSendPort.send({'event': 'final', 'text': text});
              }
            }
          }

        case 'reset':
          vad?.reset();
          cb?.reset();

        case 'dispose':
          recognizer?.free();
          vad?.free();
          cb?.free();
          tts?.free();
          recognizer = null;
          vad = null;
          cb = null;
          tts = null;
          Isolate.exit();
      }
    } catch (e, st) {
      mainSendPort.send({'event': 'error', 'message': '$e\n$st'});
    }
  });
}
