import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/daily.dart';
import '../../state/providers.dart';
import '../../theme/app_colors.dart';

/// Opens a full-height glass calendar and resolves to the day the user picked,
/// or null if they dismissed it. Future days are shown but disabled; days that
/// have logged food are marked with a dot.
Future<DateTime?> showCalendarSheet(
  BuildContext context, {
  required DateTime selected,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.92,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.glassFillHigh,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: AppColors.glassStroke, width: 1),
            ),
            child: _CalendarSheet(selected: selected),
          ),
        ),
      ),
    ),
  );
}

const _kWeekdayInitials = ['', 'M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _kMonthNames = [
  '', 'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _fmt(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

class _CalendarSheet extends ConsumerStatefulWidget {
  const _CalendarSheet({required this.selected});

  final DateTime selected;

  @override
  ConsumerState<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends ConsumerState<_CalendarSheet> {
  static const _monthsBack = 12; // how far the grid scrolls into the past

  final _scroll = ScrollController();
  late final DateTime _today;
  late final DateTime _firstMonth;
  late final List<DateTime> _months; // ascending, current month last
  // Per-day consumed totals (YYYY-MM-DD → kcal/protein), used to draw the
  // adherence ring. Days absent from the map have no logged food.
  Map<String, ({double kcal, double protein})> _dayTotals = {};
  DailyTarget? _target; // default daily target (kcal/protein goals)

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _firstMonth = DateTime(_today.year, _today.month - _monthsBack, 1);
    _months = [
      for (var m = 0; m <= _monthsBack; m++)
        DateTime(_firstMonth.year, _firstMonth.month + m, 1),
    ];
    _loadDays();
    // Current month is last → open scrolled to today.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadDays() async {
    final entries = await ref
        .read(logRepositoryProvider)
        .forDateRange(_fmt(_firstMonth), _fmt(_today));
    final target = await ref.read(targetRepositoryProvider).get(_fmt(_today));
    final totals = <String, ({double kcal, double protein})>{};
    for (final e in entries) {
      final prev = totals[e.date] ?? (kcal: 0.0, protein: 0.0);
      totals[e.date] =
          (kcal: prev.kcal + e.kcal, protein: prev.protein + e.protein);
    }
    if (!mounted) return;
    setState(() {
      _dayTotals = totals;
      _target = target;
    });
  }

  /// Adherence for a day: a calorie hit is within ±10% of the target; a protein
  /// hit is reaching (or exceeding) the protein goal. Both require a target and
  /// some logged food. Returns (hasData, calorieHit, proteinHit).
  (bool, bool, bool) _adherence(DateTime date) {
    final totals = _dayTotals[_fmt(date)];
    final hasData = totals != null && (totals.kcal > 0 || totals.protein > 0);
    if (!hasData) return (false, false, false);
    final t = _target;
    final calHit = t != null &&
        t.kcal > 0 &&
        totals.kcal >= t.kcal * 0.9 &&
        totals.kcal <= t.kcal * 1.1;
    final proHit = t != null && t.protein > 0 && totals.protein >= t.protein;
    return (true, calHit, proHit);
  }

  void _pick(DateTime d) => Navigator.of(context).pop(d);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Jump to a day',
                style: TextStyle(
                  color: AppColors.textHi,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // Legend for the per-day adherence ring.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                _legendDot(AppColors.protein),
                const SizedBox(width: 5),
                const Text('Calories',
                    style: TextStyle(color: AppColors.textMid, fontSize: 12)),
                const SizedBox(width: 16),
                _legendDot(AppColors.ember),
                const SizedBox(width: 5),
                const Text('Protein',
                    style: TextStyle(color: AppColors.textMid, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              itemCount: _months.length,
              itemBuilder: (_, i) => _monthSection(_months[i]),
            ),
          ),
          _goToBar(),
        ],
      ),
    );
  }

  Widget _legendDot(Color c) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );

  // ── Month grid ────────────────────────────────────────────────────────────

  Widget _monthSection(DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = DateTime(month.year, month.month, 1).weekday - 1;

    // Flat list of cells: null = leading blank, else the day-of-month.
    final cells = <int?>[
      for (var i = 0; i < leadingBlanks; i++) null,
      for (var d = 1; d <= daysInMonth; d++) d,
    ];
    // Pad the final week so the trailing row stays 7-wide.
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      rows.add(Row(
        children: [
          for (var j = 0; j < 7; j++)
            Expanded(
              child: cells[i + j] == null
                  ? const SizedBox(height: 52)
                  : _dayCell(DateTime(month.year, month.month, cells[i + j]!)),
            ),
        ],
      ));
    }

    final label = month.year == _today.year
        ? _kMonthNames[month.month]
        : '${_kMonthNames[month.month]} ${month.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMid,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ),
        ...rows,
      ],
    );
  }

  Widget _dayCell(DateTime date) {
    final isFuture = date.isAfter(_today);
    final isToday = date == _today;
    final isSelected = _fmt(date) ==
        _fmt(DateTime(
            widget.selected.year, widget.selected.month, widget.selected.day));
    final (hasData, calHit, proHit) = _adherence(date);

    final Color numberColor = isFuture
        ? AppColors.textLow
        : isSelected
            ? AppColors.ember
            : AppColors.textHi;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isFuture ? null : () => _pick(date),
      child: Container(
        height: 54,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        decoration: BoxDecoration(
          color: isToday ? AppColors.surfaceHigh : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.ember, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _kWeekdayInitials[date.weekday],
              style: TextStyle(
                color: isFuture ? AppColors.textLow : AppColors.textMid,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            // Adherence ring around the day number: top arc = calories (green
            // when within ±10% of target), bottom arc = protein (blue when the
            // goal is reached), faint grey when missed. Drawn only on logged days.
            SizedBox(
              width: 32,
              height: 32,
              child: CustomPaint(
                painter: hasData
                    ? _AdherenceRingPainter(
                        calorieHit: calHit, proteinHit: proHit)
                    : null,
                child: Center(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: numberColor,
                      fontSize: 15,
                      fontWeight: isSelected || isToday
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom "Go to" bar ──────────────────────────────────────────────────

  Widget _goToBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textMid),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text(
            'Go to',
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: false,
              child: Row(
                children: [
                  _jumpPill('Today', _today),
                  const SizedBox(width: 8),
                  _jumpPill(
                      'Yesterday', _today.subtract(const Duration(days: 1))),
                  const SizedBox(width: 8),
                  _jumpPill(
                      '7 Days Ago', _today.subtract(const Duration(days: 7))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _jumpPill(String label, DateTime date) {
    return GestureDetector(
      onTap: () => _pick(date),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textHi,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Splits a circular ring into a top arc (calories) and bottom arc (protein),
/// each drawn in its "hit" color or a faint grey when the target was missed.
class _AdherenceRingPainter extends CustomPainter {
  const _AdherenceRingPainter({
    required this.calorieHit,
    required this.proteinHit,
  });

  final bool calorieHit;
  final bool proteinHit;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.5;
    final rect = Rect.fromLTWH(
        stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);

    Paint arc(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = c;

    // Faint-but-visible grey for a logged day whose target was missed (the
    // hairline `line` colour is too light to read against the white sheet).
    const missed = AppColors.textLow;
    // Top half (west→north→east): calories. Bottom half (east→south→west):
    // protein. Canvas angles are clockwise with y pointing down.
    canvas.drawArc(rect, math.pi, math.pi, false,
        arc(calorieHit ? AppColors.protein : missed));
    canvas.drawArc(rect, 0, math.pi, false,
        arc(proteinHit ? AppColors.ember : missed));
  }

  @override
  bool shouldRepaint(_AdherenceRingPainter old) =>
      old.calorieHit != calorieHit || old.proteinHit != proteinHit;
}
