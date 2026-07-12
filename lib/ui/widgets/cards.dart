import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// A bold, solid-color hero card — the signature surface of the redesign.
///
/// Rounded 28px, a [color] fill (deep navy by default), two soft decorative
/// circles bleeding off the corners (echoing the design references), and a
/// colored drop shadow. Use for the one dominant element on a screen.
class HeroCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;

  const HeroCard({
    super.key,
    required this.child,
    this.color = AppColors.ember,
    this.padding = const EdgeInsets.all(28),
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(28);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: color)),
            // Decorative blobs
            Positioned(
              top: -40,
              right: -30,
              child: _blob(110, Colors.white.withValues(alpha: 0.08)),
            ),
            Positioned(
              bottom: -50,
              left: -20,
              child: _blob(120, AppColors.accent.withValues(alpha: 0.20)),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

/// A soft pastel-tinted stat tile: a small label, a big number, and a thin
/// progress bar. Background is [color] at low opacity so a row of tiles reads
/// as distinct soft colors (mint / lavender / peach) like the references.
class StatTile extends StatelessWidget {
  final String label;
  final double value;
  final double? target;
  final String unit;
  final Color color;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.target,
    this.unit = 'g',
  });

  @override
  Widget build(BuildContext context) {
    final hasTarget = target != null && target! > 0;
    final progress = hasTarget ? (value / target!).clamp(0.0, 1.0) : 0.0;

    return Container(
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
            style: TextStyle(
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
                value.toStringAsFixed(0),
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
                unit,
                style: const TextStyle(
                  color: AppColors.textMid,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (hasTarget) ...[
            const SizedBox(height: 4),
            Text(
              '/ ${target!.toStringAsFixed(0)}',
              style: tabularFigures.copyWith(
                color: AppColors.textLow,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
