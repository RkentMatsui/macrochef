import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Labeled animated horizontal fill bar for macro display.
///
/// Animates the fill fraction whenever [value] changes using a 600 ms
/// ease-out-cubic tween. Numeric labels use tabular figures.
class MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double? target;
  final Color color;
  final String unit;

  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.target,
    this.unit = 'g',
  });

  @override
  Widget build(BuildContext context) {
    final fraction = (target != null && target! > 0)
        ? (value / target!).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMid),
            ),
            Text(
              target != null
                  ? '${value.toStringAsFixed(0)} / ${target!.toStringAsFixed(0)} $unit'
                  : '${value.toStringAsFixed(0)} $unit',
              style: Theme.of(context).textTheme.bodySmall?.merge(
                    tabularFigures.copyWith(color: AppColors.textHi),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: fraction),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) {
                return LinearProgressIndicator(
                  value: animated,
                  backgroundColor: AppColors.surfaceHigh,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
