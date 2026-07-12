import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/database.dart';
import '../../services/rest_alert_service.dart';
import '../../services/training_service.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../widgets/glass_panel.dart';
import '../widgets/primary_button.dart';
import 'exercise_detail_screen.dart';
import 'exercise_picker_screen.dart';
import 'widgets/set_row.dart';

/// Live logger for one in-progress [WorkoutSession]. Exercises are grouped from
/// existing sets; each exercise shows a type-aware set grid. Sets are persisted
/// as they are added; "Finish" stamps the session complete and pops.
class SessionLoggerScreen extends ConsumerStatefulWidget {
  final int sessionId;
  const SessionLoggerScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionLoggerScreen> createState() =>
      _SessionLoggerScreenState();
}

class _LoggedSet {
  final int id;
  final SetRowData data;
  _LoggedSet(this.id, this.data);
}

class _ExerciseBlock {
  final Exercise exercise;
  final int position;
  final List<_LoggedSet> sets;

  /// Sets from the last time this exercise was trained, shown as a per-set
  /// "last time" reference. Indexed by set position (0-based).
  final List<SetEntry> previousSets;

  _ExerciseBlock(this.exercise, this.position, this.sets,
      {this.previousSets = const []});
}

class _SessionLoggerScreenState extends ConsumerState<SessionLoggerScreen>
    with WidgetsBindingObserver {
  final List<_ExerciseBlock> _blocks = [];
  bool _loading = true;
  bool _finishing = false;
  String _displayUnit = 'kg';

  // ---- rest timer ----
  Timer? _restTimer;
  int _restRemaining = 0; // seconds left in the current rest, 0 = inactive
  int _restTotal = 0; // the length the current rest started at
  int _defaultRestSec = kDefaultRestSec; // from Settings → Training
  // Absolute moment the current rest ends. The ticker recomputes remaining from
  // this each second so the countdown self-corrects after the app is throttled
  // in the background; null = no rest running.
  DateTime? _restEndsAt;
  // Guards against double-firing: once the alert (in-app tone or the background
  // notification) has handled this rest, we don't fire again.
  bool _restAlerted = false;
  // Latest app lifecycle state. The in-app tone (audioplayers) is inaudible
  // while backgrounded, so we only take that path when actually resumed and
  // otherwise let the scheduled notification's sound fire.
  AppLifecycleState _appState = AppLifecycleState.resumed;

  RestAlertService get _alerts => ref.read(restAlertServiceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _restTimer?.cancel();
    // Leaving the logger: drop any pending background rest alert so it can't
    // surprise the user after they've moved on.
    _alerts.cancelBackgroundAlert();
    super.dispose();
  }

  /// Reconcile the countdown when the app returns to the foreground: the ticker
  /// is throttled/paused while backgrounded, so recompute from the wall clock.
  /// If the rest already finished while away, the scheduled notification has
  /// already alerted — clear silently rather than double-beeping.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appState = state;
    if (state != AppLifecycleState.resumed) return;
    final ends = _restEndsAt;
    if (ends == null || _restAlerted) return;
    final remaining = ends.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _finishRest(playTone: false); // notification already fired in background
    } else {
      setState(() => _restRemaining = remaining);
    }
  }

  Future<void> _load() async {
    // Prime the alert pipeline (permissions + channel) so the first rest can
    // fire its background notification without a cold-start delay.
    _alerts.init();
    final repo = ref.read(trainingRepositoryProvider);
    final svc = ref.read(weightServiceProvider);
    final isLb = await svc.isLbs;
    final restRaw =
        await ref.read(settingsRepositoryProvider).get(kTrainingRestSecKey);
    final defaultRest = int.tryParse(restRaw ?? '') ?? kDefaultRestSec;
    final sets = await repo.setsForSession(widget.sessionId);

    // Group sets by exercise position; resolve each exercise once.
    final byPosition = <int, List<SetEntry>>{};
    for (final s in sets) {
      byPosition.putIfAbsent(s.position, () => []).add(s);
    }
    final blocks = <_ExerciseBlock>[];
    for (final entry in byPosition.entries) {
      final exercise = await repo.exerciseById(entry.value.first.exerciseId);
      if (exercise == null) continue;
      final rows = entry.value
          .map((s) => _LoggedSet(s.id, _toRowData(s)))
          .toList();
      final previous = await repo.previousSessionSetsFor(exercise.id);
      blocks.add(_ExerciseBlock(exercise, entry.key, rows,
          previousSets: previous));
    }
    blocks.sort((a, b) => a.position.compareTo(b.position));

    if (!mounted) return;
    setState(() {
      _displayUnit = isLb ? 'lb' : 'kg';
      _defaultRestSec = defaultRest;
      _blocks
        ..clear()
        ..addAll(blocks);
      _loading = false;
    });
  }

  // ---- rest timer ----------------------------------------------------------

  /// Start (or restart) a rest countdown for [secs] (defaults to the user's
  /// Training default). Anchored to a wall-clock end time so it survives the
  /// app being backgrounded; a background notification (sound + vibration) is
  /// scheduled in parallel so the alert fires even if the app is suspended.
  void _startRest([int? secs]) {
    final total = secs ?? _defaultRestSec;
    _restTimer?.cancel();
    _restAlerted = false;
    _restEndsAt = DateTime.now().add(Duration(seconds: total));
    setState(() {
      _restTotal = total;
      _restRemaining = total;
    });
    _alerts.scheduleBackgroundAlert(Duration(seconds: total));
    _restTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _tickRest());
  }

  void _tickRest() {
    final ends = _restEndsAt;
    if (!mounted || ends == null) {
      _restTimer?.cancel();
      return;
    }
    final remaining = ends.difference(DateTime.now()).inSeconds;
    setState(() => _restRemaining = remaining > 0 ? remaining : 0);
    // Only beep in-app when actually foreground; if the ticker reaches zero
    // while backgrounded, leave the scheduled notification to sound instead of
    // playing a muted tone and cancelling that notification.
    if (remaining <= 0) {
      _finishRest(playTone: _appState == AppLifecycleState.resumed);
    }
  }

  /// End the current rest. [playTone] fires the in-app tone + haptic and cancels
  /// the (now redundant) background notification — used when the rest completes
  /// while the app is in the foreground. When the rest finished in the
  /// background the notification already alerted, so we clear silently.
  void _finishRest({required bool playTone}) {
    if (_restAlerted) return;
    _restAlerted = true;
    _restTimer?.cancel();
    _restEndsAt = null;
    if (playTone) {
      HapticFeedback.heavyImpact();
      _alerts.playForegroundTone();
      _alerts.cancelBackgroundAlert();
    }
    if (mounted) setState(() => _restRemaining = 0);
  }

  void _stopRest() {
    _restTimer?.cancel();
    _restAlerted = true; // suppress any late fire
    _restEndsAt = null;
    _alerts.cancelBackgroundAlert();
    setState(() {
      _restRemaining = 0;
      _restTotal = 0;
    });
  }

  /// Add/subtract time on the fly; never drops below 5s while running. Moves the
  /// wall-clock end and reschedules the background notification to match.
  void _bumpRest(int delta) {
    if (_restRemaining <= 0 || _restEndsAt == null) return;
    final newRemaining = (_restRemaining + delta).clamp(5, 3600);
    _restEndsAt = DateTime.now().add(Duration(seconds: newRemaining));
    _alerts.scheduleBackgroundAlert(Duration(seconds: newRemaining));
    setState(() {
      _restRemaining = newRemaining;
      if (_restRemaining > _restTotal) _restTotal = _restRemaining;
    });
  }

  static String _fmtRest(int s) {
    final m = s ~/ 60;
    final sec = (s % 60).toString().padLeft(2, '0');
    return '$m:$sec';
  }

  SetRowData _toRowData(SetEntry s) {
    final unit = s.enteredUnit ?? 'kg';
    double? weight = s.weightKg;
    if (weight != null && unit == 'lb') {
      weight = WeightToDisplay.lb(weight);
    }
    return SetRowData(
      reps: s.reps,
      weight: weight,
      unit: unit,
      durationSec: s.durationSec,
      distanceM: s.distanceM,
      rpe: s.rpe,
      isWarmup: s.isWarmup,
      completed: s.completed,
    );
  }

  int get _nextPosition =>
      _blocks.isEmpty ? 0 : _blocks.map((b) => b.position).reduce((a, b) => a > b ? a : b) + 1;

  Future<void> _addExercise() async {
    final picked = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (picked == null) return;
    final previous = await ref
        .read(trainingRepositoryProvider)
        .previousSessionSetsFor(picked.id);
    if (!mounted) return;
    setState(() {
      _blocks.add(_ExerciseBlock(picked, _nextPosition, [],
          previousSets: previous));
    });
  }

  Future<void> _addSet(_ExerciseBlock block, {SetRowData? template}) async {
    final svc = ref.read(trainingServiceProvider);
    // First set for this exercise (and no explicit "repeat" template)? Pre-fill
    // weight/reps from the last time it was performed so re-doing an exercise
    // auto-populates rather than starting blank.
    SetRowData? prefill;
    if (template == null && block.sets.isEmpty) {
      final last = await ref
          .read(trainingRepositoryProvider)
          .lastSetFor(block.exercise.id);
      if (last != null) {
        prefill = _toRowData(last)
          ..isWarmup = false
          ..rpe = null;
      }
    }
    final data = template?.copy() ??
        prefill ??
        SetRowData(unit: _displayUnit, isWarmup: false);
    // A freshly added set is always pending until the user checks it off — the
    // rest timer + next-set auto-fill fire on completion, not on add.
    data.completed = false;
    final setIndex = block.sets.length;
    final id = await svc.logSet(
      sessionId: widget.sessionId,
      exerciseId: block.exercise.id,
      position: block.position,
      setIndex: setIndex,
      reps: data.reps,
      weightKg: data.weight,
      durationSec: data.durationSec,
      distanceM: data.distanceM,
      rpe: data.rpe,
      enteredUnit: block.exercise.tracksWeight ? data.unit : null,
      isWarmup: data.isWarmup,
      completed: false,
    );
    setState(() => block.sets.add(_LoggedSet(id, data)));
  }

  /// User ticked/unticked a set's done check. On completion: persist it, start
  /// the rest countdown, and — if it was the last set — auto-add the next set
  /// pre-filled with the same weight/reps so they don't re-enter it.
  Future<void> _onSetCompleted(_ExerciseBlock block, _LoggedSet logged) async {
    await _persistSet(block, logged);
    if (!logged.data.completed) return; // un-ticked → nothing else to do
    if (block.exercise.tracksReps || block.exercise.tracksWeight) {
      _startRest();
    }
    if (identical(block.sets.last, logged)) {
      await _addSet(block, template: logged.data);
    }
  }

  Future<void> _persistSet(_ExerciseBlock block, _LoggedSet logged) async {
    final data = logged.data;
    double? weightKg = data.weight;
    if (weightKg != null && block.exercise.tracksWeight) {
      weightKg = TrainingService.toKg(weightKg, data.unit);
    }
    await ref.read(trainingRepositoryProvider).updateSet(
          logged.id,
          SetEntriesUpdate.build(
            reps: data.reps,
            weightKg: weightKg,
            durationSec: data.durationSec,
            distanceM: data.distanceM,
            rpe: data.rpe,
            enteredUnit: block.exercise.tracksWeight ? data.unit : null,
            isWarmup: data.isWarmup,
            completed: data.completed,
          ),
        );
  }

  Future<void> _deleteSet(_ExerciseBlock block, _LoggedSet logged) async {
    await ref.read(trainingRepositoryProvider).deleteSet(logged.id);
    setState(() => block.sets.remove(logged));
  }

  Future<void> _finish() async {
    setState(() => _finishing = true);
    final effort = await _askEffort();
    await ref
        .read(trainingServiceProvider)
        .finishSession(widget.sessionId, perceivedEffort: effort);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<int?> _askEffort() async {
    int? selected;
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Session effort (RPE)',
            style: TextStyle(color: AppColors.textHi)),
        content: StatefulBuilder(
          builder: (ctx, setLocal) => Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 1; i <= 10; i++)
                ChoiceChip(
                  label: Text('$i'),
                  selected: selected == i,
                  onSelected: (_) => setLocal(() => selected = i),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Skip')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: const Text('Done')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.ember),
        title: Text(
          'Workout',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textHi,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _restRemaining > 0 ? 'Stop rest' : 'Start rest',
            icon: Icon(
              _restRemaining > 0
                  ? PhosphorIconsFill.timer
                  : PhosphorIconsRegular.timer,
              color: AppColors.ember,
            ),
            onPressed: () => _restRemaining > 0 ? _stopRest() : _startRest(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.line),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.ember))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                if (_blocks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(PhosphorIconsDuotone.barbell,
                            size: 56, color: AppColors.textLow),
                        const SizedBox(height: 12),
                        Text('No exercises yet',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textHi,
                            )),
                        const SizedBox(height: 4),
                        const Text('Add an exercise to start logging sets.',
                            style: TextStyle(color: AppColors.textMid)),
                      ],
                    ),
                  ),
                for (final block in _blocks) _buildBlock(block),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(PhosphorIconsBold.plus,
                      color: AppColors.ember, size: 18),
                  label: const Text('Add exercise',
                      style: TextStyle(
                          color: AppColors.ember,
                          fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.ember),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _loading
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_restRemaining > 0) ...[
                    _buildRestBar(),
                    const SizedBox(height: 10),
                  ],
                  PrimaryButton(
                    label: 'Finish workout',
                    icon: PhosphorIconsBold.check,
                    loading: _finishing,
                    onPressed: _finishing ? null : _finish,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildRestBar() {
    final progress = _restTotal == 0 ? 0.0 : _restRemaining / _restTotal;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.ember.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ember.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsFill.timer,
                  size: 20, color: AppColors.ember),
              const SizedBox(width: 8),
              Text('Rest',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMid,
                  )),
              const SizedBox(width: 10),
              Text(_fmtRest(_restRemaining),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHi,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
              const Spacer(),
              _restChip('-15', () => _bumpRest(-15)),
              const SizedBox(width: 6),
              _restChip('+15', () => _bumpRest(15)),
              const SizedBox(width: 6),
              TextButton(
                onPressed: _stopRest,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.ember,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text('Skip',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.ember.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.ember),
            ),
          ),
        ],
      ),
    );
  }

  Widget _restChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(label,
            style: const TextStyle(
                color: AppColors.ember,
                fontWeight: FontWeight.w800,
                fontSize: 13)),
      ),
    );
  }

  Widget _buildBlock(_ExerciseBlock block) {
    final e = block.exercise;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassPanel(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(e.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHi,
                        )),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(PhosphorIconsRegular.chartLineUp,
                        size: 18, color: AppColors.ember),
                    tooltip: 'Progression',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) =>
                              ExerciseDetailScreen(exercise: e)),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(PhosphorIconsRegular.trash,
                        size: 18, color: AppColors.textLow),
                    onPressed: () => _removeBlock(block),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < block.sets.length; i++)
              SetRow(
                key: ValueKey(block.sets[i].id),
                setNumber: i + 1,
                exercise: e,
                data: block.sets[i].data,
                previous: i < block.previousSets.length
                    ? block.previousSets[i]
                    : null,
                onChanged: (_) => _persistSet(block, block.sets[i]),
                onDelete: () => _deleteSet(block, block.sets[i]),
                onToggleComplete: () => _onSetCompleted(block, block.sets[i]),
              ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addSet(block),
                      icon: const Icon(PhosphorIconsRegular.plus,
                          size: 16, color: AppColors.ember),
                      label: const Text('Add set',
                          style: TextStyle(color: AppColors.ember)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.line),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (block.sets.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _addSet(block,
                            template: block.sets.last.data),
                        icon: const Icon(PhosphorIconsRegular.copy,
                            size: 16, color: AppColors.ember),
                        label: const Text('Repeat last',
                            style: TextStyle(color: AppColors.ember)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.line),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeBlock(_ExerciseBlock block) async {
    final repo = ref.read(trainingRepositoryProvider);
    for (final s in block.sets) {
      await repo.deleteSet(s.id);
    }
    setState(() => _blocks.remove(block));
  }
}

/// Display-side weight conversion helper kept local to the logger.
class WeightToDisplay {
  static double lb(double kg) => kg / 0.45359237;
}

/// Builds a partial [SetEntriesCompanion] update for an existing set row.
class SetEntriesUpdate {
  static SetEntriesCompanion build({
    int? reps,
    double? weightKg,
    int? durationSec,
    double? distanceM,
    double? rpe,
    String? enteredUnit,
    required bool isWarmup,
    bool? completed,
  }) {
    return SetEntriesCompanion(
      reps: Value(reps),
      weightKg: Value(weightKg),
      durationSec: Value(durationSec),
      distanceM: Value(distanceM),
      rpe: Value(rpe),
      enteredUnit: Value(enteredUnit),
      isWarmup: Value(isWarmup),
      completed:
          completed == null ? const Value.absent() : Value(completed),
    );
  }
}
