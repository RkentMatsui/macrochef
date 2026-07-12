import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../data/database.dart';
import '../../../theme/app_colors.dart';
import 'plate_calculator_sheet.dart';

/// Editable, type-aware row for one logged set. Fields shown are driven by the
/// owning exercise's capability flags. All values are reported back via
/// [onChanged]; weight values carry the per-row unit (`kg`/`lb`) the user typed
/// so the parent can store canonical kg while remembering the entered unit.
class SetRowData {
  int? reps;
  double? weight; // in [unit]
  String unit; // 'kg' | 'lb'
  int? durationSec;
  double? distanceM;
  double? rpe;
  bool isWarmup;
  bool completed;

  SetRowData({
    this.reps,
    this.weight,
    this.unit = 'kg',
    this.durationSec,
    this.distanceM,
    this.rpe,
    this.isWarmup = false,
    this.completed = false,
  });

  SetRowData copy() => SetRowData(
        reps: reps,
        weight: weight,
        unit: unit,
        durationSec: durationSec,
        distanceM: distanceM,
        rpe: rpe,
        isWarmup: isWarmup,
        completed: completed,
      );
}

class SetRow extends StatefulWidget {
  final int setNumber; // 1-based for display
  final Exercise exercise;
  final SetRowData data;
  final ValueChanged<SetRowData> onChanged;
  final VoidCallback onDelete;

  /// Fired when the user toggles the set's done checkmark. The parent uses the
  /// transition to start the rest timer + auto-fill the next set.
  final VoidCallback? onToggleComplete;

  /// The matching set from the last time this exercise was trained, shown as a
  /// "last time" reference under the row. Null when no history.
  final SetEntry? previous;

  const SetRow({
    super.key,
    required this.setNumber,
    required this.exercise,
    required this.data,
    required this.onChanged,
    required this.onDelete,
    this.onToggleComplete,
    this.previous,
  });

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;
  late final TextEditingController _durationCtrl; // minutes
  late final TextEditingController _distanceCtrl; // km
  late final TextEditingController _rpeCtrl;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _weightCtrl =
        TextEditingController(text: d.weight == null ? '' : _fmt(d.weight!));
    _repsCtrl =
        TextEditingController(text: d.reps == null ? '' : '${d.reps}');
    _durationCtrl = TextEditingController(
        text: d.durationSec == null ? '' : _fmt(d.durationSec! / 60));
    _distanceCtrl = TextEditingController(
        text: d.distanceM == null ? '' : _fmt(d.distanceM! / 1000));
    _rpeCtrl = TextEditingController(text: d.rpe == null ? '' : _fmt(d.rpe!));
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toString();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    _durationCtrl.dispose();
    _distanceCtrl.dispose();
    _rpeCtrl.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(widget.data);

  void _bumpWeight(double delta) {
    final cur = double.tryParse(_weightCtrl.text.trim()) ?? 0;
    final next = (cur + delta) < 0 ? 0.0 : cur + delta;
    _weightCtrl.text = _fmt(next);
    widget.data.weight = next;
    _emit();
    setState(() {});
  }

  void _bumpReps(int delta) {
    final cur = int.tryParse(_repsCtrl.text.trim()) ?? 0;
    final next = (cur + delta) < 0 ? 0 : cur + delta;
    _repsCtrl.text = '$next';
    widget.data.reps = next;
    _emit();
    setState(() {});
  }

  /// "Last: 60 kg × 8" reference from the previous session, formatted for the
  /// metrics this exercise tracks. Null when there's no prior set.
  String? _previousLabel() {
    final p = widget.previous;
    if (p == null) return null;
    final e = widget.exercise;
    final parts = <String>[];
    if (e.tracksWeight && p.weightKg != null) {
      final unit = p.enteredUnit ?? 'kg';
      final w = unit == 'lb' ? p.weightKg! / 0.45359237 : p.weightKg!;
      parts.add('${_fmt(w)} $unit');
    }
    if (e.tracksReps && p.reps != null) parts.add('${p.reps} reps');
    if (e.tracksDuration && p.durationSec != null) {
      parts.add('${(p.durationSec! / 60).round()} min');
    }
    if (e.tracksDistance && p.distanceM != null) {
      parts.add('${(p.distanceM! / 1000).toStringAsFixed(1)} km');
    }
    return parts.isEmpty ? null : 'Last: ${parts.join(' × ')}';
  }

  Widget _quickChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(label,
            style: const TextStyle(
                color: AppColors.ember,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    final prevLabel = _previousLabel();
    final wInc = widget.data.unit == 'lb' ? 5.0 : 2.5;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Set number / warmup badge
          GestureDetector(
            onTap: () {
              setState(() => widget.data.isWarmup = !widget.data.isWarmup);
              _emit();
            },
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.data.isWarmup
                    ? AppColors.fat.withValues(alpha: 0.18)
                    : AppColors.ember.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.data.isWarmup ? 'W' : '${widget.setNumber}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: widget.data.isWarmup ? AppColors.fat : AppColors.ember,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          if (e.tracksWeight) ...[
            Expanded(child: _numField(_weightCtrl, 'kg/lb', (s) {
              widget.data.weight = double.tryParse(s.trim());
              _emit();
            })),
            const SizedBox(width: 6),
            _unitToggle(),
            const SizedBox(width: 4),
            _plateButton(),
            const SizedBox(width: 6),
          ],
          if (e.tracksReps) ...[
            Expanded(child: _numField(_repsCtrl, 'reps', (s) {
              widget.data.reps = int.tryParse(s.trim());
              _emit();
            }, decimal: false)),
            const SizedBox(width: 6),
          ],
          if (e.tracksDuration) ...[
            Expanded(child: _numField(_durationCtrl, 'min', (s) {
              final v = double.tryParse(s.trim());
              widget.data.durationSec = v == null ? null : (v * 60).round();
              _emit();
            })),
            const SizedBox(width: 6),
          ],
          if (e.tracksDistance) ...[
            Expanded(child: _numField(_distanceCtrl, 'km', (s) {
              final v = double.tryParse(s.trim());
              widget.data.distanceM = v == null ? null : v * 1000;
              _emit();
            })),
            const SizedBox(width: 6),
          ],
          // RPE (always optional)
          SizedBox(
            width: 56,
            child: _numField(_rpeCtrl, 'RPE', (s) {
              widget.data.rpe = double.tryParse(s.trim());
              _emit();
            }),
          ),
          // Done check — marks the set complete (starts rest + auto-fills next).
          GestureDetector(
            onTap: () {
              setState(() => widget.data.completed = !widget.data.completed);
              _emit();
              widget.onToggleComplete?.call();
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.data.completed
                    ? AppColors.protein.withValues(alpha: 0.18)
                    : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: widget.data.completed
                        ? AppColors.protein
                        : AppColors.line),
              ),
              child: Icon(
                widget.data.completed
                    ? PhosphorIconsFill.check
                    : PhosphorIconsRegular.check,
                size: 18,
                color: widget.data.completed
                    ? AppColors.protein
                    : AppColors.textLow,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(PhosphorIconsRegular.x,
                size: 16, color: AppColors.textLow),
            onPressed: widget.onDelete,
          ),
            ],
          ),
          // Sub-row: "last time" reference + quick +/- steppers so the user
          // can adjust weight/reps without opening the keyboard.
          if (prevLabel != null || e.tracksWeight || e.tracksReps)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: 2, right: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      prevLabel ?? '',
                      style: const TextStyle(
                          color: AppColors.textLow, fontSize: 11),
                    ),
                  ),
                  if (e.tracksWeight) ...[
                    _quickChip('-${_fmt(wInc)}', () => _bumpWeight(-wInc)),
                    _quickChip('+${_fmt(wInc)}', () => _bumpWeight(wInc)),
                  ],
                  if (e.tracksReps) ...[
                    _quickChip('-1', () => _bumpReps(-1)),
                    _quickChip('+1', () => _bumpReps(1)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Opens the barbell plate calculator seeded with the current weight, and
  /// writes the chosen total back into the weight field.
  Future<void> _openPlateCalc() async {
    final current = double.tryParse(_weightCtrl.text.trim());
    final result = await showPlateCalculator(
      context,
      unit: widget.data.unit,
      initialWeight: current,
    );
    if (result == null || !mounted) return;
    setState(() {
      _weightCtrl.text = _fmt(result);
      widget.data.weight = result;
    });
    _emit();
  }

  Widget _plateButton() {
    return GestureDetector(
      onTap: _openPlateCalc,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: const Icon(PhosphorIconsDuotone.barbell,
            size: 18, color: AppColors.ember),
      ),
    );
  }

  Widget _unitToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.data.unit = widget.data.unit == 'kg' ? 'lb' : 'kg';
        });
        _emit();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(
          widget.data.unit,
          style: const TextStyle(
            color: AppColors.ember,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _numField(
    TextEditingController ctrl,
    String hint,
    ValueChanged<String> onChanged, {
    bool decimal = true,
  }) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
            decimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]')),
      ],
      style: const TextStyle(color: AppColors.textHi, fontSize: 15),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textLow, fontSize: 12),
        filled: true,
        fillColor: AppColors.surfaceHigh,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
