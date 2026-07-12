import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../models/daily.dart';
import '../../models/macros.dart';
import '../../providers/speech/speech_provider.dart';
import '../../services/cooking_session.dart';
import '../../services/food_lookup.dart';
import '../../services/intent_parser.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import 'macro_ribbon.dart';
import 'mic_orb.dart';

// ---------------------------------------------------------------------------
// CaptioningSpeechProvider — thin decorator that exposes the last spoken text.
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// CookingScreen
// ---------------------------------------------------------------------------

class CookingScreen extends ConsumerStatefulWidget {
  final List<String>? steps;
  final String? recipeTitle;

  /// Recipe context for hands-free ingredient adjustment ("I used 1325g of
  /// chicken"). When null, that utterance falls back to logging a food.
  final int? recipeId;
  final List<String> ingredientNames;

  /// Whether this tab is currently visible. On inactive→active the macro
  /// ribbon re-queries so totals logged elsewhere (e.g. Today) stay in sync.
  final bool isActive;

  /// True when shown as a bottom-nav tab (inside RootShell, whose floating nav
  /// overlays the body via extendBody). Adds clearance under the macro ribbon
  /// so it isn't hidden behind the nav. False for the pushed full-screen route.
  final bool tabbed;

  const CookingScreen({
    super.key,
    this.steps,
    this.recipeTitle,
    this.recipeId,
    this.ingredientNames = const [],
    this.isActive = true,
    this.tabbed = false,
  });

  @override
  ConsumerState<CookingScreen> createState() => _CookingScreenState();
}

class _CookingScreenState extends ConsumerState<CookingScreen> {
  // Session
  CookingSession? _session;
  _CaptioningSpeechProvider? _captioningSpeech;

  // Loading / error
  bool _loading = true;
  bool _llmFailed = false;
  bool _voiceFailed = false; // sherpa init failed/timed out (retryable)
  String? _voiceError; // underlying reason (shown on the error screen)

  // Loop control
  bool _loopActive = false;

  // Macro totals
  MacroValues _consumed = MacroValues.zero;
  DailyTarget? _target;

  // Captions
  String _heardCaption = '';

  // Manual command input
  final TextEditingController _cmdCtrl = TextEditingController();
  final FocusNode _cmdFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  @override
  void didUpdateWidget(CookingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Became the active tab → refresh the macro ribbon totals.
    if (widget.isActive && !oldWidget.isActive && !_loading) {
      _refreshTotals();
    }
  }

  @override
  void dispose() {
    _cmdCtrl.dispose();
    _cmdFocus.dispose();
    _stopLoop();
    _captioningSpeech?.lastSpoken.dispose();
    super.dispose();
  }

  // ---- session initialisation ----

  Future<void> _initSession() async {
    // Providers build even with empty API keys; the LLM calls just fail at
    // runtime and fall back to rule-based parsing. We track if the async
    // resolution itself fails so we can show a banner.
    bool llmFailed = false;
    IntentParser? parser;
    FoodLookup? lookup;

    try {
      parser = await ref.read(intentParserProvider.future);
    } catch (_) {
      llmFailed = true;
    }

    try {
      lookup = await ref.read(foodLookupProvider.future);
    } catch (_) {
      llmFailed = true;
    }

    // If either async provider failed we cannot build a full session.
    // Surface the error and bail; the screen stays in loading with a message.
    if (parser == null || lookup == null) {
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
    } catch (e) {
      // Voice engine failed or timed out loading its models (or the pack is
      // missing). Surface a retryable error instead of an endless spinner.
      if (mounted) {
        setState(() {
          _loading = false;
          _voiceFailed = true;
          _voiceError = e.toString();
        });
      }
      return;
    }
    final captioning = _CaptioningSpeechProvider(rawSpeech);

    final logService = ref.read(dailyLogServiceProvider);
    final date = todayDate();

    final recipeId = widget.recipeId;
    final session = CookingSession(
      steps: widget.steps ?? const [],
      speech: captioning,
      parser: parser,
      lookup: lookup,
      log: logService,
      date: date,
      llm: parser.llm, // enables conversational answers for non-command speech
      recipeId: recipeId,
      ingredientNames: widget.ingredientNames,
      onAdjustIngredient: recipeId == null
          ? null
          : (food, grams) => ref
              .read(recipeRepositoryProvider)
              .setIngredientQuantityByName(recipeId, food, grams, 'g'),
      onRecipeNutritionChanged: recipeId == null
          ? null
          : () async {
              final svc =
                  await ref.read(recipeNutritionServiceProvider.future);
              svc.invalidate(recipeId);
            },
    );

    final totals = await logService.totals(date);

    if (mounted) {
      setState(() {
        _captioningSpeech = captioning;
        _session = session;
        _consumed = totals.consumed;
        _target = totals.target;
        _loading = false;
        _llmFailed = llmFailed;
      });
    }
  }

  // ---- macro refresh ----

  Future<void> _refreshTotals() async {
    final logService = ref.read(dailyLogServiceProvider);
    final totals = await logService.totals(todayDate());
    if (mounted) {
      setState(() {
        _consumed = totals.consumed;
        _target = totals.target;
      });
    }
  }

  // ---- voice loop ----

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
          await _refreshTotals();
          if (!session.exited && _loopActive && mounted) {
            await listenOnce();
          } else {
            _stopLoop();
          }
        },
        // Phrase ended; Whisper is transcribing → show the processing animation.
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

  // ---- manual command ----

  Future<void> _sendManual() async {
    final session = _session;
    final text = _cmdCtrl.text.trim();
    if (session == null || text.isEmpty) return;

    _cmdCtrl.clear();
    _cmdFocus.unfocus();
    setState(() => _heardCaption = text);

    await session.handleUtterance(text);
    await _refreshTotals();

    if (session.exited && _loopActive) {
      _stopLoop();
    }

    if (mounted) setState(() {});
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final title = widget.recipeTitle ?? 'Cooking';
    final isFreeMode = (widget.steps == null || widget.steps!.isEmpty);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          title,
          style: tt.titleMedium?.copyWith(color: AppColors.textHi),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.ember),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.line),
        ),
      ),
      body: _loading
          ? _buildLoading()
          : _voiceFailed && _session == null
              ? _buildVoiceError(tt)
              : _llmFailed && _session == null
              ? _buildLlmError(tt)
              : Column(
                  children: [
                    Expanded(child: _buildBody(tt, isFreeMode)),
                    MacroRibbon(
                      consumed: _consumed,
                      target: _target,
                      // Clear the floating nav (height + margin + safe area)
                      // only when this is the bottom-nav tab.
                      bottomInset: widget.tabbed
                          ? MediaQuery.of(context).padding.bottom + 92
                          : 0,
                    ),
                  ],
                ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.ember),
          SizedBox(height: 16),
          Text(
            'Preparing cooking session…',
            style: TextStyle(color: AppColors.textMid),
          ),
        ],
      ),
    );
  }

  Widget _buildLlmError(TextTheme tt) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(PhosphorIconsRegular.prohibit, color: AppColors.carb, size: 48),
            const SizedBox(height: 16),
            Text(
              'AI features need an API key in Settings',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: AppColors.textMid),
            ),
          ],
        ),
      ),
    );
  }

  /// Voice engine failed/timed out loading its models — retryable (the load is
  /// bounded so this replaces the old endless "Preparing…" spinner).
  Widget _buildVoiceError(TextTheme tt) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(PhosphorIconsRegular.warningCircle,
                color: AppColors.carb, size: 48),
            const SizedBox(height: 16),
            Text(
              "The voice engine didn't finish loading. This can happen on the "
              'first launch or when the device is low on memory.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(color: AppColors.textMid),
            ),
            if (_voiceError != null) ...[
              const SizedBox(height: 10),
              Text(
                _voiceError!,
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: AppColors.textLow),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _voiceFailed = false;
                  _voiceError = null;
                  _loading = true;
                });
                _initSession();
              },
              icon: const Icon(PhosphorIconsRegular.arrowClockwise, size: 18),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(TextTheme tt, bool isFreeMode) {
    final session = _session!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LLM warning banner (session exists but LLM had issues)
          if (_llmFailed)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsRegular.info,
                      size: 16, color: AppColors.carb),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI features need an API key in Settings',
                      style: tt.bodySmall?.copyWith(color: AppColors.textMid),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

          // Step display
          ValueListenableBuilder<int>(
            valueListenable: session.currentStep,
            builder: (context, stepIndex, _) {
              return _buildStepArea(tt, isFreeMode, stepIndex);
            },
          ),

          const SizedBox(height: 24),

          // Mic orb centred — tap it to start/stop the hands-free loop.
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

          // Caption area
          _buildCaptions(tt),

          const SizedBox(height: 24),

          // Voice loop controls
          _buildVoiceControls(session),

          const SizedBox(height: 16),

          // Manual command input
          _buildManualInput(tt),

          const SizedBox(height: 8),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _buildStepArea(TextTheme tt, bool isFreeMode, int stepIndex) {
    if (isFreeMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voice logging',
            style: tt.bodySmall?.copyWith(color: AppColors.textLow),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell me what you ate',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              height: 1.15,
              color: AppColors.textHi,
            ),
          ),
        ],
      );
    }

    final steps = widget.steps!;
    final totalSteps = steps.length;
    final currentText =
        (stepIndex >= 0 && stepIndex < steps.length) ? steps[stepIndex] : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step ${stepIndex + 1} of $totalSteps',
          style: tt.bodySmall?.copyWith(color: AppColors.textLow),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position:
                  Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                      .animate(anim),
              child: child,
            ),
          ),
          child: Text(
            currentText,
            key: ValueKey(stepIndex),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              height: 1.15,
              color: AppColors.textHi,
            ),
          ),
        ),
      ],
    );
  }

  // A permanent empty notifier used when _captioningSpeech is not yet ready,
  // so _buildCaptions never allocates a throwaway ValueNotifier in build.
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
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Heard: ',
                        style:
                            tt.bodySmall?.copyWith(color: AppColors.textLow),
                      ),
                      TextSpan(
                        text: heard,
                        style:
                            tt.bodySmall?.copyWith(color: AppColors.textMid),
                      ),
                    ],
                  ),
                ),
              if (heard.isNotEmpty && lastSaid.isNotEmpty)
                const SizedBox(height: 4),
              if (lastSaid.isNotEmpty)
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Said: ',
                        style:
                            tt.bodySmall?.copyWith(color: AppColors.textLow),
                      ),
                      TextSpan(
                        text: lastSaid,
                        style: tt.bodySmall
                            ?.copyWith(color: AppColors.emberSoft),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVoiceControls(CookingSession session) {
    // The mic orb itself is the start/stop control now; this is just a hint.
    final String hint;
    if (session.exited) {
      hint = 'Session ended';
    } else if (!_loopActive) {
      hint = 'Tap the mic to start';
    } else {
      hint = 'Listening… tap the mic to stop';
    }
    return Center(
      child: Text(
        hint,
        style: const TextStyle(color: AppColors.textMid, fontSize: 13),
      ),
    );
  }

  Widget _buildManualInput(TextTheme tt) {
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
              hintText:
                  "Type a command (e.g. 'next', 'I used 200g of chicken')",
              hintStyle: TextStyle(
                color: AppColors.textLow,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.surfaceHigh,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(28)),
                borderSide: BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(28)),
                borderSide: BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(28)),
                borderSide: BorderSide(color: AppColors.ember),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _sendManual,
          icon: const Icon(PhosphorIconsBold.paperPlaneTilt),
          color: AppColors.ember,
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
