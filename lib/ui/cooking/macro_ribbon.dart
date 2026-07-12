import 'package:flutter/material.dart';

import '../../models/daily.dart';
import '../../models/macros.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../widgets/macro_ring.dart';

/// Horizontal ribbon pinned at the bottom of the cooking screen, showing
/// today's running macro totals. Values animate with [TweenAnimationBuilder].
///
/// Each macro is represented by a tiny [MacroRing] (size 34, stroke 4) with a
/// label below and an optional "value/target" fraction. Tabular figures on all
/// numbers. The ring stroke carries the macro color; the centered value uses
/// ink text for legibility on the light ribbon.
class MacroRibbon extends StatelessWidget {
  final MacroValues consumed;
  final DailyTarget? target;

  /// Extra padding below the rings so the ribbon's content clears an overlaying
  /// floating nav (the surface fills down behind the translucent nav).
  final double bottomInset;

  const MacroRibbon({
    super.key,
    required this.consumed,
    this.target,
    this.bottomInset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.line, width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomInset),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _MiniRingColumn(
            label: 'kcal',
            value: consumed.kcal,
            target: target?.kcal,
            color: AppColors.ember,
            unit: '',
          ),
          _MiniRingColumn(
            label: 'protein',
            value: consumed.protein,
            target: target?.protein,
            color: AppColors.protein,
            unit: 'g',
          ),
          _MiniRingColumn(
            label: 'carbs',
            value: consumed.carb,
            target: target?.carb,
            color: AppColors.carb,
            unit: 'g',
          ),
          _MiniRingColumn(
            label: 'fat',
            value: consumed.fat,
            target: target?.fat,
            color: AppColors.fat,
            unit: 'g',
          ),
        ],
      ),
    );
  }
}

/// A single column: tiny ring, animated value text, and label.
class _MiniRingColumn extends StatelessWidget {
  final String label;
  final double value;
  final double? target;
  final Color color;
  final String unit;

  const _MiniRingColumn({
    required this.label,
    required this.value,
    required this.color,
    required this.unit,
    this.target,
  });

  @override
  Widget build(BuildContext context) {
    final hasTarget = target != null && target! > 0;
    final progress =
        hasTarget ? (value / target!).clamp(0.0, 1.0) : 0.0;

    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, _) {
          final displayValue = animatedValue.toStringAsFixed(0);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MacroRing(
                progress: progress,
                color: color,
                size: 36,
                stroke: 4,
                glow: 0.2,
                center: Text(
                  '$displayValue$unit',
                  style: tabularFigures.copyWith(
                    color: AppColors.textHi,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textLow,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
