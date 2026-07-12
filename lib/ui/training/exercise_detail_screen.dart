import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/database.dart';
import '../../services/progression_service.dart';
import '../../services/weight_service.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../widgets/glass_panel.dart';

/// Which series the exercise-detail chart plots.
enum _Metric { est1rm, topSet, volume }

/// Per-exercise progression analytics: a line chart of est-1RM / top-set /
/// volume (toggle) with PR markers, plus a recent-history list. Reuses the
/// reports chart styling.
class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final Exercise exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  _Metric _metric = _Metric.est1rm;
  late Future<_DetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DetailData> _load() async {
    final svc = ref.read(progressionServiceProvider);
    final isLbs = await ref.read(weightServiceProvider).isLbs;
    final isCardio = widget.exercise.tracksDistance ||
        (widget.exercise.category == 'cardio');
    if (isCardio) {
      final cardio = await svc.cardioSeries(widget.exercise.id);
      return _DetailData(
          series: const [], prs: const [], cardio: cardio, isLbs: isLbs);
    }
    final series = await svc.exerciseSeries(widget.exercise.id);
    final prs = await svc.detectPrs(widget.exercise.id);
    return _DetailData(
        series: series, prs: prs, cardio: const [], isLbs: isLbs);
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isCardio = widget.exercise.tracksDistance ||
        widget.exercise.category == 'cardio';
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.ember),
        title: Text(
          widget.exercise.name,
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
      body: FutureBuilder<_DetailData>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.ember));
          }
          final data = snap.data!;
          if (isCardio) {
            return _buildCardio(tt, data);
          }
          if (data.series.isEmpty) {
            return _empty(tt);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              _howToCard(tt),
              _metricToggle(),
              const SizedBox(height: 18),
              _strengthChart(tt, data),
              const SizedBox(height: 24),
              _prSection(tt, data),
              const SizedBox(height: 24),
              _historyHeader(),
              const SizedBox(height: 12),
              _history(tt, data),
            ],
          );
        },
      ),
    );
  }

  Widget _empty(TextTheme tt) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        _howToCard(tt),
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(PhosphorIconsDuotone.chartLineUp,
                  size: 56, color: AppColors.textLow),
              const SizedBox(height: 12),
              Text('No history yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHi,
                  )),
              const SizedBox(height: 4),
              Text('Log this exercise in a workout to see progression here.',
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: AppColors.textMid)),
            ],
          ),
        ),
      ],
    );
  }

  /// "How to" card from the exercise's seeded description. Renders nothing when
  /// the exercise has no description (e.g. a user-created custom exercise).
  Widget _howToCard(TextTheme tt) {
    final desc = widget.exercise.description;
    if (desc == null || desc.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: GlassPanel(
        radius: 20,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(PhosphorIconsDuotone.info,
                    size: 18, color: AppColors.ember),
                const SizedBox(width: 8),
                Text('How to',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMid,
                      letterSpacing: 0.3,
                    )),
                if (widget.exercise.primaryMuscle != null) ...[
                  const Spacer(),
                  Text(widget.exercise.primaryMuscle!,
                      style: tabularFigures.copyWith(
                          color: AppColors.textLow, fontSize: 12)),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(desc,
                style: tt.bodyMedium?.copyWith(
                    color: AppColors.textHi, height: 1.35)),
          ],
        ),
      ),
    );
  }

  Widget _metricToggle() {
    Widget chip(String label, _Metric m) {
      final sel = _metric == m;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _metric = m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: sel ? AppColors.ember : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: sel ? Colors.white : AppColors.textMid,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Row(children: [
        chip('Est. 1RM', _Metric.est1rm),
        chip('Top set', _Metric.topSet),
        chip('Volume', _Metric.volume),
      ]),
    );
  }

  double _convWeight(double kg, bool isLbs) =>
      isLbs ? WeightService.kgToLb(kg) : kg;

  Widget _strengthChart(TextTheme tt, _DetailData data) {
    final isLbs = data.isLbs;
    final isVolume = _metric == _Metric.volume;
    String unit = isVolume ? (isLbs ? 'lb·reps' : 'kg·reps') : (isLbs ? 'lb' : 'kg');

    double valueOf(ProgressionPoint p) {
      switch (_metric) {
        case _Metric.est1rm:
          return _convWeight(p.best1rm, isLbs);
        case _Metric.topSet:
          return _convWeight(p.topSetWeightKg, isLbs);
        case _Metric.volume:
          return _convWeight(p.totalVolume, isLbs);
      }
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < data.series.length; i++) {
      spots.add(FlSpot(i.toDouble(), valueOf(data.series[i])));
    }
    final values = spots.map((s) => s.y).toList();
    final minY = (values.reduce((a, b) => a < b ? a : b)) * 0.95;
    final maxY = (values.reduce((a, b) => a > b ? a : b)) * 1.08;
    final latest = values.last;

    // PR session-dates (for the current metric, only est-1RM / top-set apply).
    final prDates = <String>{};
    if (_metric == _Metric.est1rm) {
      prDates.addAll(data.prs
          .where((p) => p.kind == PrKind.estimated1rm)
          .map((p) => p.date));
    } else if (_metric == _Metric.topSet) {
      prDates.addAll(
          data.prs.where((p) => p.kind == PrKind.weight).map((p) => p.date));
    }

    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Latest',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textMid,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(latest.toStringAsFixed(isVolume ? 0 : 1),
                  style: tabularFigures.copyWith(
                      color: AppColors.textHi,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              const SizedBox(width: 3),
              Text(unit,
                  style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textMid,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY <= minY ? minY + 1 : maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: AppColors.ember,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) {
                        final isPr = prDates.contains(data.series[idx].date);
                        return FlDotCirclePainter(
                          radius: isPr ? 5 : 3,
                          color: isPr ? AppColors.accent : AppColors.ember,
                          strokeWidth: isPr ? 2 : 0,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.ember.withValues(alpha: 0.18),
                          AppColors.ember.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (prDates.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      color: AppColors.accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('Personal record',
                    style: tt.bodySmall?.copyWith(color: AppColors.textMid)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _prSection(TextTheme tt, _DetailData data) {
    final isLbs = data.isLbs;
    Pr? bestWeight;
    Pr? best1rm;
    for (final p in data.prs) {
      if (p.kind == PrKind.weight) bestWeight = p;
      if (p.kind == PrKind.estimated1rm) best1rm = p;
    }
    final unit = isLbs ? 'lb' : 'kg';
    Widget stat(String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color: AppColors.protein.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textMid,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    )),
                const SizedBox(height: 8),
                Text(value,
                    style: tabularFigures.copyWith(
                      color: AppColors.textHi,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    )),
              ],
            ),
          ),
        );
    return Row(
      children: [
        stat(
            'Best set',
            bestWeight == null
                ? '—'
                : '${_convWeight(bestWeight.value, isLbs).toStringAsFixed(1)} $unit'),
        const SizedBox(width: 12),
        stat(
            'Est. 1RM',
            best1rm == null
                ? '—'
                : '${_convWeight(best1rm.value, isLbs).toStringAsFixed(1)} $unit'),
      ],
    );
  }

  Widget _historyHeader() {
    return Text('History',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textHi,
        ));
  }

  Widget _history(TextTheme tt, _DetailData data) {
    final isLbs = data.isLbs;
    final unit = isLbs ? 'lb' : 'kg';
    // Most recent first.
    final rows = data.series.reversed.toList();
    return Column(
      children: [
        for (final p in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassPanel(
              frosted: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(p.date,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHi,
                        )),
                  ),
                  Text(
                    'Top ${_convWeight(p.topSetWeightKg, isLbs).toStringAsFixed(1)} $unit · '
                    'e1RM ${_convWeight(p.best1rm, isLbs).toStringAsFixed(1)}',
                    style: tt.bodySmall?.copyWith(color: AppColors.textMid),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCardio(TextTheme tt, _DetailData data) {
    if (data.cardio.isEmpty) {
      return _empty(tt);
    }
    final points = data.cardio;
    // Distance in km; pace in min/km.
    final distSpots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      distSpots.add(FlSpot(i.toDouble(), (points[i].distanceM ?? 0) / 1000.0));
    }
    final distValues = distSpots.map((s) => s.y).toList();
    final hasDist = distValues.any((v) => v > 0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        _howToCard(tt),
        GlassPanel(
          radius: 24,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Distance (km)',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textMid,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: hasDist
                    ? LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: distSpots,
                              isCurved: true,
                              curveSmoothness: 0.3,
                              color: AppColors.ember,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.ember.withValues(alpha: 0.18),
                                    AppColors.ember.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Center(
                        child: Text('No distance logged',
                            style: tt.bodySmall
                                ?.copyWith(color: AppColors.textLow)),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _historyHeader(),
        const SizedBox(height: 12),
        for (final p in points.reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassPanel(
              frosted: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(p.date,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHi,
                        )),
                  ),
                  Text(_cardioSummary(p),
                      style:
                          tt.bodySmall?.copyWith(color: AppColors.textMid)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _cardioSummary(CardioPoint p) {
    final parts = <String>[];
    if (p.distanceM != null && p.distanceM! > 0) {
      parts.add('${(p.distanceM! / 1000).toStringAsFixed(2)} km');
    }
    if (p.durationSec != null && p.durationSec! > 0) {
      parts.add('${(p.durationSec! / 60).round()} min');
    }
    final pace = p.paceSecPerKm;
    if (pace != null) {
      final m = (pace / 60).floor();
      final s = (pace % 60).round().toString().padLeft(2, '0');
      parts.add('$m:$s /km');
    }
    return parts.isEmpty ? '—' : parts.join(' · ');
  }
}

class _DetailData {
  final List<ProgressionPoint> series;
  final List<Pr> prs;
  final List<CardioPoint> cardio;
  final bool isLbs;
  const _DetailData({
    required this.series,
    required this.prs,
    required this.cardio,
    required this.isLbs,
  });
}
