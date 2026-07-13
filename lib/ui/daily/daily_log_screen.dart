import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/database.dart';
import '../../models/daily.dart';
import '../../models/macros.dart';
import '../../services/daily_log_service.dart';
import '../../services/date_range.dart';
import '../../services/food_db/usda_client.dart';
import '../../services/food_units.dart';
import '../../services/macro_calculator.dart';
import '../../services/nutrition/food_row.dart';
import '../../services/weight_service.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../reports/reports_screen.dart';
import 'calendar_sheet.dart';
import '../widgets/cards.dart';
import '../widgets/glass_panel.dart';
import '../widgets/macro_ring.dart';
import '../widgets/primary_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

// ---------------------------------------------------------------------------
// DailyLogScreen
// ---------------------------------------------------------------------------

class DailyLogScreen extends ConsumerStatefulWidget {
  /// Whether this tab is currently the visible one. When it transitions from
  /// inactive→active the screen re-queries so targets/entries changed on other
  /// tabs (e.g. Settings, Cook) show immediately.
  final bool isActive;

  const DailyLogScreen({super.key, this.isActive = true});

  @override
  ConsumerState<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends ConsumerState<DailyLogScreen> {
  /// Currently displayed day, as YYYY-MM-DD. Defaults to today; the date
  /// navigator lets the user browse past days (and back to today).
  late String _date;
  late Future<DailyTotals> _totalsFuture;
  late Future<List<LogEntry>> _entriesFuture;
  late Future<WeightEntry?> _weightFuture;
  double? _fibreTarget;
  bool _isLbs = false; // weight display/entry unit (storage is always kg)

  @override
  void initState() {
    super.initState();
    _date = todayDate();
    _load();
    _loadPrefs();
  }

  @override
  void didUpdateWidget(DailyLogScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Became the active tab → refresh so cross-tab changes are reflected
    // (e.g. fibre target or weight unit changed on the Settings tab).
    if (widget.isActive && !oldWidget.isActive) {
      _refresh();
      _loadPrefs();
    }
  }

  Future<void> _loadPrefs() async {
    final raw = await ref.read(settingsRepositoryProvider).get('fibre_target_g');
    final lbs = await ref.read(weightServiceProvider).isLbs;
    if (mounted) {
      setState(() {
        _fibreTarget = double.tryParse(raw ?? '');
        _isLbs = lbs;
      });
    }
  }

  void _load() {
    _totalsFuture = ref.read(dailyLogServiceProvider).totals(_date);
    _entriesFuture = ref.read(logRepositoryProvider).forDate(_date);
    _weightFuture = ref.read(weightServiceProvider).forDate(_date);
  }

  void _refresh() {
    setState(() => _load());
  }

  // ── Date navigation ──────────────────────────────────────────────────────

  DateTime _parseDate(String s) {
    final p = s.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  bool get _isToday => _date == todayDate();

  void _goToDate(DateTime d) {
    final today = _parseDate(todayDate());
    final target = DateTime(d.year, d.month, d.day);
    if (target.isAfter(today)) return; // never browse the future
    setState(() {
      _date = _fmtDate(target);
      _load();
    });
  }

  void _prevDay() =>
      _goToDate(_parseDate(_date).subtract(const Duration(days: 1)));

  /// Re-log every food from the day before the selected day onto it — one tap
  /// to repeat a typical day's meals.
  Future<void> _copyYesterday() async {
    final messenger = ScaffoldMessenger.of(context);
    final from =
        _fmtDate(_parseDate(_date).subtract(const Duration(days: 1)));
    final n = await ref.read(dailyLogServiceProvider).copyDay(from, _date);
    if (!mounted) return;
    _refresh();
    messenger.showSnackBar(SnackBar(
      content: Text(n == 0
          ? 'Nothing logged the day before to copy.'
          : 'Copied $n item${n == 1 ? '' : 's'} from the previous day.'),
    ));
  }

  void _nextDay() => _goToDate(_parseDate(_date).add(const Duration(days: 1)));

  Future<void> _pickDate() async {
    final picked =
        await showCalendarSheet(context, selected: _parseDate(_date));
    if (picked != null) _goToDate(picked);
  }

  /// Relative label for the selected day: TODAY / YESTERDAY / weekday.
  String _relLabel(DateTime d) {
    final today = _parseDate(todayDate());
    final diff = today.difference(DateTime(d.year, d.month, d.day)).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    return _weekdayName(d.weekday).toUpperCase();
  }

  /// Horizontal row of quick-jump chips: TODAY, YESTERDAY, 7 DAYS AGO.
  Widget _quickJumpRow() {
    final today = todayDate();

    Widget chip(String label, int daysBack) {
      final target = nDaysAgo(today, daysBack);
      return _QuickJumpChip(
        label: label,
        selected: _date == target,
        onTap: () => _goToDate(_parseDate(target)),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('TODAY', 0),
          const SizedBox(width: 8),
          chip('YESTERDAY', 1),
          const SizedBox(width: 8),
          chip('7 DAYS AGO', 7),
        ],
      ),
    );
  }

  Future<void> _deleteEntry(int id) async {
    await ref.read(logRepositoryProvider).delete(id);
    _refresh();
  }

  void _openAddSheet() => _openFoodSheet();

  void _openEditSheet(LogEntry entry) => _openFoodSheet(existing: entry);

  void _openFoodSheet({LogEntry? existing}) =>
      showAddFoodSheet(context, date: _date, onAdded: _refresh, existing: existing);

  void _openWeightSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.glassFillHigh,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppColors.glassStroke, width: 1),
            ),
            child: _WeightSheet(
              date: _date,
              isLbs: _isLbs,
              onSaved: _refresh,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _parseDate(_date);
    final weekday = _weekdayName(selected.weekday);
    final monthDay = _monthDayLabel(selected);
    final relLabel = _relLabel(selected);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      // No AppBar — header lives in the scroll view for a dashboard feel
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Page header w/ date navigator ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 28, 12, 0),
                child: Row(
                  children: [
                    _navArrow(PhosphorIconsBold.caretLeft, _prevDay),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          children: [
                            Text(
                              relLabel,
                              style: const TextStyle(
                                color: AppColors.textMid,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$weekday, $monthDay',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textHi,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _navArrow(
                      PhosphorIconsBold.caretRight,
                      _isToday ? null : _nextDay,
                    ),
                    IconButton(
                      tooltip: 'Copy previous day',
                      icon: const Icon(PhosphorIconsDuotone.copy,
                          color: AppColors.ember),
                      onPressed: _copyYesterday,
                    ),
                    IconButton(
                      tooltip: 'Reports',
                      icon: const Icon(PhosphorIconsDuotone.chartBar,
                          color: AppColors.ember),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ReportsScreen()),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.04, end: 0),
            ),

            // ── Quick-jump date chips ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _quickJumpRow(),
              ).animate().fadeIn(duration: 350.ms, delay: 15.ms),
            ),

            // ── Weight card ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: FutureBuilder<WeightEntry?>(
                  future: _weightFuture,
                  builder: (context, snap) {
                    final entry = snap.data;
                    return GlassPanel(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      frosted: false,
                      child: Row(
                        children: [
                          const Icon(
                            PhosphorIconsDuotone.scales,
                            color: AppColors.ember,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry != null
                                  ? '${(_isLbs ? WeightService.kgToLb(entry.kg) : entry.kg).toStringAsFixed(1)} ${_isLbs ? 'lb' : 'kg'}'
                                  : 'Not logged today',
                              style: TextStyle(
                                color: entry != null
                                    ? AppColors.textHi
                                    : AppColors.textLow,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _openWeightSheet,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.ember,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            child: Text(
                              entry != null ? 'Edit' : 'Log weight',
                              style: const TextStyle(
                                color: AppColors.ember,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(duration: 350.ms, delay: 30.ms),
            ),

            // ── Hero calorie ring card ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: FutureBuilder<DailyTotals>(
                  future: _totalsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return const _LoadingCard(height: 260);
                    }

                    final totals = snap.data;
                    final consumed = totals?.consumed ?? MacroValues.zero;
                    final target = totals?.target;
                    final kcalProgress = (target != null && target.kcal > 0)
                        ? (consumed.kcal / target.kcal).clamp(0.0, 1.0)
                        : 0.0;

                    return HeroCard(
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'CALORIES',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          MacroRing(
                            progress: kcalProgress,
                            color: AppColors.accent,
                            size: 196,
                            stroke: 16,
                            glow: 0.4,
                            center: _CalorieCenterWidget(
                              consumed: consumed.kcal,
                              target: target?.kcal,
                              onDark: true,
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 450.ms, delay: 60.ms)
                        .slideY(begin: 0.04, end: 0);
                  },
                ),
              ),
            ),

            // ── Macro rings row ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: FutureBuilder<DailyTotals>(
                  future: _totalsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return const _LoadingCard(height: 120);
                    }

                    final totals = snap.data;
                    final consumed = totals?.consumed ?? MacroValues.zero;
                    final target = totals?.target;

                    final showFibre =
                        consumed.fibre != null || _fibreTarget != null;
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: StatTile(
                                label: 'Protein',
                                value: consumed.protein,
                                target: target?.protein,
                                color: AppColors.protein,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatTile(
                                label: 'Carbs',
                                value: consumed.carb,
                                target: target?.carb,
                                color: AppColors.carb,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatTile(
                                label: 'Fat',
                                value: consumed.fat,
                                target: target?.fat,
                                color: AppColors.fat,
                              ),
                            ),
                          ],
                        ),
                        if (showFibre) ...[
                          const SizedBox(height: 12),
                          StatTile(
                            label: 'Fibre',
                            value: consumed.fibre ?? 0,
                            target: _fibreTarget,
                            color: AppColors.ember,
                          ),
                        ],
                      ],
                    )
                        .animate()
                        .fadeIn(duration: 450.ms, delay: 120.ms)
                        .slideY(begin: 0.04, end: 0);
                  },
                ),
              ),
            ),

            // ── Logged entries header ──────────────────────────────────────
            FutureBuilder<List<LogEntry>>(
              future: _entriesFuture,
              builder: (context, snap) {
                final entries = snap.data ?? [];
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 10),
                    child: Row(
                      children: [
                        Text(
                          'LOGGED',
                          style: const TextStyle(
                            color: AppColors.textMid,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (snap.hasData && entries.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHigh,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${entries.length}',
                              style: tabularFigures.copyWith(
                                color: AppColors.textLow,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 180.ms),
                );
              },
            ),

            // ── Entry list ─────────────────────────────────────────────────
            FutureBuilder<List<LogEntry>>(
              future: _entriesFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                          color: AppColors.ember,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  );
                }
                if (snap.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Failed to load entries.',
                          style: TextStyle(color: AppColors.textMid),
                        ),
                      ),
                    ),
                  );
                }

                final entries = snap.data ?? [];

                if (entries.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, index) {
                        final entry = entries[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _LogEntryRow(
                            entry: entry,
                            index: index,
                            onDelete: () => _deleteEntry(entry.id),
                            onEdit: () => _openEditSheet(entry),
                          ),
                        );
                      },
                      childCount: entries.length,
                    ),
                  ),
                );
              },
            ),

            // ── Add food button ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                child: PrimaryButton(
                  label: 'Add food',
                  icon: PhosphorIconsBold.plus,
                  onPressed: _openAddSheet,
                ).animate(delay: 240.ms).fadeIn(duration: 300.ms),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A circular ‹ / › day-stepper button. [onTap] null = disabled (dimmed).
  Widget _navArrow(IconData icon, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.textMid : AppColors.textLow.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  String _weekdayName(int weekday) {
    const names = [
      '', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
      'Sunday'
    ];
    return names[weekday.clamp(1, 7)];
  }

  String _monthDayLabel(DateTime dt) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month]} ${dt.day}';
  }
}

// ---------------------------------------------------------------------------
// Calorie center widget (inside the hero ring)
// ---------------------------------------------------------------------------

class _CalorieCenterWidget extends StatelessWidget {
  final double consumed;
  final double? target;

  /// When painted on a dark hero surface, switch to light text.
  final bool onDark;

  const _CalorieCenterWidget({
    required this.consumed,
    this.target,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasTarget = target != null && target! > 0;
    final remaining = hasTarget
        ? math.max(0.0, target! - consumed)
        : null;

    final big = onDark ? Colors.white : AppColors.textHi;
    final mid = onDark ? Colors.white70 : AppColors.textMid;
    final low = onDark ? Colors.white60 : AppColors.textLow;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Big number
        Text(
          hasTarget
              ? remaining!.toStringAsFixed(0)
              : consumed.toStringAsFixed(0),
          style: tabularFigures.copyWith(
            color: big,
            fontSize: 46,
            fontWeight: FontWeight.w800,
            height: 1.0,
            letterSpacing: -1.0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          hasTarget ? 'kcal left' : 'kcal',
          style: TextStyle(
            color: mid,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        if (hasTarget) ...[
          const SizedBox(height: 4),
          Text(
            '${consumed.toStringAsFixed(0)} / ${target!.toStringAsFixed(0)}',
            style: tabularFigures.copyWith(
              color: low,
              fontSize: 11,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Loading card placeholder
// ---------------------------------------------------------------------------

class _LoadingCard extends StatelessWidget {
  final double height;
  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.ember,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              PhosphorIconsDuotone.bowlFood,
              size: 52,
              color: AppColors.textLow,
            ),
            const SizedBox(height: 16),
            Text(
              'Nothing logged yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textHi,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap "Add food" below to start tracking your day.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMid,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

// ---------------------------------------------------------------------------
// Log entry row
// ---------------------------------------------------------------------------

class _LogEntryRow extends StatelessWidget {
  final LogEntry entry;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _LogEntryRow({
    required this.entry,
    required this.index,
    required this.onDelete,
    required this.onEdit,
  });

  Color _sourceBadgeColor(String source) {
    switch (source) {
      case 'localDb':
        return AppColors.accent.withValues(alpha: 0.2);
      case 'usda':
        return AppColors.carb.withValues(alpha: 0.2);
      case 'ai':
        return AppColors.protein.withValues(alpha: 0.2);
      case 'manual':
        return AppColors.textMid.withValues(alpha: 0.15);
      default: // off
        return AppColors.emberSoft.withValues(alpha: 0.2);
    }
  }

  Color _sourceBadgeTextColor(String source) {
    switch (source) {
      case 'localDb':
        return AppColors.accent;
      case 'usda':
        return AppColors.carb;
      case 'ai':
        return AppColors.protein;
      case 'manual':
        return AppColors.textMid;
      default: // off
        return AppColors.emberSoft;
    }
  }

  /// Human-facing badge text. Only the pack source needs relabelling — its raw
  /// enum name ('localDb') is camelCase; the rest already read cleanly.
  String _sourceLabel(String source) => source == 'localDb' ? 'local' : source;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final isAi = entry.source == 'ai';

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.fat.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          PhosphorIconsRegular.trash,
          color: AppColors.fat,
          size: 22,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onEdit,
        behavior: HitTestBehavior.opaque,
        child: GlassPanel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        radius: 18,
        frosted: false, // per-row in a SliverList — flat fill avoids scroll jank
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Food name + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.foodName,
                    style: tt.bodyMedium?.copyWith(
                      color: AppColors.textHi,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${entry.grams.toStringAsFixed(0)} g  ·  ${entry.kcal.toStringAsFixed(0)} kcal',
                        style: tt.bodySmall?.merge(
                          tabularFigures.copyWith(color: AppColors.textMid),
                        ),
                      ),
                      if (isAi) ...[
                        const SizedBox(width: 6),
                        Text(
                          '~approx',
                          style: tt.bodySmall?.copyWith(
                            color: AppColors.textLow,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Source badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _sourceBadgeColor(entry.source),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _sourceLabel(entry.source),
                style: tt.labelSmall?.copyWith(
                  color: _sourceBadgeTextColor(entry.source),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.05, end: 0);
  }
}

// ---------------------------------------------------------------------------
// Add Food bottom sheet
// ---------------------------------------------------------------------------

/// Opens the "Add food" bottom sheet for [date] (defaults to today). Shared by
/// the Today screen's add button and the global nav "+" action.
void showAddFoodSheet(
  BuildContext context, {
  String? date,
  VoidCallback? onAdded,
  LogEntry? existing,
}) {
  final d = date ?? todayDate();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.glassFillHigh,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.glassStroke, width: 1),
          ),
          child: _AddFoodSheet(
            onAdded: onAdded ?? () {},
            date: d,
            existing: existing,
          ),
        ),
      ),
    ),
  );
}

class _AddFoodSheet extends ConsumerStatefulWidget {
  final VoidCallback onAdded;

  /// The day this entry belongs to (YYYY-MM-DD) — the currently viewed day.
  final String date;

  /// When non-null the sheet is in edit mode: fields are prefilled and saving
  /// overwrites this entry instead of inserting a new one.
  final LogEntry? existing;

  const _AddFoodSheet({
    required this.onAdded,
    required this.date,
    this.existing,
  });

  @override
  ConsumerState<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends ConsumerState<_AddFoodSheet> {
  final _nameCtrl = TextEditingController();
  final _gramsCtrl = TextEditingController();
  final _kcalCtrl = TextEditingController();
  final _proteinCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  bool _loading = false;

  // 0 = Look up (search+camera), 1 = From recipe, 2 = Enter macros
  int _mode = 0;
  bool get _manual => _mode == 2;
  // Selected household unit for look-up logging (default grams = prior behaviour).
  FoodUnit _unit = kFoodUnits.first;
  // Pre-resolved per-100g from a dropdown selection or photo scan; when set,
  // _submitLookup skips the resolve() waterfall and uses these macros directly.
  FoodMacros? _resolvedMacros;
  // Autocomplete
  Timer? _debounce;
  List<FoodMacros> _cacheHits = [];
  List<FoodRow> _localHits = [];
  List<UsdaCandidate> _usdaCandidates = [];
  bool _autocompleteLoading = false;
  // Monotonic guard: each debounced search bumps this; stale futures that
  // resolve out of order are discarded so the latest query always wins.
  int _searchSeq = 0;
  // True once a search has completed for the current query — lets the dropdown
  // stay open (with a "no matches" + AI fallback) instead of vanishing when
  // USDA/cache return nothing, which read as a broken/hidden search.
  bool _searched = false;
  bool _imageAnalyzing = false;
  // Recipe picker
  List<Recipe> _recipes = [];
  bool _recipesLoading = false;
  bool _recipesLoadFailed = false;
  Recipe? _selectedRecipe;
  RecipeMacros? _recipeMacros;
  bool _recipeMacrosLoading = false;
  double _recipeServings = 1;

  /// When true, saves a per-100g override to the food cache.
  bool _remember = false;

  /// Frequently-logged foods for the one-tap re-log strip (look-up mode only).
  List<FrequentFood> _frequent = [];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      // Editing → full manual edit of the stored values.
      _mode = 2;
      _nameCtrl.text = e.foodName;
      _gramsCtrl.text = e.grams == 0 ? '' : _trimNum(e.grams);
      _kcalCtrl.text = _trimNum(e.kcal);
      _proteinCtrl.text = _trimNum(e.protein);
      _carbCtrl.text = _trimNum(e.carb);
      _fatCtrl.text = _trimNum(e.fat);
    } else {
      _loadFrequent();
    }
  }

  /// Loads the user's frequent foods for the quick-add strip. Non-fatal: on any
  /// error the strip simply stays hidden.
  Future<void> _loadFrequent() async {
    try {
      final list =
          await ref.read(dailyLogServiceProvider).frequentFoods(widget.date);
      if (mounted) setState(() => _frequent = list);
    } catch (_) {/* strip stays hidden */}
  }

  /// One-tap re-log: writes the food's stored portion to the current day and
  /// closes the sheet. Instant — no nutrition re-resolve.
  Future<void> _quickRelog(FrequentFood f) async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await ref.read(dailyLogServiceProvider).relog(widget.date, f);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onAdded();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Logged ${f.name} (${_trimNum(f.grams)} g).',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.textHi,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  /// Drops a trailing ".0" so 100.0 shows as "100" in the editor.
  String _trimNum(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    _gramsCtrl.dispose();
    _kcalCtrl.dispose();
    _proteinCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  Future<void> _submit() {
    if (_isEdit) return _submitEdit();
    if (_mode == 1) return _submitRecipe();
    return _manual ? _submitManual() : _submitLookup();
  }

  /// Removes the entry being edited (edit mode only).
  Future<void> _deleteEntry() async {
    final id = widget.existing?.id;
    if (id == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(logRepositoryProvider).delete(id);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onAdded();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entry removed.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /// Overwrites the existing entry with the hand-edited values.
  Future<void> _submitEdit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a food name.')),
      );
      return;
    }
    final macros = MacroValues(
      kcal: _num(_kcalCtrl),
      protein: _num(_proteinCtrl),
      carb: _num(_carbCtrl),
      fat: _num(_fatCtrl),
    );
    final grams = double.tryParse(_gramsCtrl.text.trim()) ?? 0;

    setState(() => _loading = true);
    try {
      await ref.read(dailyLogServiceProvider).update(
            widget.existing!.id,
            name: name,
            grams: grams,
            macros: macros,
          );
      if (_remember) {
        if (grams > 0) {
          final per100 = PerHundred(
            kcal: macros.kcal * 100 / grams,
            protein: macros.protein * 100 / grams,
            carb: macros.carb * 100 / grams,
            fat: macros.fat * 100 / grams,
          );
          await ref.read(foodCacheRepositoryProvider).upsertOverride(
                FoodMacros(
                    name: name,
                    perHundred: per100,
                    source: MacroSource.manual,
                    isEstimate: false),
              );
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Add a weight (g) to remember per-100g macros.')));
          }
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onAdded();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated $name.', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.textHi,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  /// Logs an entry from hand-entered macro totals — no network, source=manual.
  Future<void> _submitManual() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a food name.')),
      );
      return;
    }
    final macros = MacroValues(
      kcal: _num(_kcalCtrl),
      protein: _num(_proteinCtrl),
      carb: _num(_carbCtrl),
      fat: _num(_fatCtrl),
    );
    if (macros.kcal == 0 &&
        macros.protein == 0 &&
        macros.carb == 0 &&
        macros.fat == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one macro value.')),
      );
      return;
    }
    final grams = double.tryParse(_gramsCtrl.text.trim()) ?? 0;

    setState(() => _loading = true);
    try {
      await ref.read(dailyLogServiceProvider).log(
            widget.date,
            name: name,
            grams: grams,
            macros: macros,
            source: MacroSource.manual,
          );
      if (_remember) {
        if (grams > 0) {
          final per100 = PerHundred(
            kcal: macros.kcal * 100 / grams,
            protein: macros.protein * 100 / grams,
            carb: macros.carb * 100 / grams,
            fat: macros.fat * 100 / grams,
          );
          await ref.read(foodCacheRepositoryProvider).upsertOverride(
            FoodMacros(name: name, perHundred: per100, source: MacroSource.manual, isEstimate: false));
        } else if (mounted) {
          // Remember was on but there's no weight to derive per-100g from —
          // tell the user instead of silently dropping the override.
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Add a weight (g) to remember per-100g macros.')));
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onAdded();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $name.', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.textHi,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _submitLookup() async {
    final name = _nameCtrl.text.trim();
    final qtyText = _gramsCtrl.text.trim();

    if (name.isEmpty || qtyText.isEmpty) return;
    final qty = double.tryParse(qtyText);
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_unit.label == 'g'
                ? 'Enter a valid weight in grams.'
                : 'Enter a valid quantity.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // Resolve the food FIRST so a saved per-piece weight can drive count units.
      FoodMacros? fm = _resolvedMacros;
      if (fm == null || fm.name.toLowerCase() != name.toLowerCase()) {
        final lookup = await ref.read(foodLookupProvider.future);
        fm = await lookup.resolve(name);
      }

      if (!mounted) return;

      if (fm == null) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not find "$name".')),
        );
        return;
      }

      // Resolve the quantity+unit to grams. Fixed-factor units (g/kg/oz)
      // convert arithmetically; count units (piece/serving/slice) prefer this
      // food's SAVED grams-per-piece (e.g. a custom "tortilla = 50 g"); the
      // remaining household measures (cup/tbsp/…) fall back to an AI estimate.
      final double grams;
      if (!_unit.needsEstimate) {
        grams = qty * _unit.gramsPerUnit!;
      } else if (_isPieceUnit(_unit.label) && fm.gramsPerPiece != null) {
        grams = qty * fm.gramsPerPiece!;
      } else {
        final lookup = await ref.read(foodLookupProvider.future);
        final perUnit = await lookup.estimateUnitWeight(name, _unit.label);
        if (!mounted) return;
        if (perUnit == null) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Couldn\'t estimate the weight of a ${_unit.label} of "$name". Try entering grams.')),
          );
          return;
        }
        grams = qty * perUnit;
      }

      final macros = MacroCalculator.forGrams(fm.perHundred, grams);
      await ref.read(dailyLogServiceProvider).log(
            widget.date,
            name: fm.name,
            grams: grams,
            macros: macros,
            source: fm.source,
          );
      // Remember this food's unit + quantity so it defaults next time.
      await ref.read(settingsRepositoryProvider).set(
          'foodunit:${fm.name.toLowerCase()}',
          '${_unit.label}|${_trimNum(qty)}');

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onAdded();
      // When a household unit was used, show the resolved grams so the user
      // can sanity-check the AI's portion estimate.
      final portion = _unit.label == 'g'
          ? ''
          : ' · ${_trimNum(qty)} ${_unit.label} ≈ ${grams.toStringAsFixed(0)} g';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${fm.name}.$portion',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.textHi,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      final msg = e.toString().contains('API key') ||
              e.toString().contains('apiKey') ||
              e.toString().contains('401')
          ? 'No API key — set one in Settings.'
          : 'Error: ${e.toString()}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  /// Non-mass units (piece/serving/slice/cup/tbsp/tsp/ml) whose weight is one
  /// serving of the food. When the food carries a saved
  /// [FoodMacros.gramsPerPiece] — e.g. a custom food defined "per cup" — that
  /// serving weight applies directly instead of an AI estimate.
  static bool _isPieceUnit(String label) {
    final u = label.trim().toLowerCase();
    return u == 'piece' ||
        u == 'serving' ||
        u == 'slice' ||
        u == 'cup' ||
        u == 'tbsp' ||
        u == 'tsp' ||
        u == 'ml';
  }

  void _onNameChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() { _cacheHits = []; _localHits = []; _usdaCandidates = []; _searched = false; });
      return;
    }
    final seq = ++_searchSeq;
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _autocompleteLoading = true);
      final cache = ref.read(foodCacheRepositoryProvider);
      final lookup = await ref.read(foodLookupProvider.future);
      final cacheResults = await cache.search(value.trim());
      final usdaResults = await lookup.usda.searchCandidates(value.trim());
      // Local nutrition pack, when enabled + downloaded. Uses the fast lexical
      // FTS prefilter only (no per-keystroke ONNX embedding) so typeahead stays
      // snappy; the semantic re-rank is reserved for resolve()-time direct hits.
      final retriever = await ref.read(nutritionRetrieverProvider.future);
      final localResults = retriever == null
          ? const <FoodRow>[]
          : retriever.db.ftsPrefilter(value.trim(), limit: 8);
      // A newer keystroke superseded this search while it was in flight —
      // drop the stale results so they can't overwrite the latest query.
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _cacheHits = cacheResults;
        _localHits = localResults;
        _usdaCandidates = usdaResults;
        _autocompleteLoading = false;
        _searched = true;
      });
    });
  }

  void _selectCacheFood(FoodMacros fm) {
    _nameCtrl.text = fm.name;
    setState(() { _resolvedMacros = fm; _cacheHits = []; _localHits = []; _usdaCandidates = []; _searched = false; });
    _applyRememberedPortion(fm);
  }

  /// Default the unit (and quantity) to how this food was last logged, so a
  /// food you always take "by the piece" or "30 g" doesn't reset to grams. Falls
  /// back to 'piece' for a food that only carries a per-piece weight.
  Future<void> _applyRememberedPortion(FoodMacros fm) async {
    final saved = await ref
        .read(settingsRepositoryProvider)
        .get('foodunit:${fm.name.toLowerCase()}');
    if (!mounted) return;
    String? label;
    String? qty;
    if (saved != null && saved.isNotEmpty) {
      final parts = saved.split('|');
      label = parts[0];
      if (parts.length > 1 && parts[1].isNotEmpty) qty = parts[1];
    }
    // Fall back to 'piece' for a food that only carries a per-piece weight.
    label ??= fm.gramsPerPiece != null ? 'piece' : null;
    if (label == null) return;
    final matches = kFoodUnits.where((u) => u.label == label);
    if (matches.isEmpty) return;
    final unit = matches.first;
    setState(() {
      _unit = unit;
      if (qty != null && _gramsCtrl.text.trim().isEmpty) _gramsCtrl.text = qty;
    });
  }

  void _selectUsdaCandidate(UsdaCandidate c) {
    _nameCtrl.text = c.description;
    setState(() {
      _resolvedMacros = FoodMacros(name: c.description, perHundred: c.perHundred, source: MacroSource.usda, isEstimate: false);
      _cacheHits = [];
      _localHits = [];
      _usdaCandidates = [];
      _searched = false;
    });
  }

  void _selectLocalFood(FoodRow row) {
    _nameCtrl.text = row.name;
    setState(() {
      _resolvedMacros = FoodMacros(name: row.name, perHundred: row.per, source: MacroSource.localDb, isEstimate: false);
      _cacheHits = [];
      _localHits = [];
      _usdaCandidates = [];
      _searched = false;
    });
  }

  Future<void> _captureImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (file == null) return;
    final Uint8List bytes = await file.readAsBytes();
    setState(() => _imageAnalyzing = true);
    try {
      final lookup = await ref.read(foodLookupProvider.future);
      final fm = await lookup.resolveFromImage(bytes);
      if (!mounted) return;
      if (fm == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not read nutrition — try a clearer photo, or switch to Claude/Gemini in Settings.')));
      } else {
        _nameCtrl.text = fm.name;
        setState(() => _resolvedMacros = fm);
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo analysis failed.')));
    } finally {
      if (mounted) setState(() => _imageAnalyzing = false);
    }
  }

  /// Full one-tap re-log list for the Frequent tab. Each row re-logs the food's
  /// last-used portion instantly; the trailing pencil prefills the form to tweak
  /// the amount before logging.
  Widget _frequentList(TextTheme tt) {
    if (_frequent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            const Icon(PhosphorIconsDuotone.clockCounterClockwise,
                size: 40, color: AppColors.textLow),
            const SizedBox(height: 12),
            Text('No frequent foods yet',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMid)),
            const SizedBox(height: 4),
            Text('Foods you log often show up here for one-tap re-logging.',
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: AppColors.textLow)),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 2),
          child: Text('Tap to log the same portion again',
              style: tt.bodySmall?.copyWith(color: AppColors.textLow)),
        ),
        for (final f in _frequent)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _loading ? null : () => _quickRelog(f),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsFill.plusCircle,
                          size: 22, color: AppColors.ember),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textHi)),
                            const SizedBox(height: 2),
                            Text(
                                '${_trimNum(f.grams)} g · '
                                '${f.macros.kcal.round()} kcal · '
                                '${f.macros.protein.round()}g P',
                                style: tabularFigures.copyWith(
                                    color: AppColors.textMid, fontSize: 12)),
                          ],
                        ),
                      ),
                      // Tweak-before-logging affordance.
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(PhosphorIconsRegular.pencilSimple,
                            size: 18, color: AppColors.textLow),
                        tooltip: 'Adjust amount',
                        onPressed: _loading ? null : () => _prefillFromFrequent(f),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Long-press path: drop the frequent food's values into the manual form so
  /// the user can adjust the portion before logging.
  void _prefillFromFrequent(FrequentFood f) {
    setState(() {
      _mode = 2;
      _nameCtrl.text = f.name;
      _gramsCtrl.text = f.grams == 0 ? '' : _trimNum(f.grams);
      _kcalCtrl.text = _trimNum(f.macros.kcal);
      _proteinCtrl.text = _trimNum(f.macros.protein);
      _carbCtrl.text = _trimNum(f.macros.carb);
      _fatCtrl.text = _trimNum(f.macros.fat);
    });
  }

  /// Compact unit selector shown beside the quantity field in look-up mode.
  Widget _unitDropdown(TextTheme tt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FoodUnit>(
          value: _unit,
          isDense: true,
          dropdownColor: AppColors.surface,
          iconEnabledColor: AppColors.ember,
          borderRadius: BorderRadius.circular(12),
          style: tt.bodyMedium?.copyWith(color: AppColors.textHi),
          items: kFoodUnits
              .map((u) => DropdownMenuItem(value: u, child: Text(u.label)))
              .toList(),
          onChanged: _loading
              ? null
              : (u) {
                  if (u != null) setState(() => _unit = u);
                },
        ),
      ),
    );
  }

  Future<void> _loadRecipes() async {
    if (_recipes.isNotEmpty) return;
    setState(() { _recipesLoading = true; _recipesLoadFailed = false; });
    try {
      final r = await ref.read(recipeRepositoryProvider).all();
      if (mounted) setState(() { _recipes = r; _recipesLoading = false; });
    } catch (_) {
      // Surface the failure so the recipe tab can offer a retry instead of
      // leaving the user staring at a tab that silently loaded nothing.
      if (mounted) setState(() { _recipesLoading = false; _recipesLoadFailed = true; });
    }
  }

  Future<void> _selectRecipe(Recipe r) async {
    setState(() { _selectedRecipe = r; _recipeMacrosLoading = true; _recipeServings = 1; });
    try {
      final svc = await ref.read(recipeNutritionServiceProvider.future);
      final m = await svc.nutritionFor(r.id);
      if (mounted) setState(() { _recipeMacros = m; _recipeMacrosLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _recipeMacrosLoading = false);
    }
  }

  Future<void> _submitRecipe() async {
    final r = _selectedRecipe;
    final m = _recipeMacros;
    if (r == null || m == null) return;
    setState(() => _loading = true);
    try {
      final svc = await ref.read(recipeNutritionServiceProvider.future);
      await svc.logMealServings(recipeId: r.id, recipeTitle: r.title, recipeMacros: m, servingsEaten: _recipeServings, date: widget.date);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onAdded();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Logged ${r.title}.', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.textHi,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      // Lift the sheet above the keyboard; the inner scroll view absorbs any
      // remaining overflow so the Column never overflows by a few pixels.
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            _isEdit ? 'Edit food' : 'Log food',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textHi,
            ),
          ),
          const SizedBox(height: 16),

          // Mode toggle: 3 tabs (hidden when editing — always full manual edit).
          if (!_isEdit) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                // Frequent is the fast re-log path — shown first, only once the
                // user has logged enough foods to populate it.
                if (_frequent.isNotEmpty)
                  _modeTab('Frequent', _mode == 3, () {
                    if (_loading) return;
                    setState(() { _mode = 3; _selectedRecipe = null; _recipeMacros = null; });
                  }),
                _modeTab('Look up', _mode == 0, () {
                  if (_loading) return;
                  setState(() { _mode = 0; _selectedRecipe = null; _recipeMacros = null; });
                }),
                _modeTab('Recipe', _mode == 1, () {
                  if (_loading) return;
                  setState(() => _mode = 1);
                  _loadRecipes();
                }),
                _modeTab('Macros', _mode == 2, () {
                  if (_loading) return;
                  setState(() { _mode = 2; _resolvedMacros = null; });
                }),
              ]),
            ),
            const SizedBox(height: 16),
          ],

          // Frequent tab: full one-tap re-log list.
          if (_mode == 3 && !_isEdit) ...[
            _frequentList(tt),
          ],

          // Food name + grams + manual macros (hidden in recipe + frequent tabs)
          if (_mode != 1 && _mode != 3) ...[
            TextField(
              controller: _nameCtrl,
              style: tt.bodyMedium?.copyWith(color: AppColors.textHi),
              decoration: InputDecoration(
                hintText: 'Food name (e.g. chicken breast)',
                hintStyle: tt.bodyMedium?.copyWith(color: AppColors.textLow),
                filled: true,
                fillColor: AppColors.surfaceHigh,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _mode == 0
                    ? (_imageAnalyzing
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ember)))
                        : IconButton(
                            icon: const Icon(PhosphorIconsBold.camera, color: AppColors.ember),
                            tooltip: 'Scan nutrition label or food photo',
                            onPressed: _loading ? null : _captureImage))
                    : null,
              ),
              onChanged: _mode == 0 ? _onNameChanged : null,
              textInputAction: TextInputAction.next,
              enabled: !_loading,
            ),

            // Inline autocomplete dropdown (look-up mode only). Stays open once a
            // search has run — even with zero matches — so the user always sees
            // a result state and the "Let AI decide" fallback.
            if (_mode == 0 && (_autocompleteLoading || _searched)) ...[
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: _autocompleteLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(children: [
                          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ember)),
                          SizedBox(width: 10),
                          Text('Searching…', style: TextStyle(color: AppColors.textMid, fontSize: 13)),
                        ]))
                    : ListView(shrinkWrap: true, padding: EdgeInsets.zero, children: [
                        if (_cacheHits.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                            child: Text('My foods', style: TextStyle(color: AppColors.textMid, fontSize: 11, fontWeight: FontWeight.w600))),
                          ..._cacheHits.map((fm) => ListTile(
                            dense: true,
                            title: Text(fm.name, style: const TextStyle(color: AppColors.textHi, fontSize: 13)),
                            subtitle: Text('${fm.perHundred.kcal.toStringAsFixed(0)} kcal/100g · ${fm.source.name}',
                                style: const TextStyle(color: AppColors.textMid, fontSize: 11)),
                            onTap: () => _selectCacheFood(fm))),
                        ],
                        if (_localHits.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                            child: Text('Local', style: TextStyle(color: AppColors.textMid, fontSize: 11, fontWeight: FontWeight.w600))),
                          ..._localHits.map((row) => ListTile(
                            dense: true,
                            title: Text(row.name, style: const TextStyle(color: AppColors.textHi, fontSize: 13)),
                            subtitle: Text('${row.per.kcal.toStringAsFixed(0)} kcal/100g',
                                style: const TextStyle(color: AppColors.textMid, fontSize: 11)),
                            onTap: () => _selectLocalFood(row))),
                        ],
                        if (_usdaCandidates.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
                            child: Text('USDA', style: TextStyle(color: AppColors.textMid, fontSize: 11, fontWeight: FontWeight.w600))),
                          ..._usdaCandidates.map((c) => ListTile(
                            dense: true,
                            title: Text(c.description, style: const TextStyle(color: AppColors.textHi, fontSize: 13)),
                            subtitle: Text('${c.perHundred.kcal.toStringAsFixed(0)} kcal/100g',
                                style: const TextStyle(color: AppColors.textMid, fontSize: 11)),
                            onTap: () => _selectUsdaCandidate(c))),
                        ],
                        if (_cacheHits.isEmpty && _localHits.isEmpty && _usdaCandidates.isEmpty)
                          const Padding(
                            padding: EdgeInsets.fromLTRB(12, 10, 12, 2),
                            child: Text('No matches in your foods, local pack, or USDA',
                                style: TextStyle(color: AppColors.textMid, fontSize: 12))),
                        ListTile(
                          dense: true,
                          leading: const Icon(PhosphorIconsRegular.sparkle, color: AppColors.ember, size: 18),
                          title: Text('Let AI decide for "${_nameCtrl.text.trim()}"',
                              style: const TextStyle(color: AppColors.ember, fontSize: 13, fontWeight: FontWeight.w600)),
                          onTap: () => setState(() { _resolvedMacros = null; _cacheHits = []; _localHits = []; _usdaCandidates = []; _searched = false; })),
                      ]),
              ),
            ],

            const SizedBox(height: 12),

            // Quantity + unit (look-up mode) — grams stays the default, so
            // behaviour is unchanged unless a household unit is picked.
            if (_mode == 0)
              Row(
                // NB: never CrossAxisAlignment.stretch here — this Row lives in
                // a vertically-unbounded SingleChildScrollView, and stretch
                // forces children to infinite height (collapses the sheet).
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gramsCtrl,
                      style: tt.bodyMedium?.merge(
                          tabularFigures.copyWith(color: AppColors.textHi)),
                      decoration: InputDecoration(
                        hintText:
                            _unit.label == 'g' ? 'Weight (g)' : 'Quantity',
                        hintStyle:
                            tt.bodyMedium?.copyWith(color: AppColors.textLow),
                        filled: true,
                        fillColor: AppColors.surfaceHigh,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      enabled: !_loading,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _unitDropdown(tt),
                ],
              )
            else
              // Manual ("Enter macros") mode — plain optional weight in grams.
              TextField(
                controller: _gramsCtrl,
                style: tt.bodyMedium
                    ?.merge(tabularFigures.copyWith(color: AppColors.textHi)),
                decoration: InputDecoration(
                  hintText: 'Weight (g) · optional',
                  hintStyle: tt.bodyMedium?.copyWith(color: AppColors.textLow),
                  filled: true,
                  fillColor: AppColors.surfaceHigh,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                textInputAction: TextInputAction.next,
                enabled: !_loading,
              ),

            // Manual macro inputs (only when "Enter macros" is selected).
            if (_manual) ...[
              const SizedBox(height: 12),
              _macroField(_kcalCtrl, 'Calories', AppColors.ember),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _macroField(_proteinCtrl, 'Protein (g)',
                        AppColors.protein),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _macroField(_carbCtrl, 'Carbs (g)', AppColors.carb),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _macroField(_fatCtrl, 'Fat (g)', AppColors.fat),
                  ),
                ],
              ),
              // Remember toggle visible whenever entering macros (not just edit).
              // (Already inside the outer `if (_manual)` — no second guard needed.)
              const SizedBox(height: 8),
              SwitchListTile(
                value: _remember,
                onChanged: _loading ? null : (v) => setState(() => _remember = v),
                activeColor: AppColors.ember,
                contentPadding: EdgeInsets.zero,
                title: Text('Remember these macros for "${_nameCtrl.text.trim()}"',
                    style: const TextStyle(color: AppColors.textHi, fontSize: 13)),
                subtitle: const Text('Saves per-100g so future lookups use your values',
                    style: TextStyle(color: AppColors.textMid, fontSize: 11)),
              ),
            ],
          ],

          // Recipe tab body
          if (_mode == 1) ...[
            if (_recipesLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.ember))
            else if (_recipesLoadFailed)
              Row(children: [
                const Expanded(
                  child: Text("Couldn't load recipes.",
                      style: TextStyle(color: AppColors.textMid))),
                TextButton(onPressed: _loadRecipes, child: const Text('Retry')),
              ])
            else if (_recipes.isEmpty)
              const Text('No recipes saved.', style: TextStyle(color: AppColors.textMid))
            else if (_selectedRecipe == null)
              SizedBox(
                height: 220,
                child: ListView.builder(
                  itemCount: _recipes.length,
                  itemBuilder: (_, i) {
                    final r = _recipes[i];
                    return ListTile(
                      dense: true,
                      title: Text(r.title, style: const TextStyle(color: AppColors.textHi, fontSize: 14)),
                      trailing: const Icon(PhosphorIconsRegular.caretRight, size: 16, color: AppColors.textMid),
                      onTap: () => _selectRecipe(r));
                  }),
              )
            else ...[
              Row(children: [
                Expanded(child: Text(_selectedRecipe!.title,
                    style: const TextStyle(color: AppColors.textHi, fontWeight: FontWeight.w600))),
                TextButton(
                  onPressed: () => setState(() { _selectedRecipe = null; _recipeMacros = null; }),
                  child: const Text('Change')),
              ]),
              if (_recipeMacrosLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator(color: AppColors.ember)))
              else if (_recipeMacros == null)
                const Text('No nutrition data for this recipe.', style: TextStyle(color: AppColors.textMid))
              else ...[
                const SizedBox(height: 8),
                Text('${_recipeMacros!.perServing.kcal.toStringAsFixed(0)} kcal per serving',
                    style: const TextStyle(color: AppColors.textMid, fontSize: 12)),
                const SizedBox(height: 8),
                Row(children: [
                  const Text('Servings:', style: TextStyle(color: AppColors.textHi)),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _recipeServings > 0.5
                        ? () => setState(() => _recipeServings = (_recipeServings - 0.5).clamp(0.5, 99))
                        : null,
                    icon: const Icon(PhosphorIconsBold.minus, size: 18)),
                  Text(
                    _recipeServings % 1 == 0
                        ? _recipeServings.toInt().toString()
                        : _recipeServings.toStringAsFixed(1),
                    style: const TextStyle(color: AppColors.textHi, fontWeight: FontWeight.w600)),
                  IconButton(
                    onPressed: () => setState(() => _recipeServings = (_recipeServings + 0.5).clamp(0.5, 99)),
                    icon: const Icon(PhosphorIconsBold.plus, size: 18)),
                ]),
              ],
            ],
            const SizedBox(height: 8),
          ],

          // Frequent tab logs on row-tap, so it needs no submit button.
          if (_mode != 3) ...[
            const SizedBox(height: 24),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.ember),
              )
            else
              PrimaryButton(
                label: _isEdit ? 'Save' : (_mode == 1 ? 'Log recipe' : 'Add'),
                icon: PhosphorIconsBold.check,
                onPressed: (_mode == 1 && (_selectedRecipe == null || _recipeMacros == null)) ? null : _submit,
              ),
          ],

          // Delete (edit mode only)
          if (_isEdit && !_loading) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _deleteEntry,
              icon: const Icon(PhosphorIconsRegular.trash,
                  color: AppColors.danger, size: 18),
              label: const Text('Delete entry',
                  style: TextStyle(color: AppColors.danger)),
            ),
          ],
          ],
        ),
      ),
    );
  }

  /// One pill in the Look-up / Enter-macros segmented toggle.
  Widget _modeTab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.ember : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.canvas : AppColors.textMid,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// A labelled numeric field for one macro, with a colour-coded label.
  Widget _macroField(
      TextEditingController controller, String label, Color accent) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 5),
          child: Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        TextField(
          controller: controller,
          style: tt.bodyMedium
              ?.merge(tabularFigures.copyWith(color: AppColors.textHi)),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: tt.bodyMedium?.copyWith(color: AppColors.textLow),
            filled: true,
            fillColor: AppColors.surfaceHigh,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          textInputAction: TextInputAction.next,
          enabled: !_loading,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Weight bottom sheet
// ---------------------------------------------------------------------------

class _WeightSheet extends ConsumerStatefulWidget {
  final String date;
  final bool isLbs;
  final VoidCallback onSaved;

  const _WeightSheet({
    required this.date,
    required this.isLbs,
    required this.onSaved,
  });

  @override
  ConsumerState<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends ConsumerState<_WeightSheet> {
  final _kgCtrl = TextEditingController();
  bool _loading = false;

  String get _unit => widget.isLbs ? 'lb' : 'kg';
  // Display-unit upper bound (≈500 kg) so the validation message matches the
  // unit the user is actually typing in.
  double get _maxInUnit => widget.isLbs ? 1100 : 500;

  @override
  void dispose() {
    _kgCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _kgCtrl.text.trim();
    final entered = double.tryParse(text);
    if (entered == null || entered <= 0 || entered > _maxInUnit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter a valid weight (0–${_maxInUnit.toStringAsFixed(0)} $_unit).'),
        ),
      );
      return;
    }
    // Storage is always kg — convert from the entered display unit.
    final kg = widget.isLbs ? WeightService.lbToKg(entered) : entered;
    setState(() => _loading = true);
    try {
      await ref.read(weightServiceProvider).logWeight(widget.date, kg);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Log weight',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textHi,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _kgCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: tt.bodyMedium
                  ?.merge(tabularFigures.copyWith(color: AppColors.textHi)),
              decoration: InputDecoration(
                hintText: 'Weight in $_unit (e.g. ${widget.isLbs ? '166' : '75.4'})',
                hintStyle: tt.bodyMedium?.copyWith(color: AppColors.textLow),
                suffixText: _unit,
                suffixStyle: const TextStyle(
                  color: AppColors.ember,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: AppColors.surfaceHigh,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              enabled: !_loading,
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.ember),
              )
            else
              PrimaryButton(
                label: 'Save weight',
                icon: PhosphorIconsBold.check,
                onPressed: _save,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick-jump date chip
// ---------------------------------------------------------------------------

class _QuickJumpChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickJumpChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.ember : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? null
              : Border.all(color: AppColors.line, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.canvas : AppColors.textMid,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
