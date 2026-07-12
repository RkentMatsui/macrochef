import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/database.dart';
import '../../services/exercise_library.dart';
import '../../services/schedule_service.dart';
import '../../services/template_seed.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../widgets/cards.dart';
import '../widgets/glass_panel.dart';
import '../widgets/macro_ring.dart';
import 'program_generator_screen.dart';
import 'schedule_screen.dart';
import 'session_logger_screen.dart';
import 'templates_screen.dart';
import 'training_analytics_screen.dart';
// import 'voice_workout_screen.dart';

/// Root of the Train tab: start an empty workout, browse recent sessions, plus
/// disabled placeholders for features wired in later phases (templates,
/// schedule, analytics, AI). Seeds the built-in exercise catalog on first show.
class TrainingHomeScreen extends ConsumerStatefulWidget {
  final bool isActive;
  const TrainingHomeScreen({super.key, this.isActive = true});

  @override
  ConsumerState<TrainingHomeScreen> createState() => _TrainingHomeScreenState();
}

class _TrainingHomeScreenState extends ConsumerState<TrainingHomeScreen> {
  late Future<List<WorkoutSession>> _sessionsFuture;
  late Future<_TodayPlan> _todayFuture;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    // Initialize the late futures synchronously so the first build() never
    // reads them before assignment. _seedAndLoad() seeds in the background and
    // re-runs _loadSessions() afterwards to pick up newly-seeded programs.
    _loadSessions();
    _seedAndLoad();
  }

  @override
  void didUpdateWidget(TrainingHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      setState(_loadSessions);
    }
  }

  Future<void> _seedAndLoad() async {
    final repo = ref.read(trainingRepositoryProvider);
    await seedExercises(repo);
    await seedStarterPrograms(repo, ref.read(settingsRepositoryProvider));
    if (mounted) setState(_loadSessions);
  }

  void _loadSessions() {
    _sessionsFuture =
        ref.read(trainingRepositoryProvider).recentSessions(limit: 30);
    _todayFuture = _loadToday();
  }

  Future<_TodayPlan> _loadToday() async {
    final schedule = ref.read(scheduleServiceProvider);
    final now = DateTime.now();
    final planned = await schedule.plannedForDate(now);
    final adherence = await schedule.adherenceForWeek(now);
    return _TodayPlan(planned: planned, adherence: adherence);
  }

  Future<void> _startEmpty() async {
    setState(() => _starting = true);
    final navigator = Navigator.of(context);
    final svc = ref.read(trainingServiceProvider);
    final id = await svc.startEmptySession(todayDate(), name: 'Workout');
    if (!mounted) return;
    setState(() => _starting = false);
    await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => SessionLoggerScreen(sessionId: id)),
    );
    if (mounted) setState(_loadSessions);
  }

  Future<void> _startFromDay(int dayId) async {
    setState(() => _starting = true);
    final navigator = Navigator.of(context);
    final svc = ref.read(trainingServiceProvider);
    final id = await svc.startFromDay(dayId, todayDate());
    if (!mounted) return;
    setState(() => _starting = false);
    await navigator.push<bool>(
      MaterialPageRoute(builder: (_) => SessionLoggerScreen(sessionId: id)),
    );
    if (mounted) setState(_loadSessions);
  }

  // Future<void> _startEmptyVoice() async {
  //   setState(() => _starting = true);
  //   final navigator = Navigator.of(context);
  //   final svc = ref.read(trainingServiceProvider);
  //   final id = await svc.startEmptySession(todayDate(), name: 'Voice workout');
  //   if (!mounted) return;
  //   setState(() => _starting = false);
  //   await navigator.push<bool>(
  //     MaterialPageRoute(
  //       builder: (_) => VoiceWorkoutScreen(sessionId: id, dayId: null),
  //     ),
  //   );
  //   if (mounted) setState(_loadSessions);
  // }
  //
  // Future<void> _startFromDayVoice(int dayId) async {
  //   setState(() => _starting = true);
  //   final navigator = Navigator.of(context);
  //   final svc = ref.read(trainingServiceProvider);
  //   final id = await svc.startFromDay(dayId, todayDate());
  //   if (!mounted) return;
  //   setState(() => _starting = false);
  //   await navigator.push<bool>(
  //     MaterialPageRoute(
  //       builder: (_) => VoiceWorkoutScreen(sessionId: id, dayId: dayId),
  //     ),
  //   );
  //   if (mounted) setState(_loadSessions);
  // }

  /// Entry for the hero "Voice workout" button: use today's plan if present,
  /// otherwise let the user pick a program day or go freeform.
  // Future<void> _onVoiceTap() async {
  //   final plan = await _todayFuture;
  //   if (!mounted) return;
  //   if (plan.planned.isNotEmpty) {
  //     await _startFromDayVoice(plan.planned.first.dayId);
  //   } else {
  //     await _pickDayForVoice();
  //   }
  // }

  // Future<void> _pickDayForVoice() async {
  //   final repo = ref.read(trainingRepositoryProvider);
  //   final programs = await repo.allPrograms();
  //   final entries = <({String label, int? dayId})>[
  //     (label: 'Freeform (no program)', dayId: null),
  //   ];
  //   for (final p in programs) {
  //     final days = await repo.daysForProgram(p.id);
  //     for (final d in days) {
  //       entries.add((label: '${p.name} · ${d.name}', dayId: d.id));
  //     }
  //   }
  //   if (!mounted) return;
  //   final chosen = await showModalBottomSheet<({String label, int? dayId})>(
  //     context: context,
  //     backgroundColor: AppColors.surface,
  //     builder: (ctx) => SafeArea(
  //       child: ListView(
  //         shrinkWrap: true,
  //         children: [
  //           for (final e in entries)
  //             ListTile(
  //               title: Text(e.label,
  //                   style: const TextStyle(color: AppColors.textHi)),
  //               leading: Icon(
  //                 e.dayId == null
  //                     ? PhosphorIconsBold.microphone
  //                     : PhosphorIconsBold.listChecks,
  //                 color: AppColors.ember,
  //               ),
  //               onTap: () => Navigator.of(ctx).pop(e),
  //             ),
  //         ],
  //       ),
  //     ),
  //   );
  //   if (chosen == null || !mounted) return;
  //   if (chosen.dayId == null) {
  //     await _startEmptyVoice();
  //   } else {
  //     await _startFromDayVoice(chosen.dayId!);
  //   }
  // }

  Future<void> _openTemplates() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TemplatesScreen()),
    );
    if (mounted) setState(_loadSessions);
  }

  Future<void> _openSchedule() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScheduleScreen()),
    );
    if (mounted) setState(_loadSessions);
  }

  Future<void> _openAnalytics() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TrainingAnalyticsScreen()),
    );
    if (mounted) setState(_loadSessions);
  }

  Future<void> _openGenerator() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProgramGeneratorScreen()),
    );
    if (mounted) setState(_loadSessions);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
        title: Text(
          'Train',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textHi,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.line),
        ),
      ),
      body: ListView(
        // Clear the floating bottom nav (it overlays the body via extendBody),
        // so the last recent-session row isn't hidden behind it.
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).padding.bottom + 96),
        children: [
          _buildHero(tt),
          const SizedBox(height: 16),
          _buildToday(tt),
          const SizedBox(height: 20),
          _buildQuickActions(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text('Recent sessions',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHi,
                )),
          ),
          _buildRecent(tt),
        ],
      ),
    );
  }

  Widget _buildHero(TextTheme tt) {
    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(PhosphorIconsDuotone.barbell,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ready to train?',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 4),
                    Text('Log strength, cardio, or a class — your way.',
                        style: tt.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.4,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _starting ? null : _startEmpty,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _starting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.ember),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsBold.plus,
                            color: AppColors.ember, size: 18),
                        SizedBox(width: 8),
                        Text('Start empty workout',
                            style: TextStyle(
                              color: AppColors.ember,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            )),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _starting ? null : _openTemplates,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIconsBold.listChecks,
                      color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Start from template',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          //commented out voice workout
          // GestureDetector(
          //   onTap: _starting ? null : _onVoiceTap,
          //   child: Container(
          //     width: double.infinity,
          //     padding: const EdgeInsets.symmetric(vertical: 13),
          //     alignment: Alignment.center,
          //     decoration: BoxDecoration(
          //       color: Colors.white.withValues(alpha: 0.16),
          //       borderRadius: BorderRadius.circular(16),
          //       border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          //     ),
          //     child: const Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         Icon(PhosphorIconsBold.microphone,
          //             color: Colors.white, size: 18),
          //         SizedBox(width: 8),
          //         Text('Voice workout (hands-free)',
          //             style: TextStyle(
          //               color: Colors.white,
          //               fontWeight: FontWeight.w800,
          //               fontSize: 15,
          //             )),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildToday(TextTheme tt) {
    return FutureBuilder<_TodayPlan>(
      future: _todayFuture,
      builder: (context, snap) {
        final plan = snap.data;
        if (plan == null) {
          return const SizedBox.shrink();
        }
        final planned = plan.planned;
        final adherence = plan.adherence;
        final pct = (adherence.fraction * 100).round();
        return GlassPanel(
          child: Row(
            children: [
              MacroRing(
                progress: adherence.fraction,
                color: AppColors.protein,
                size: 72,
                stroke: 8,
                center: Text('$pct%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textHi,
                    )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Today',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMid,
                          letterSpacing: 0.4,
                        )),
                    const SizedBox(height: 2),
                    if (planned.isEmpty)
                      Text('Rest day — no session planned',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHi,
                          ))
                    else
                      Text(planned.map((p) => p.name).join(' · '),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHi,
                          )),
                    const SizedBox(height: 2),
                    Text(
                      adherence.planned == 0
                          ? 'No weekly plan set'
                          : 'This week: ${adherence.completed}/${adherence.planned} sessions',
                      style: tt.bodySmall?.copyWith(color: AppColors.textMid),
                    ),
                    const SizedBox(height: 10),
                    if (planned.isEmpty)
                      _todayButton(
                        label: 'Start empty',
                        icon: PhosphorIconsBold.plus,
                        onTap: _starting ? null : _startEmpty,
                      )
                    else
                      _todayButton(
                        label: 'Start ${planned.first.name}',
                        icon: PhosphorIconsBold.play,
                        onTap: _starting
                            ? null
                            : () => _startFromDay(planned.first.dayId),
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

  Widget _todayButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.ember,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.canvas, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.canvas,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _activeTile(
              PhosphorIconsDuotone.listChecks, 'Templates', _openTemplates),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _activeTile(
              PhosphorIconsDuotone.calendarDots, 'Schedule', _openSchedule),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _activeTile(
              PhosphorIconsDuotone.chartLineUp, 'Analytics', _openAnalytics),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _activeTile(
              PhosphorIconsDuotone.sparkle, 'AI plan', _openGenerator),
        ),
      ],
    );
  }

  Widget _activeTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.ember, size: 24),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textHi,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecent(TextTheme tt) {
    return FutureBuilder<List<WorkoutSession>>(
      future: _sessionsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: AppColors.ember),
            ),
          );
        }
        final sessions = snap.data ?? [];
        if (sessions.isEmpty) {
          return GlassPanel(
            child: Text('No workouts yet. Start one above to see it here.',
                style: tt.bodyMedium?.copyWith(color: AppColors.textMid)),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < sessions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: ValueKey('session-${sessions[i].id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: AppColors.fat.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(PhosphorIconsBold.trash,
                        color: AppColors.fat),
                  ),
                  confirmDismiss: (_) => _confirmDeleteSession(sessions[i]),
                  onDismissed: (_) {
                    if (mounted) setState(_loadSessions);
                  },
                  child: _sessionRow(tt, sessions[i]),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Confirm + delete a session (cascades its logged sets). Returns true when
  /// deleted so the Dismissible animates the row away.
  Future<bool> _confirmDeleteSession(WorkoutSession s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete workout?',
            style: TextStyle(color: AppColors.textHi)),
        content: Text(
          'This permanently removes "${s.name}" and its logged sets.',
          style: const TextStyle(color: AppColors.textMid),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.fat)),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    await ref.read(trainingRepositoryProvider).deleteSession(s.id);
    return true;
  }

  Widget _sessionRow(TextTheme tt, WorkoutSession s) {
    final completed = s.completedAt != null;
    final duration = s.durationSec;
    final subtitle = [
      s.date,
      if (duration != null) '${(duration / 60).round()} min',
      if (s.perceivedEffort != null) 'RPE ${s.perceivedEffort}',
      if (!completed) 'in progress',
    ].join(' · ');
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => SessionLoggerScreen(sessionId: s.id)),
        );
        if (mounted) setState(_loadSessions);
      },
      child: GlassPanel(
        frosted: false,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (completed ? AppColors.protein : AppColors.fat)
                    .withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                completed
                    ? PhosphorIconsDuotone.checkCircle
                    : PhosphorIconsDuotone.hourglassMedium,
                color: completed ? AppColors.protein : AppColors.fat,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHi,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: tt.bodySmall?.copyWith(color: AppColors.textMid)),
                ],
              ),
            ),
            const Icon(PhosphorIconsRegular.caretRight,
                color: AppColors.textLow),
          ],
        ),
      ),
    );
  }
}

/// Today's planned session(s) plus this week's planned-vs-actual adherence,
/// loaded together for the Today card.
class _TodayPlan {
  final List<PlannedSession> planned;
  final WeekAdherence adherence;
  const _TodayPlan({required this.planned, required this.adherence});
}
