import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A circular progress ring — the hero element of the Lumen design system.
///
/// Draws an animated arc that sweeps clockwise from the top of the circle.
/// A full track ring is drawn first in [AppColors.line] (or [color] at ~12%
/// alpha), then the progress arc in [color] with [StrokeCap.round].
/// A subtle radial glow is applied behind the progress arc.
///
/// [progress] is clamped to 0..1 and animates smoothly when it changes
/// (700 ms, [Curves.easeOutCubic]).
class MacroRing extends StatelessWidget {
  final double progress;
  final Color color;
  final double size;
  final double stroke;
  final Widget? center;
  final double glow;

  const MacroRing({
    super.key,
    required this.progress,
    required this.color,
    this.size = 120,
    this.stroke = 10,
    this.center,
    this.glow = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: clamped),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, animatedProgress, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow layer (only when progress > 0)
              if (glow > 0 && animatedProgress > 0.01)
                CustomPaint(
                  size: Size(size, size),
                  painter: _RingGlowPainter(
                    progress: animatedProgress,
                    color: color,
                    stroke: stroke,
                    glowIntensity: glow,
                  ),
                ),
              // Ring layer
              CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  progress: animatedProgress,
                  color: color,
                  stroke: stroke,
                ),
              ),
              // Center content
              if (center != null)
                Padding(
                  padding: EdgeInsets.all(stroke + 4),
                  child: center,
                ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Ring painter
// ---------------------------------------------------------------------------

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double stroke;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track ring (full circle)
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Progress arc — starts at top (-90°), sweeps clockwise
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2, // start at top
      2 * math.pi * progress, // sweep clockwise
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.stroke != stroke;
}

// ---------------------------------------------------------------------------
// Glow painter — soft radial blur behind the arc
// ---------------------------------------------------------------------------

class _RingGlowPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double stroke;
  final double glowIntensity;

  const _RingGlowPainter({
    required this.progress,
    required this.color,
    required this.stroke,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: glowIntensity * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 2.8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_RingGlowPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.stroke != stroke ||
      old.glowIntensity != glowIntensity;
}
