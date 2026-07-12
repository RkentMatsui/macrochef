import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/database.dart';
import '../../services/progression_service.dart';
import '../../services/volume_landmarks.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../widgets/glass_panel.dart';
import '../widgets/macro_ring.dart';
import 'exercise_detail_screen.dart';
import 'widgets/muscle_map.dart';

/// Training analytics overview: weekly volume-by-muscle (bar), consistency ring
/// + streak, and a per-exercise drill-down list into [ExerciseDetailScreen].
class TrainingAnalyticsScreen extends ConsumerStatefulWidget {
  const TrainingAnalyticsScreen({super.key});

  @override
  ConsumerState<TrainingAnalyticsScreen> createState() =>
      _TrainingAnalyticsScreenState();
}

class _TrainingAnalyticsScreenState
    extends ConsumerState<TrainingAnalyticsScreen> {
  late Future<_AnalyticsData> _future;

  /// Per-exercise progression filter: null = all, otherwise a `primaryMuscle`
  /// key or the special `'cardio'` category bucket.
  String? _progFilter;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AnalyticsData> _load() async {
    final svc = ref.read(progressionServiceProvider);
    final repo = ref.read(trainingRepositoryProvider);
    final activityRepo = ref.read(dailyActivityRepositoryProvider);
    final weightService = ref.read(weightServiceProvider);
    final now = DateTime.now();
    final byMuscle = await svc.weeklyVolumeByMuscle(now);
    final breakdown = await svc.weeklyMuscleBreakdown(now);
    final consistency = await svc.consistency(now: now, weeks: 8);
    final exercises = await repo.allExercises();

    // Activity + body-weight trend over the same trailing window so the step
    // line can be overlaid on the weight trend.
    final weightSeries = await weightService.trendSeries();
    final isLbs = await weightService.isLbs;
    final start = now.subtract(const Duration(days: 89));
    final activity = await activityRepo.range(_ymd(start), _ymd(now));
    final today = await activityRepo.forDate(_ymd(now));

    return _AnalyticsData(
      byMuscle: byMuscle,
      breakdown: breakdown,
      consistency: consistency,
      exercises: exercises,
      activity: activity,
      today: today,
      weightSeries: weightSeries,
      isLbs: isLbs,
    );
  }

  /// Days between [ymd] (YYYY-MM-DD) and today, clamped at 0.
  static int _daysAgo(String ymd) {
    final d = DateTime.tryParse(ymd);
    if (d == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;
    return diff < 0 ? 0 : diff;
  }

  static String _ymd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.ember),
        title: Text(
          'Analytics',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textHi,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.line),
        ),
      ),
      body: FutureBuilder<_AnalyticsData>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.ember));
          }
          final data = snap.data!;
          return RefreshIndicator(
            color: AppColors.ember,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                _consistencyCard(tt, data.consistency),
                const SizedBox(height: 24),
                _sectionLabel('Daily activity'),
                const SizedBox(height: 12),
                _activityCard(tt, data),
                const SizedBox(height: 24),
                _sectionLabel('This week · muscles trained'),
                const SizedBox(height: 12),
                _muscleMapCard(tt, data.byMuscle, data.breakdown),
                const SizedBox(height: 24),
                _sectionLabel('This week · volume by muscle'),
                const SizedBox(height: 12),
                _muscleVolume(tt, data.byMuscle),
                const SizedBox(height: 24),
                _sectionLabel('Per-exercise progression'),
                const SizedBox(height: 12),
                _exerciseFilterChips(data.exercises),
                const SizedBox(height: 12),
                _exerciseList(tt, data.exercises),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.textHi,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      );

  Widget _consistencyCard(TextTheme tt, ConsistencyStats c) {
    // Ring shows how close sessions/week is to a 4×/week goal.
    final progress = (c.sessionsPerWeek / 4.0).clamp(0.0, 1.0);
    return GlassPanel(
      child: Row(
        children: [
          MacroRing(
            progress: progress,
            color: AppColors.protein,
            size: 80,
            stroke: 9,
            center: Text(c.sessionsPerWeek.toStringAsFixed(1),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHi,
                )),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Consistency',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMid,
                      letterSpacing: 0.4,
                    )),
                const SizedBox(height: 4),
                Text(
                    '${c.sessionsPerWeek.toStringAsFixed(1)} sessions / week',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHi,
                    )),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(PhosphorIconsFill.fire,
                        size: 16, color: AppColors.fat),
                    const SizedBox(width: 4),
                    Text('${c.currentStreakWeeks}-week streak',
                        style: tt.bodySmall
                            ?.copyWith(color: AppColors.textMid)),
                    const SizedBox(width: 10),
                    Text('${c.totalSessions} in ${c.weeks}w',
                        style: tt.bodySmall
                            ?.copyWith(color: AppColors.textLow)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityCard(TextTheme tt, _AnalyticsData data) {
    final today = data.today;
    final steps = today?.steps;
    final activeMin = today?.activeMinutes;
    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _activityStat(
                  icon: PhosphorIconsDuotone.footprints,
                  label: 'Steps today',
                  value: steps == null ? '—' : _grouped(steps),
                  color: AppColors.protein,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _activityStat(
                  icon: PhosphorIconsDuotone.timer,
                  label: 'Active min',
                  value: activeMin == null ? '—' : '$activeMin',
                  color: AppColors.carb,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.ember.withValues(alpha: 0.10),
                foregroundColor: AppColors.ember,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _editActivity(today),
              icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 18),
              label: Text(
                today == null ? "Log today's activity" : "Edit today's activity",
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _stepTrendChart(tt, data),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.info,
                  size: 14, color: AppColors.textLow),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Activity is informational only — it does NOT change your '
                  'calorie targets.',
                  style: tt.bodySmall?.copyWith(color: AppColors.textLow),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textMid,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: tabularFigures.copyWith(
                        color: AppColors.textHi,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Step trend overlaid on the body-weight trend. Both series are normalised to
  /// 0..1 over the visible window so two very different scales (kg vs thousands
  /// of steps) can share one axis; this is a contextual overlay, not a precise
  /// dual-axis chart.
  Widget _stepTrendChart(TextTheme tt, _AnalyticsData data) {
    final activity = data.activity.where((a) => a.steps != null).toList();
    final weight = data.weightSeries;
    if (activity.isEmpty && weight.isEmpty) {
      return Text('No steps or weight logged yet.',
          style: tt.bodySmall?.copyWith(color: AppColors.textMid));
    }

    // Build a sorted union of dates so both lines share the x-axis indices.
    final dates = <String>{
      ...activity.map((a) => a.date),
      ...weight.map((w) => w.date),
    }.toList()
      ..sort();
    final indexOf = {for (var i = 0; i < dates.length; i++) dates[i]: i};

    double norm(double v, double lo, double hi) =>
        hi <= lo ? 0.5 : (v - lo) / (hi - lo);

    final stepSpots = <FlSpot>[];
    if (activity.isNotEmpty) {
      final vals = activity.map((a) => a.steps!.toDouble()).toList();
      final lo = vals.reduce((a, b) => a < b ? a : b);
      final hi = vals.reduce((a, b) => a > b ? a : b);
      for (final a in activity) {
        stepSpots.add(FlSpot(
            indexOf[a.date]!.toDouble(), norm(a.steps!.toDouble(), lo, hi)));
      }
    }

    final weightSpots = <FlSpot>[];
    if (weight.isNotEmpty) {
      final vals = weight.map((w) => w.trend).toList();
      final lo = vals.reduce((a, b) => a < b ? a : b);
      final hi = vals.reduce((a, b) => a > b ? a : b);
      for (final w in weight) {
        weightSpots.add(
            FlSpot(indexOf[w.date]!.toDouble(), norm(w.trend, lo, hi)));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _legendDot(AppColors.protein, 'Steps'),
            const SizedBox(width: 16),
            _legendDot(AppColors.ember, 'Weight trend'),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: LineChart(
            LineChartData(
              minY: -0.05,
              maxY: 1.05,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: const FlTitlesData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                if (stepSpots.isNotEmpty)
                  LineChartBarData(
                    spots: stepSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.protein,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.protein.withValues(alpha: 0.16),
                          AppColors.protein.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                if (weightSpots.isNotEmpty)
                  LineChartBarData(
                    spots: weightSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.ember,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textMid,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      );

  String _grouped(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Future<void> _editActivity(DailyActivityData? existing) async {
    final stepsCtrl =
        TextEditingController(text: existing?.steps?.toString() ?? '');
    final minCtrl = TextEditingController(
        text: existing?.activeMinutes?.toString() ?? '');
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text("Today's activity",
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHi)),
                const SizedBox(height: 16),
                _activityField(stepsCtrl, 'Steps', PhosphorIconsDuotone.footprints),
                const SizedBox(height: 12),
                _activityField(
                    minCtrl, 'Active minutes', PhosphorIconsDuotone.timer),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ember,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text('Save',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (saved == true) {
      final steps = int.tryParse(stepsCtrl.text.trim());
      final mins = int.tryParse(minCtrl.text.trim());
      await ref
          .read(dailyActivityRepositoryProvider)
          .upsert(_ymd(DateTime.now()), steps: steps, activeMinutes: mins);
      if (mounted) await _refresh();
    }
    stepsCtrl.dispose();
    minCtrl.dispose();
  }

  Widget _activityField(
      TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      style: tabularFigures.copyWith(
          color: AppColors.textHi, fontSize: 16, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.plusJakartaSans(color: AppColors.textMid, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.ember, size: 22),
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.ember, width: 1.5),
        ),
      ),
    );
  }

  Widget _muscleMapCard(
    TextTheme tt,
    Map<String, double> byMuscle,
    Map<String, MuscleBreakdown> breakdown,
  ) {
    if (byMuscle.isEmpty) {
      return GlassPanel(
        radius: 24,
        child: Text('No muscles trained yet this week.',
            style: tt.bodyMedium?.copyWith(color: AppColors.textMid)),
      );
    }
    // Colour by research-based hypertrophy volume: each muscle reddens as its
    // weekly working-set count approaches its MAV target (RP / Israetel
    // landmarks, cross-checked vs Schoenfeld dose-response). Full red = weekly
    // hypertrophy target hit — not "most volume of the week".
    final fill = <String, double>{
      for (final e in breakdown.entries)
        e.key: hypertrophyFill(e.key, e.value.sets),
    };
    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MuscleMap(
            intensity: fill,
            onMuscleTap: (muscle) => _showMuscleSheet(muscle, breakdown),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(PhosphorIconsRegular.handTap,
                  size: 14, color: AppColors.textLow),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Red = weekly hypertrophy set target hit. '
                  'Tap a muscle for its breakdown.',
                  style: tt.bodySmall?.copyWith(color: AppColors.textLow),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _muscleLabel(String key) {
    switch (key) {
      case 'rear-delts':
        return 'Rear delts';
      case 'core':
        return 'Core / abs';
      default:
        return key[0].toUpperCase() + key.substring(1);
    }
  }

  String _recoveryText(int days) {
    if (days <= 0) return 'Trained today';
    if (days == 1) return 'Trained yesterday';
    return 'Last trained $days days ago';
  }

  /// Weekly working-set count against this muscle's research-based hypertrophy
  /// landmarks (RP / Israetel MEV→MAV→MRV). The bar fills to the MAV target;
  /// the caption names the zone the lifter is in.
  /// Formats a fractional set count: whole numbers drop the decimal, halves
  /// show one place (e.g. 12 → "12", 12.5 → "12.5").
  static String _fmtSets(double s) =>
      s == s.roundToDouble() ? s.toStringAsFixed(0) : s.toStringAsFixed(1);

  Widget _volumeTarget(
      TextTheme tt, String muscle, double sets, MuscleVolumeLandmark lm) {
    final fill = hypertrophyFill(muscle, sets);
    final String status;
    final Color statusColor;
    if (sets < lm.mev) {
      status = 'Below effective volume (MEV ${lm.mev})';
      statusColor = AppColors.textMid;
    } else if (sets < lm.mav) {
      status = 'Productive — building toward target';
      statusColor = AppColors.accent;
    } else if (sets <= lm.mrv) {
      status = 'At hypertrophy target 🔥';
      statusColor = AppColors.danger;
    } else {
      status = 'Above recoverable volume — consider a deload';
      statusColor = AppColors.danger;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Weekly sets',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHi)),
            const Spacer(),
            Text('${_fmtSets(sets)} / ${lm.mav} target',
                style: tabularFigures.copyWith(
                    color: AppColors.textMid, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fill.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.surfaceHigh,
            valueColor: AlwaysStoppedAnimation(statusColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(status,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: statusColor)),
      ],
    );
  }

  Future<void> _showMuscleSheet(
    String muscle,
    Map<String, MuscleBreakdown> breakdown,
  ) async {
    // The back view's rear-delt region borrows general shoulder volume when no
    // dedicated rear-delt work exists, so resolve the tap to whichever key
    // actually has data (keeping the sheet consistent with what glowed).
    var resolved = muscle;
    var data = breakdown[muscle];
    if (data == null && muscle == 'rear-delts' &&
        breakdown['shoulders'] != null) {
      resolved = 'shoulders';
      data = breakdown['shoulders'];
    }
    final tt = Theme.of(context).textTheme;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              child: ListView(
                controller: scrollCtrl,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.line,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_muscleLabel(resolved),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHi)),
                  const SizedBox(height: 4),
                  Text('This week',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMid,
                          letterSpacing: 0.3)),
                  const SizedBox(height: 18),
                  if (data == null)
                    Text('No working-set volume logged for this muscle '
                        'this week.',
                        style:
                            tt.bodyMedium?.copyWith(color: AppColors.textMid))
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _activityStat(
                            icon: PhosphorIconsDuotone.barbell,
                            label: 'Sets',
                            value: _fmtSets(data.sets),
                            color: AppColors.protein,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _activityStat(
                            icon: PhosphorIconsDuotone.stack,
                            label: 'Volume',
                            value: '${_grouped(data.volume.round())} kg',
                            color: AppColors.ember,
                          ),
                        ),
                      ],
                    ),
                    if (kMuscleVolumeLandmarks[resolved] != null) ...[
                      const SizedBox(height: 16),
                      _volumeTarget(tt, resolved, data.sets,
                          kMuscleVolumeLandmarks[resolved]!),
                    ],
                    if (data.lastTrained != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Icon(
                            PhosphorIconsFill.circle,
                            size: 12,
                            color: _recoveryColor(_daysAgo(data.lastTrained!)),
                          ),
                          const SizedBox(width: 8),
                          Text(_recoveryText(_daysAgo(data.lastTrained!)),
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMid)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text('Exercises',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHi)),
                    const SizedBox(height: 10),
                    for (final ex in data.exercises)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(ex.name,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textHi)),
                            ),
                            Text(
                                '${_fmtSets(ex.sets)} × · '
                                '${_grouped(ex.volume.round())} kg',
                                style: tabularFigures.copyWith(
                                    color: AppColors.textMid, fontSize: 13)),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _recoveryColor(int days) => days <= 0
      ? AppColors.fat
      : days <= 2
          ? AppColors.carb
          : AppColors.protein;

  Widget _muscleVolume(TextTheme tt, Map<String, double> byMuscle) {
    if (byMuscle.isEmpty) {
      return GlassPanel(
        radius: 24,
        child: Text('No working-set volume logged this week.',
            style: tt.bodyMedium?.copyWith(color: AppColors.textMid)),
      );
    }
    final entries = byMuscle.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxV = entries.first.value;

    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxV * 1.15,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= entries.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            entries[i].key,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textMid,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < entries.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: entries[i].value,
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [AppColors.ember, AppColors.emberSoft],
                        ),
                        width: entries.length > 6 ? 10 : 18,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(5)),
                      ),
                    ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('Total volume (weight × reps) per muscle group this week.',
              style: tt.bodySmall?.copyWith(color: AppColors.textLow)),
        ],
      ),
    );
  }

  /// Filter buckets for an exercise: its `primaryMuscle` if set, else the
  /// `'cardio'` bucket for trackable cardio/class/mobility moves.
  static String _filterBucket(Exercise e) => e.primaryMuscle ?? 'cardio';

  Widget _exerciseFilterChips(List<Exercise> exercises) {
    final relevant = exercises
        .where((e) => e.tracksWeight || e.tracksDistance || e.tracksDuration)
        .toList();
    // Distinct buckets present, ordered for a stable, scannable chip row.
    const order = [
      'chest', 'back', 'shoulders', 'rear-delts', 'biceps', 'triceps',
      'forearms', 'core', 'quads', 'hamstrings', 'glutes', 'adductors',
      'abductors', 'calves', 'tibialis', 'cardio',
    ];
    final present = relevant.map(_filterBucket).toSet();
    final buckets = order.where(present.contains).toList();
    if (buckets.length < 2) return const SizedBox.shrink();

    // Clear a filter that no longer matches anything.
    if (_progFilter != null && !present.contains(_progFilter)) {
      _progFilter = null;
    }

    Widget chip(String? value, String label) {
      final selected = _progFilter == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => setState(() => _progFilter = value),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.ember : AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: selected ? AppColors.ember : AppColors.line),
            ),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textMid,
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          chip(null, 'All'),
          for (final b in buckets) chip(b, _filterLabel(b)),
        ],
      ),
    );
  }

  static String _filterLabel(String bucket) {
    switch (bucket) {
      case 'rear-delts':
        return 'Rear delts';
      case 'core':
        return 'Core';
      case 'cardio':
        return 'Cardio';
      default:
        return bucket[0].toUpperCase() + bucket.substring(1);
    }
  }

  Widget _exerciseList(TextTheme tt, List<Exercise> exercises) {
    // Only strength/cardio-style exercises that carry meaningful trends.
    final relevant = exercises
        .where((e) =>
            (e.tracksWeight || e.tracksDistance || e.tracksDuration) &&
            (_progFilter == null || _filterBucket(e) == _progFilter))
        .toList();
    if (relevant.isEmpty) {
      return GlassPanel(
        radius: 20,
        child: Text('No exercises match this filter.',
            style: tt.bodyMedium?.copyWith(color: AppColors.textMid)),
      );
    }
    return Column(
      children: [
        for (final e in relevant)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => ExerciseDetailScreen(exercise: e)),
              ),
              child: GlassPanel(
                frosted: false,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.ember.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(_iconFor(e.category),
                          color: AppColors.ember, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textHi,
                              )),
                          if (e.primaryMuscle != null)
                            Text(e.primaryMuscle!,
                                style: tabularFigures.copyWith(
                                    color: AppColors.textMid, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(PhosphorIconsRegular.caretRight,
                        color: AppColors.textLow),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  IconData _iconFor(String category) {
    switch (category) {
      case 'cardio':
        return PhosphorIconsDuotone.heartbeat;
      case 'class':
        return PhosphorIconsDuotone.usersThree;
      case 'mobility':
        return PhosphorIconsDuotone.personSimpleTaiChi;
      default:
        return PhosphorIconsDuotone.barbell;
    }
  }
}

class _AnalyticsData {
  final Map<String, double> byMuscle;
  final Map<String, MuscleBreakdown> breakdown;
  final ConsistencyStats consistency;
  final List<Exercise> exercises;
  final List<DailyActivityData> activity;
  final DailyActivityData? today;
  final List<({String date, double raw, double trend})> weightSeries;
  final bool isLbs;
  const _AnalyticsData({
    required this.byMuscle,
    required this.breakdown,
    required this.consistency,
    required this.exercises,
    required this.activity,
    required this.today,
    required this.weightSeries,
    required this.isLbs,
  });
}
