import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Full-bleed light app background. Flat dusty canvas with two very faint
/// pastel corner blooms echoing the design references.
class AmbientBackground extends StatelessWidget {
  final Widget child;
  const AmbientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.canvas),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -100,
            child: _blob(AppColors.accent.withValues(alpha: 0.10)),
          ),
          Positioned(
            bottom: -140,
            left: -120,
            child: _blob(AppColors.carb.withValues(alpha: 0.08)),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blob(Color color) => Container(
        width: 360,
        height: 360,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      );
}
