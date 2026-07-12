import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../services/plate_calculator.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Boostcamp-style barbell plate calculator. Build a weight by tapping plates
/// (per side), or type a target and tap "Fill" to auto-load the closest match;
/// the live total can be sent back to the set's weight field.
///
/// Returns the chosen total (in [unit]) via `Navigator.pop`, or null if
/// dismissed. [initialWeight] pre-loads the bar to that weight.
Future<double?> showPlateCalculator(
  BuildContext context, {
  required String unit,
  double? initialWeight,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _PlateCalculatorSheet(unit: unit, initialWeight: initialWeight),
  );
}

class _PlateCalculatorSheet extends StatefulWidget {
  final String unit;
  final double? initialWeight;
  const _PlateCalculatorSheet({required this.unit, this.initialWeight});

  @override
  State<_PlateCalculatorSheet> createState() => _PlateCalculatorSheetState();
}

class _PlateCalculatorSheetState extends State<_PlateCalculatorSheet> {
  late double _bar;
  final Map<double, int> _counts = {}; // plate weight → count per side
  final _targetCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bar = PlateCalculator.defaultBar(widget.unit);
    final w = widget.initialWeight;
    if (w != null && w > 0) {
      _targetCtrl.text = _fmt(w);
      _fillFromTarget(w);
    }
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  double get _total =>
      PlateCalculator.totalForCounts(bar: _bar, counts: _counts);

  double get _perSide => (_total - _bar) / 2;

  void _fillFromTarget(double target) {
    final l =
        PlateCalculator.solve(target: target, bar: _bar, unit: widget.unit);
    setState(() {
      _counts
        ..clear()
        ..addEntries(l.perSide.map((p) => MapEntry(p.weight, p.count)));
    });
  }

  void _addPlate(double w) {
    HapticFeedback.selectionClick();
    setState(() => _counts[w] = (_counts[w] ?? 0) + 1);
  }

  void _removePlate(double w) {
    setState(() {
      final n = (_counts[w] ?? 0) - 1;
      if (n <= 0) {
        _counts.remove(w);
      } else {
        _counts[w] = n;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final plates = PlateCalculator.platesFor(widget.unit);
    final bars = PlateCalculator.barsFor(widget.unit);
    // Loaded plates, heaviest first, for the per-side display.
    final loaded = _counts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Row(
              children: [
                const Icon(PhosphorIconsDuotone.barbell,
                    color: AppColors.ember, size: 24),
                const SizedBox(width: 8),
                Text('Plate calculator',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHi)),
              ],
            ),
            const SizedBox(height: 18),

            // ---- Total + per-side summary ----
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('${_fmt(_total)} ${widget.unit}',
                      style: tabularFigures.copyWith(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHi)),
                  const SizedBox(height: 2),
                  Text(
                      _perSide <= 0
                          ? 'Empty bar'
                          : '${_fmt(_perSide)} ${widget.unit} per side',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMid)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---- Per-side plate visualization ----
            Text('Each side',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMid)),
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: loaded.isEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Just the bar — tap plates below to load it.',
                          style:
                              tt.bodySmall?.copyWith(color: AppColors.textLow)),
                    )
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final e in loaded)
                          for (var i = 0; i < e.value; i++)
                            _plateChip(e.key, () => _removePlate(e.key)),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // ---- Add plates (per side) ----
            Text('Add per side',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMid)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in plates)
                  ActionChip(
                    label: Text('+${_fmt(p)}'),
                    labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHi),
                    backgroundColor: AppColors.surfaceHigh,
                    side: const BorderSide(color: AppColors.line),
                    onPressed: () => _addPlate(p),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // ---- Bar + target controls ----
            Row(
              children: [
                Text('Bar',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMid)),
                const SizedBox(width: 12),
                for (final b in bars) ...[
                  _barChip(b),
                  const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _targetCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    style: const TextStyle(color: AppColors.textHi),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Target ${widget.unit}',
                      hintStyle:
                          const TextStyle(color: AppColors.textLow, fontSize: 13),
                      filled: true,
                      fillColor: AppColors.surfaceHigh,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (s) {
                      final v = double.tryParse(s.trim());
                      if (v != null) _fillFromTarget(v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.surfaceHigh,
                    foregroundColor: AppColors.ember,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onPressed: () {
                    final v = double.tryParse(_targetCtrl.text.trim());
                    if (v != null) _fillFromTarget(v);
                  },
                  child: const Text('Fill'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ember,
                foregroundColor: AppColors.canvas,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: const Icon(PhosphorIconsBold.check, size: 18),
              label: Text('Use ${_fmt(_total)} ${widget.unit}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              onPressed: () => Navigator.of(context).pop(_total),
            ),
          ],
        ),
      ),
    );
  }

  Widget _plateChip(double weight, VoidCallback onRemove) {
    // Bigger plates read taller, like real plates.
    final h = (30 + weight * 1.3).clamp(34.0, 60.0).toDouble();
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onRemove,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30,
              height: h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.ember.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.ember, width: 1.4),
              ),
              child: Text(_fmt(weight),
                  style: tabularFigures.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ember)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barChip(double b) {
    final selected = _bar == b;
    return GestureDetector(
      onTap: () {
        setState(() => _bar = b);
        // Re-fit plates to the typed target against the new bar, if any.
        final v = double.tryParse(_targetCtrl.text.trim());
        if (v != null) _fillFromTarget(v);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.ember : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.ember : AppColors.line),
        ),
        child: Text(b == 0 ? 'None' : _fmt(b),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.canvas : AppColors.textMid)),
      ),
    );
  }
}
