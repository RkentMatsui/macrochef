import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../providers/speech/speech_provider.dart';
import '../../services/cooking_session.dart' show SessionState;
import '../../services/training_service.dart'
    show kTrainingRestSecKey, kDefaultRestSec;
import '../../services/workout_intent_parser.dart';
import '../../services/workout_voice_session.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../cooking/mic_orb.dart';

/// Thin decorator exposing the last spoken text for captions.
class _CaptioningSpeechProvider implements SpeechProvider {
  final SpeechProvider _inner;
  final ValueNotifier<String> lastSpoken = ValueNotifier('');
  _CaptioningSpeechProvider(this._inner);
  @override
  Future<void> init() => _inner.init();
  @override
  Future<void> startListening(
    void Function(String partial) onPartial,
    void Function(String finalText) onFinal, {
    void Function()? onSpeechEnd,
  }) =>
      _inner.startListening(onPartial, onFinal, onSpeechEnd: onSpeechEnd);
  @override
  Future<void> stopListening() => _inner.stopListening();
  @override
  Future<void> speak(String text) {
    lastSpoken.value = text;
    return _inner.speak(text);
  }
  @override
  Future<void> stopSpeaking() => _inner.stopSpeaking();
  @override
  Future<void> dispose() => _inner.dispose();
}

class VoiceWorkoutScreen extends ConsumerStatefulWidget {
  final int sessionId;
  final int? dayId;
  const VoiceWorkoutScreen({super.key, required this.sessionId, this.dayId});

  @override
  ConsumerState<VoiceWorkoutScreen> createState() => _VoiceWorkoutScreenState();
}

class _VoiceWorkoutScreenState extends ConsumerState<VoiceWorkoutScreen>
    with WidgetsBindingObserver {
  WorkoutVoiceSession? _session;
  _CaptioningSpeechProvider? _captioningSpeech;
  bool _loading = true;
  bool _llmFailed = false;
  bool _loopActive = false;
  String _heardCaption = '';

  final TextEditingController _cmdCtrl = TextEditingController();
  final FocusNode _cmdFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cmdCtrl.dispose();
    _cmdFocus.dispose();
    _stopLoop();
    _captioningSpeech?.lastSpoken.dispose();
    _session?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _session?.setAppForeground(state == AppLifecycleState.resumed);
  }

  Future<void> _initSession() async {
    WorkoutIntentParser? parser;
    bool llmFailed = false;
    try {
      parser = await ref.read(workoutIntentParserProvider.future);
    } catch (_) {
      llmFailed = true;
    }
    // The LLM provider builds even with an empty API key, so the parser (and
    // its offline regex path) is normally available. Only a hard provider
    // error leaves it null — surface the banner in that case.
    if (parser == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _llmFailed = true;
        });
      }
      return;
    }

    final rawSpeech = ref.read(speechProvider);
    try {
      await rawSpeech.init();
    } catch (_) {
      // Voice pack missing/failed — surface the error banner instead of hanging
      // on the spinner (this screen has no cook-gate of its own).
      if (mounted) {
        setState(() {
          _loading = false;
          _llmFailed = true;
        });
      }
      return;
    }
    final captioning = _CaptioningSpeechProvider(rawSpeech);

    // Training defaults: weight unit (shared with the body-weight setting) and
    // the rest-timer length used when a "rest" command carries no number.
    final defaultUnit =
        (await ref.read(weightServiceProvider).isLbs) ? 'lb' : 'kg';
    final restRaw =
        await ref.read(settingsRepositoryProvider).get(kTrainingRestSecKey);
    final defaultRestSec = int.tryParse(restRaw ?? '') ?? kDefaultRestSec;

    // Mirror voice rests to a background notification (sound + vibration) so the
    // alert still fires if the app is backgrounded mid-rest.
    final alerts = ref.read(restAlertServiceProvider);
    unawaited(alerts.init());

    final session = WorkoutVoiceSession(
      sessionId: widget.sessionId,
      dayId: widget.dayId,
      training: ref.read(trainingServiceProvider),
      repo: ref.read(trainingRepositoryProvider),
      speech: captioning,
      parser: parser,
      llm: parser.llm,
      defaultUnit: defaultUnit,
      defaultRestSec: defaultRestSec,
      onRestScheduled: alerts.scheduleBackgroundAlert,
      onRestCancelled: alerts.cancelBackgroundAlert,
    );
    await session.init();

    if (mounted) {
      setState(() {
        _captioningSpeech = captioning;
        _session = session;
        _loading = false;
        _llmFailed = llmFailed;
      });
      await session.begin();
    }
  }

  Future<void> _startLoop() async {
    final session = _session;
    if (session == null || _loopActive) return;
    setState(() => _loopActive = true);
    final speech = _captioningSpeech!;

    Future<void> listenOnce() async {
      if (!_loopActive || session.exited || !mounted) return;
      session.state.value = SessionState.listening;
      await speech.startListening(
        (partial) {
          if (mounted) setState(() => _heardCaption = partial);
        },
        (finalText) async {
          if (!mounted) return;
          setState(() => _heardCaption = finalText);
          await session.handleUtterance(finalText);
          if (!session.exited && _loopActive && mounted) {
            await listenOnce();
          } else {
            _stopLoop();
          }
        },
        onSpeechEnd: () {
          if (mounted) session.state.value = SessionState.understanding;
        },
      );
    }

    await listenOnce();
  }

  void _stopLoop() {
    if (!_loopActive) return;
    setState(() => _loopActive = false);
    _captioningSpeech?.stopListening();
    _captioningSpeech?.stopSpeaking();
    _session?.state.value = SessionState.idle;
  }

  Future<void> _sendManual() async {
    final session = _session;
    final text = _cmdCtrl.text.trim();
    if (session == null || text.isEmpty) return;
    _cmdCtrl.clear();
    _cmdFocus.unfocus();
    setState(() => _heardCaption = text);
    await session.handleUtterance(text);
    if (session.exited && _loopActive) _stopLoop();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Voice workout',
            style: tt.titleMedium?.copyWith(color: AppColors.textHi)),
        iconTheme: const IconThemeData(color: AppColors.ember),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.line),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.ember))
          : _llmFailed && _session == null
              ? _buildError(tt)
              : _buildBody(tt),
    );
  }

  Widget _buildError(TextTheme tt) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('AI features need an API key in Settings',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: AppColors.textMid)),
        ),
      );

  Widget _buildBody(TextTheme tt) {
    final session = _session!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Current exercise + draft readout.
          ValueListenableBuilder<int>(
            valueListenable: session.exerciseIndex,
            builder: (context, _, __) {
              return ValueListenableBuilder<DraftSet>(
                valueListenable: session.draft,
                builder: (context, draft, ___) {
                  final name = session.currentExerciseName ?? 'No exercise';
                  final draftText = session.draftSummary;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current exercise',
                          style: tt.bodySmall
                              ?.copyWith(color: AppColors.textLow)),
                      const SizedBox(height: 8),
                      Text(name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                            color: AppColors.textHi,
                          )),
                      const SizedBox(height: 8),
                      Text(draftText,
                          style: tt.bodyMedium
                              ?.copyWith(color: AppColors.emberSoft)),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          ValueListenableBuilder<SessionState>(
            valueListenable: session.state,
            builder: (context, state, _) {
              return Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: session.exited
                      ? null
                      : (_loopActive ? _stopLoop : _startLoop),
                  child: MicOrb(state: state, size: 120),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildCaptions(tt),
          const SizedBox(height: 16),
          Center(
            child: Text(
              session.exited
                  ? 'Session ended'
                  : (_loopActive
                      ? 'Listening… tap the mic to stop'
                      : 'Tap the mic to start'),
              style: const TextStyle(color: AppColors.textMid, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          _buildManualInput(),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0);
  }

  static final _emptyCaption = ValueNotifier<String>('');

  Widget _buildCaptions(TextTheme tt) {
    final notifier = _captioningSpeech?.lastSpoken ?? _emptyCaption;
    return ValueListenableBuilder<String>(
      valueListenable: notifier,
      builder: (context, lastSaid, _) {
        final heard = _heardCaption;
        if (heard.isEmpty && lastSaid.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (heard.isNotEmpty)
                Text('Heard: $heard',
                    style: tt.bodySmall?.copyWith(color: AppColors.textMid)),
              if (heard.isNotEmpty && lastSaid.isNotEmpty)
                const SizedBox(height: 4),
              if (lastSaid.isNotEmpty)
                Text('Said: $lastSaid',
                    style:
                        tt.bodySmall?.copyWith(color: AppColors.emberSoft)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildManualInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _cmdCtrl,
            focusNode: _cmdFocus,
            style: const TextStyle(color: AppColors.textHi),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendManual(),
            decoration: const InputDecoration(
              hintText: "Type a command (e.g. '6 reps at 80 kg', 'next set')",
              hintStyle: TextStyle(color: AppColors.textLow, fontSize: 13),
              filled: true,
              fillColor: AppColors.surfaceHigh,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(28)),
                borderSide: BorderSide(color: AppColors.line),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _sendManual,
          icon: const Icon(PhosphorIconsBold.paperPlaneTilt),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.ember,
            foregroundColor: AppColors.canvas,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
          ),
          tooltip: 'Send command',
        ),
      ],
    );
  }
}
