import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../services/cooking_session.dart';
import '../../theme/app_colors.dart';

/// Animated mic orb that reflects the current [SessionState].
///
/// - idle      : slow breathing scale 1.0↔1.06 (2.4 s ease-in-out).
/// - listening : concentric expanding rings painted behind the orb.
/// - understanding : subtle spin / pulse on the orb itself.
/// - speaking  : warm glow pulse (opacity of the radial glow).
class MicOrb extends StatefulWidget {
  final SessionState state;
  final double size;

  const MicOrb({
    super.key,
    required this.state,
    this.size = 160,
  });

  @override
  State<MicOrb> createState() => _MicOrbState();
}

class _MicOrbState extends State<MicOrb> with TickerProviderStateMixin {
  // ---- idle: breathing scale ----
  late final AnimationController _breathCtrl;
  late final Animation<double> _breathAnim;

  // ---- listening: ring expansion ----
  late final AnimationController _ringCtrl;

  // ---- understanding: rotation ----
  late final AnimationController _spinCtrl;

  // ---- speaking: glow opacity pulse ----
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();

    // Breathing (idle)
    _breathCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _breathAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _breathCtrl, curve: Curves.easeInOut),
    );
    _breathCtrl.repeat(reverse: true);

    // Rings (listening)
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    // Spin (understanding)
    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Glow pulse (speaking)
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _glowAnim = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
    _glowCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathCtrl.dispose();
    _ringCtrl.dispose();
    _spinCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final size = widget.size;

    return SizedBox(
      width: size * 2,
      height: size * 2,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _breathAnim,
          _ringCtrl,
          _spinCtrl,
          _glowAnim,
        ]),
        builder: (context, _) {
          double scale = 1.0;
          double glowOpacity = 0.08;
          bool showRings = false;
          double rotationAngle = 0;

          switch (s) {
            case SessionState.idle:
              scale = _breathAnim.value;
              glowOpacity = 0.08;
              break;
            case SessionState.listening:
              scale = 1.0;
              glowOpacity = 0.12;
              showRings = true;
              break;
            case SessionState.understanding:
              scale = 1.0 + math.sin(_spinCtrl.value * 2 * math.pi) * 0.03;
              glowOpacity = 0.15;
              rotationAngle = _spinCtrl.value * 2 * math.pi;
              break;
            case SessionState.speaking:
              scale = 1.0;
              glowOpacity = _glowAnim.value;
              break;
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              // Radial background glow
              Opacity(
                opacity: glowOpacity.clamp(0.0, 1.0),
                child: Container(
                  width: size * 1.8,
                  height: size * 1.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.ember,
                        AppColors.ember.withValues(alpha: 0.0),
                      ],
                      stops: const [0.08, 1.0],
                    ),
                  ),
                ),
              ),

              // Expanding rings (listening state)
              if (showRings)
                CustomPaint(
                  size: Size(size * 1.8, size * 1.8),
                  painter: _RingPainter(
                    progress: _ringCtrl.value,
                    color: AppColors.ember,
                    baseRadius: size * 0.5,
                    maxRadius: size * 0.85,
                    ringCount: 3,
                  ),
                ),

              // Spinning arc (understanding / transcribing state) — a clear
              // "processing" indicator while Whisper decodes the phrase.
              if (s == SessionState.understanding)
                CustomPaint(
                  size: Size(size * 1.8, size * 1.8),
                  painter: _ArcPainter(
                    progress: _spinCtrl.value,
                    color: AppColors.ember,
                    radius: size * 0.62,
                  ),
                ),

              // Orb core
              Transform.scale(
                scale: scale,
                child: Transform.rotate(
                  angle: s == SessionState.understanding ? rotationAngle * 0.05 : 0,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.ember,
                    ),
                    child: Center(
                      child: Icon(
                        PhosphorIconsDuotone.microphone,
                        size: size * 0.38,
                        color: AppColors.canvas,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Paints a rotating arc (a "spinner") used for the understanding/processing
/// state. Two opposed arc segments sweep around continuously.
class _ArcPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  final double radius;

  const _ArcPainter({
    required this.progress,
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final start = progress * 2 * math.pi;
    const sweep = math.pi * 0.55; // ~100°

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, start, sweep, false, paint);
    canvas.drawArc(rect, start + math.pi, sweep, false,
        paint..color = color.withValues(alpha: 0.45));
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color || old.radius != radius;
}

/// Paints concentric rings that grow outward and fade, looping continuously.
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double baseRadius;
  final double maxRadius;
  final int ringCount;

  const _RingPainter({
    required this.progress,
    required this.color,
    required this.baseRadius,
    required this.maxRadius,
    required this.ringCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < ringCount; i++) {
      final phase = (progress + i / ringCount) % 1.0;
      final radius = baseRadius + (maxRadius - baseRadius) * phase;
      final opacity = (1.0 - phase).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = color.withValues(alpha: opacity * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.baseRadius != baseRadius ||
      old.maxRadius != maxRadius;
}
