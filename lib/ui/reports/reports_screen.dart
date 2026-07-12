import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/daily.dart';
import '../../services/daily_log_service.dart';
import '../../services/date_range.dart';
import '../../services/weight_service.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../widgets/cards.dart';
import '../widgets/glass_panel.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _days = 7; // 7 or 30
  late Future<_ReportData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ReportData> _load() async {
    final svc = ref.read(dailyLogServiceProvider);
    final window = lastNDays(todayDate(), _days);
    final start = window.first;
    final end = window.last;
    final totals = await svc.rangeTotals(start, end);
    final top = await svc.topFoods(start, end);
    // EWMA is computed over the full history (continuity at the window edge),
    // then sliced to the displayed range.
    final allWeightSeries = await ref.read(weightServiceProvider).trendSeries();
    final weightSeries = allWeightSeries
        .where((s) => s.date.compareTo(start) >= 0 && s.date.compareTo(end) <= 0)
        .toList();
    final isLbs = await ref.read(weightServiceProvider).isLbs;
    return _ReportData(totals, top, weightSeries, isLbs);
  }

  void _setRange(int d) {
    setState(() {
      _days = d;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: FutureBuilder<_ReportData>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Could not load reports.',
                        style:
                            tt.bodyMedium?.copyWith(color: AppColors.textMid)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: const Text('Retry',
                          style: TextStyle(color: AppColors.ember)),
                    ),
                  ],
                ),
              );
            }
            if (!snap.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: AppColors.ember));
            }
            final data = snap.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  _rangeToggle(tt),
                  const SizedBox(height: 20),
                  _calorieHero(data),
                  const SizedBox(height: 24),
                  _sectionLabel('Calories'),
                  const SizedBox(height: 12),
                  _caloriesVsTarget(tt, data),
                  const SizedBox(height: 24),
                  _sectionLabel('Weight'),
                  const SizedBox(height: 12),
                  _weightChart(tt, data),
                  const SizedBox(height: 24),
                  _sectionLabel('Daily macro averages'),
                  const SizedBox(height: 12),
                  _macroAverages(tt, data),
                  const SizedBox(height: 24),
                  _sectionLabel('Top foods'),
                  const SizedBox(height: 12),
                  _topFoods(tt, data),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reports',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textHi,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your trends over the last $_days days',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textMid,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: AppColors.textHi,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    );
  }

  /// Headline HeroCard: average daily calories on logged days + target hit rate.
  Widget _calorieHero(_ReportData data) {
    final target = data.totals
        .map((t) => t.target?.kcal ?? 0.0)
        .firstWhere((k) => k > 0, orElse: () => 0.0);
    final logged = data.totals.where((t) => t.consumed.kcal > 0).toList();
    final avgKcal = logged.isEmpty
        ? 0.0
        : logged.fold<double>(0, (a, t) => a + t.consumed.kcal) / logged.length;
    final hit = data.totals
        .where((t) =>
            target > 0 && t.consumed.kcal <= target && t.consumed.kcal > 0)
        .length;

    return HeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVG DAILY CALORIES',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                avgKcal.toStringAsFixed(0),
                style: tabularFigures.copyWith(
                  color: Colors.white,
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'kcal',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            target > 0
                ? 'On target $hit of ${data.totals.length} days · goal ${target.toStringAsFixed(0)} kcal'
                : 'On ${logged.length} logged ${logged.length == 1 ? 'day' : 'days'}',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangeToggle(TextTheme tt) {
    Widget chip(String label, int d) {
      final sel = _days == d;
      return Expanded(
        child: GestureDetector(
          onTap: () => _setRange(d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
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
                fontSize: 13.5,
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
      child: Row(children: [chip('Last 7 days', 7), chip('Last 30 days', 30)]),
    );
  }

  Widget _caloriesVsTarget(TextTheme tt, _ReportData data) {
    final target = data.totals
        .map((t) => t.target?.kcal ?? 0.0)
        .firstWhere((k) => k > 0, orElse: () => 0.0);
    final hit = data.totals
        .where((t) => target > 0 && t.consumed.kcal <= target && t.consumed.kcal > 0)
        .length;
    final maxY = [
      target,
      ...data.totals.map((t) => t.consumed.kcal),
    ].fold<double>(0, (a, c) => c > a ? c : a) * 1.2;

    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Daily intake',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textMid,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              if (target > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.protein.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Hit $hit/${data.totals.length}',
                      style: GoogleFonts.plusJakartaSans(
                          color: AppColors.protein,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY <= 0 ? 100 : maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                extraLinesData: target > 0
                    ? ExtraLinesData(horizontalLines: [
                        HorizontalLine(
                            y: target,
                            color: AppColors.ember,
                            strokeWidth: 1,
                            dashArray: [6, 4]),
                      ])
                    : const ExtraLinesData(),
                barGroups: [
                  for (var i = 0; i < data.totals.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: data.totals[i].consumed.kcal,
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [AppColors.ember, AppColors.emberSoft],
                        ),
                        width: data.totals.length > 14 ? 5 : 12,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5)),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weightChart(TextTheme tt, _ReportData data) {
    if (data.weightSeries.isEmpty) {
      return GlassPanel(
        radius: 24,
        child: Text('No weight entries in this period.',
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.textLow,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      );
    }

    // Stored values are kg; convert to the user's display unit for the chart.
    double conv(double kg) => data.isLbs ? WeightService.kgToLb(kg) : kg;
    final rawValues = data.weightSeries.map((s) => conv(s.raw)).toList();
    final trendValues = data.weightSeries.map((s) => conv(s.trend)).toList();
    final allValues = [...rawValues, ...trendValues];
    final minY = allValues.reduce((a, b) => a < b ? a : b) - 1;
    final maxY = allValues.reduce((a, b) => a > b ? a : b) + 1;

    final rawSpots = <FlSpot>[];
    final trendSpots = <FlSpot>[];
    for (var i = 0; i < data.weightSeries.length; i++) {
      rawSpots.add(FlSpot(i.toDouble(), conv(data.weightSeries[i].raw)));
      trendSpots.add(FlSpot(i.toDouble(), conv(data.weightSeries[i].trend)));
    }

    final latestTrend = trendValues.last;
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
              Text('Trend',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textMid,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(latestTrend.toStringAsFixed(1),
                  style: tabularFigures.copyWith(
                      color: AppColors.textHi,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              const SizedBox(width: 3),
              Text(data.isLbs ? 'lb' : 'kg',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textMid,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineBarsData: [
                  // Raw dots
                  LineChartBarData(
                    spots: rawSpots,
                    isCurved: false,
                    color: AppColors.textLow,
                    barWidth: 0,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, idx) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.textLow,
                        strokeWidth: 0,
                        strokeColor: Colors.transparent,
                      ),
                    ),
                  ),
                  // Trend line
                  LineChartBarData(
                    spots: trendSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.ember,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
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
        ],
      ),
    );
  }

  Widget _macroAverages(TextTheme tt, _ReportData data) {
    // Average over days that actually have intake, so sparse logging isn't
    // diluted by untracked rest days ("g/day" = on days you logged).
    final logged =
        data.totals.where((t) => t.consumed.kcal > 0).toList();
    final n = logged.isEmpty ? 1 : logged.length;
    double avg(double Function(DailyTotals) f) =>
        logged.fold<double>(0, (a, t) => a + f(t)) / n;
    final p = avg((t) => t.consumed.protein);
    final c = avg((t) => t.consumed.carb);
    final f = avg((t) => t.consumed.fat);
    final kcalFromMacros = p * 4 + c * 4 + f * 9;
    String pct(double grams, double perGram) => kcalFromMacros <= 0
        ? '—'
        : '${(grams * perGram / kcalFromMacros * 100).toStringAsFixed(0)}%';

    final hasFibre = logged.any((t) => t.consumed.fibre != null);
    final fibreAvg = hasFibre
        ? logged.fold<double>(0, (a, t) => a + (t.consumed.fibre ?? 0)) / n
        : null;

    // Pastel macro tile: big gram number + thin energy-share bar.
    Widget tile(String label, double grams, String pctStr, double share,
            Color color) =>
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textMid,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    grams.toStringAsFixed(0),
                    style: tabularFigures.copyWith(
                      color: AppColors.textHi,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'g',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textMid,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                pctStr == '—' ? 'per day' : '$pctStr of energy',
                style: tabularFigures.copyWith(
                  color: AppColors.textLow,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: share.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.6),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        );

    double share(double grams, double perGram) =>
        kcalFromMacros <= 0 ? 0.0 : grams * perGram / kcalFromMacros;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
                child: tile('Protein', p, pct(p, 4), share(p, 4),
                    AppColors.protein)),
            const SizedBox(width: 12),
            Expanded(
                child:
                    tile('Carbs', c, pct(c, 4), share(c, 4), AppColors.carb)),
            const SizedBox(width: 12),
            Expanded(
                child: tile('Fat', f, pct(f, 9), share(f, 9), AppColors.fat)),
          ],
        ),
        if (fibreAvg != null) ...[
          const SizedBox(height: 12),
          tile('Fibre', fibreAvg, '—', 0.0,
              AppColors.protein.withValues(alpha: 0.6)),
        ],
      ],
    );
  }

  Widget _topFoods(TextTheme tt, _ReportData data) {
    if (data.top.isEmpty) {
      return GlassPanel(
        radius: 24,
        child: Text('Nothing logged in this period.',
            style: GoogleFonts.plusJakartaSans(
                color: AppColors.textLow,
                fontSize: 13,
                fontWeight: FontWeight.w500)),
      );
    }

    final items = data.top.toList();
    return GlassPanel(
      radius: 24,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: AppColors.line),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.ember.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text('${i + 1}',
                        style: tabularFigures.copyWith(
                            color: AppColors.ember,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textHi,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('${items[i].count}× logged',
                            style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textLow,
                                fontSize: 12,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${items[i].kcal.toStringAsFixed(0)} kcal',
                          style: tabularFigures.copyWith(
                              color: AppColors.textHi,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('P ${items[i].protein.toStringAsFixed(0)} g',
                          style: tabularFigures.copyWith(
                              color: AppColors.protein,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReportData {
  final List<DailyTotals> totals;
  final List<FoodContribution> top;
  final List<({String date, double raw, double trend})> weightSeries;
  final bool isLbs;
  const _ReportData(this.totals, this.top, this.weightSeries, this.isLbs);
}
