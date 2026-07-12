import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import 'muscle_atlas.dart';

/// Front + back anatomical heatmap that highlights which muscle groups were
/// trained, rendered from detailed vendored muscle SVGs (see [MuscleAtlas]).
///
/// [intensity] maps a coarse muscle key (matching `Exercise.primaryMuscle`:
/// chest/back/shoulders/rear-delts/biceps/triceps/core/quads/hamstrings/
/// glutes/calves) to a 0..1 value (already normalised by the caller). Untrained
/// muscles render in a neutral slate; trained ones ramp slate → coral → red.
/// [onMuscleTap] (if provided) fires with the tapped muscle key.
class MuscleMap extends StatefulWidget {
  final Map<String, double> intensity;
  final void Function(String muscle)? onMuscleTap;

  const MuscleMap({
    super.key,
    required this.intensity,
    this.onMuscleTap,
  });

  @override
  State<MuscleMap> createState() => _MuscleMapState();
}

class _MuscleMapState extends State<MuscleMap> {
  late Future<List<AtlasFigure>> _figures;

  @override
  void initState() {
    super.initState();
    _figures = Future.wait([
      MuscleAtlas.load(back: false),
      MuscleAtlas.load(back: true),
    ]);
  }

  double _i(String key) => (widget.intensity[key] ?? 0).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AtlasFigure>>(
      future: _figures,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SizedBox(
            height: 260,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.ember),
              ),
            ),
          );
        }
        final front = snap.data![0];
        final back = snap.data![1];
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _figure('Front', front)),
                const SizedBox(width: 8),
                Expanded(child: _figure('Back', back)),
              ],
            ),
            const SizedBox(height: 12),
            _legend(),
          ],
        );
      },
    );
  }

  Widget _figure(String label, AtlasFigure figure) {
    final ratio = figure.viewBox.width / figure.viewBox.height;
    return Column(
      children: [
        AspectRatio(
          aspectRatio: ratio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: widget.onMuscleTap == null
                    ? null
                    : (d) {
                        final key =
                            _hitTest(figure, size, d.localPosition);
                        if (key != null) widget.onMuscleTap!(key);
                      },
                child: CustomPaint(
                  size: size,
                  painter: _FigurePainter(figure, _i),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMid,
            )),
      ],
    );
  }

  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Under',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11, color: AppColors.textLow)),
        const SizedBox(width: 8),
        Container(
          width: 120,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: const LinearGradient(
              colors: [
                _FigurePainter.muscleBase,
                AppColors.accent,
                AppColors.danger,
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('Target',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11, color: AppColors.textLow)),
      ],
    );
  }

  /// Maps a tap to a muscle key by inverse-scaling into viewBox space and
  /// testing muscle paths from topmost (last drawn) to bottom.
  static String? _hitTest(AtlasFigure figure, Size size, Offset local) {
    final vb = figure.viewBox;
    final scale =
        math.min(size.width / vb.width, size.height / vb.height);
    final ox = (size.width - vb.width * scale) / 2;
    final oy = (size.height - vb.height * scale) / 2;
    final pt = Offset((local.dx - ox) / scale, (local.dy - oy) / scale);
    for (final ap in figure.paths.reversed) {
      if (ap.key != null && ap.path.contains(pt)) return ap.key;
    }
    return null;
  }
}

/// Paints one anatomical figure: every path filled by its muscle's training
/// intensity (neutral slate when untrained / untracked) with a hairline outline
/// for the segmented "plated" look.
class _FigurePainter extends CustomPainter {
  final AtlasFigure figure;
  final double Function(String) intensity;
  _FigurePainter(this.figure, this.intensity);

  /// Light body base (the SVG underlayer / tendon gaps).
  static const _baseLight = Color(0xFFEAECF2);

  /// Neutral tint of an untrained / untracked muscle (a touch more saturated
  /// than the base so muscles — incl. thin forearms — read even untrained).
  static const muscleBase = Color(0xFF9BA4BE);
  static const _outline = Color(0xFF565E80);

  static Color _colorFor(double t) {
    if (t <= 0) return muscleBase;
    if (t <= 0.5) {
      return Color.lerp(muscleBase, AppColors.accent, t / 0.5)!;
    }
    return Color.lerp(AppColors.accent, AppColors.danger, (t - 0.5) / 0.5)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final vb = figure.viewBox;
    final scale =
        math.min(size.width / vb.width, size.height / vb.height);
    final ox = (size.width - vb.width * scale) / 2;
    final oy = (size.height - vb.height * scale) / 2;

    canvas.save();
    canvas.translate(ox, oy);
    canvas.scale(scale);

    final muscleOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1 / scale
      ..strokeJoin = StrokeJoin.round
      ..color = _outline.withValues(alpha: 0.62);
    final baseOutline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 / scale
      ..strokeJoin = StrokeJoin.round
      ..color = _outline.withValues(alpha: 0.28);

    for (final ap in figure.paths) {
      if (ap.isLightBase) {
        // Body underlayer / tendon gaps — light fill, faint edge.
        canvas.drawPath(ap.path, Paint()..color = _baseLight);
        canvas.drawPath(ap.path, baseOutline);
      } else if (ap.isMuscleShade) {
        // Muscle: tinted by its group's training intensity (neutral if
        // untrained or untracked, e.g. forearms/neck).
        final t = ap.key == null ? 0.0 : intensity(ap.key!);
        canvas.drawPath(ap.path, Paint()..color = _colorFor(t));
        canvas.drawPath(ap.path, muscleOutline);
      }
      // fill="none" paths (background / clip / detail strokes) are skipped so
      // nothing paints outside the silhouette.
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_FigurePainter old) =>
      old.figure != figure || old.intensity != intensity;
}
