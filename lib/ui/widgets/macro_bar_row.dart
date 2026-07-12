import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// One macro row: label, consumed/target grams, remaining,
/// and a colour-filled horizontal track with a soft gradient.
class MacroBarRow extends StatelessWidget {
  final String label;
  final double value;
  final double? targetValue;
  final Color color;

  const MacroBarRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.targetValue,
  });

  @override
  Widget build(BuildContext context) {
    final hasTarget = targetValue != null && targetValue! > 0;
    final progress = hasTarget ? (value / targetValue!).clamp(0.0, 1.0) : 0.0;
    final remaining = hasTarget ? (targetValue! - value) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textHi, fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              hasTarget
                  ? '${value.toStringAsFixed(0)} / ${targetValue!.toStringAsFixed(0)} g'
                  : '${value.toStringAsFixed(0)} g',
              style: tabularFigures.copyWith(color: AppColors.textMid, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(height: 10, color: AppColors.surfaceHigh),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, p, _) => FractionallySizedBox(
                  widthFactor: p,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.65), color],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (remaining != null) ...[
          const SizedBox(height: 4),
          Text(
            remaining >= 0
                ? '${remaining.toStringAsFixed(0)} g left'
                : '${(-remaining).toStringAsFixed(0)} g over',
            style: tabularFigures.copyWith(color: AppColors.textLow, fontSize: 11),
          ),
        ],
      ],
    );
  }
}
