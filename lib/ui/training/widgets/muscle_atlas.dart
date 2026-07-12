import 'dart:ui';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

/// Maps an anatomical SVG element id (e.g. `latissimus_dorsi_r`,
/// `biceps_femoris_l`) to one of the app's coarse muscle keys used for training
/// volume (matching `Exercise.primaryMuscle`):
/// chest/back/shoulders/rear-delts/biceps/triceps/core/quads/hamstrings/
/// glutes/calves/adductors/abductors/tibialis. Returns null for structural /
/// untracked anatomy (forearms, neck, face, hands, feet, body underlayer),
/// which is drawn in the neutral base tint.
String? muscleKeyForId(String? id) {
  if (id == null) return null;
  final s = id.toLowerCase();
  bool has(String p) => s.contains(p);

  // Legs — check the leg "biceps" (femoris) before the arm biceps_brachii.
  if (has('biceps_femoris') || has('semimembranosus') || has('semitendinosus')) {
    return 'hamstrings';
  }
  // Outer-hip abductors (glute medius/minimus + TFL) before the glute max.
  if (has('gluteus_medius') ||
      has('gluteus_minimus') ||
      has('tensor_fasciae') ||
      has('tensor_fascia')) {
    return 'abductors';
  }
  if (has('gluteus')) return 'glutes';
  // Inner thigh adductors before the quads (they sit medially on the figure).
  if (has('adductor') || has('gracilis') || has('pectineus')) {
    return 'adductors';
  }
  if (has('rectus_femoris') ||
      has('vastus_') ||
      has('sartoris') ||
      has('iliotibial')) {
    return 'quads';
  }
  // Anterior shin compartment (tibialis + the long toe-extensors that share it).
  if (has('tibialis') ||
      has('extensor_hallucis') ||
      has('extensor_digitorum_longus')) {
    return 'tibialis';
  }
  // Lower-leg posterior + lateral compartments.
  if (has('gastrocnemius') || has('soleus') || has('fibularis')) {
    return 'calves';
  }
  // Trunk.
  if (has('pectoralis')) return 'chest';
  if (has('rectus_abdominis') || has('external_oblique') || has('serratus')) {
    return 'core';
  }
  if (has('latissimus') ||
      has('trapezius') ||
      has('infraspinatus') ||
      has('teres') ||
      has('rhomboid') ||
      has('erector')) {
    return 'back';
  }
  // Shoulders — posterior delt is tracked separately as rear-delts.
  if (has('posterior_deltoid')) return 'rear-delts';
  if (has('anterior_deltoid') || has('lateral_deltoid')) return 'shoulders';
  // Upper arm.
  if (has('biceps_brachii')) return 'biceps';
  if (has('triceps_brachii') || has('anconeus')) return 'triceps';
  // Forearm flexors/extensors (the lower-leg `*_longus` extensors were already
  // resolved to calves above, so the remaining extensor/flexor here are arm).
  if (has('brachioradialis') ||
      has('flexor_carpi') ||
      has('extensor_carpi') ||
      has('palmaris') ||
      has('pronator') ||
      has('flexor_digitorum') ||
      has('extensor_digitorum')) {
    return 'forearms';
  }

  return null;
}

/// One parsed SVG region: its [path] (in unscaled viewBox coordinates), the
/// resolved coarse muscle [key] (null = structural/untracked), and the raw
/// element [id]/[region] for debugging.
class AtlasPath {
  final String? id;
  final String region;
  final String? key;
  final Path path;

  /// The SVG `fill` of this path: `#E0E0E0` for the light body base, `#BDBDBD`
  /// for muscle shading, `none` for outline-only/background paths (not filled).
  final String? fill;

  const AtlasPath({
    required this.id,
    required this.region,
    required this.key,
    required this.path,
    required this.fill,
  });

  /// True for the light body-underlayer / tendon-gap fills.
  bool get isLightBase => (fill ?? '').toLowerCase() == '#e0e0e0';

  /// True for muscle-shaded fills (the only paths we tint by intensity).
  bool get isMuscleShade => (fill ?? '').toLowerCase() == '#bdbdbd';
}

/// A parsed anatomical figure: the viewBox size plus every drawable path in
/// document order (so the body underlayer paints first, muscle segments on top).
class AtlasFigure {
  final Size viewBox;
  final List<AtlasPath> paths;
  const AtlasFigure({required this.viewBox, required this.paths});
}

/// Loads + parses the vendored muscle SVGs once and caches the result. [back]
/// selects the posterior view.
class MuscleAtlas {
  static const _frontAsset = 'assets/anatomy/muscle_layer_front.svg';
  static const _backAsset = 'assets/anatomy/muscle_layer_back.svg';

  static final Map<bool, AtlasFigure> _cache = {};
  static final Map<bool, Future<AtlasFigure>> _inflight = {};

  static Future<AtlasFigure> load({required bool back}) {
    final cached = _cache[back];
    if (cached != null) return Future.value(cached);
    return _inflight[back] ??= _parse(back).then((fig) {
      _cache[back] = fig;
      _inflight.remove(back);
      return fig;
    });
  }

  static Future<AtlasFigure> _parse(bool back) async {
    final raw = await rootBundle.loadString(back ? _backAsset : _frontAsset);
    final doc = XmlDocument.parse(raw);
    final svg = doc.rootElement;

    final vb = (svg.getAttribute('viewBox') ?? '0 0 100 100')
        .trim()
        .split(RegExp(r'[\s,]+'))
        .map(double.parse)
        .toList();
    final size = Size(vb[2], vb[3]);

    final paths = <AtlasPath>[];
    void visit(XmlElement el, String region) {
      for (final child in el.childElements) {
        final tag = child.name.local;
        if (tag == 'g') {
          visit(child, child.getAttribute('id') ?? region);
        } else if (tag == 'path') {
          final d = child.getAttribute('d');
          if (d == null || d.isEmpty) continue;
          final id = child.getAttribute('id');
          Path p;
          try {
            p = parseSvgPathData(d);
          } catch (_) {
            continue;
          }
          p.fillType = PathFillType.evenOdd;
          paths.add(AtlasPath(
            id: id,
            region: region,
            key: muscleKeyForId(id),
            path: p,
            fill: child.getAttribute('fill'),
          ));
        }
      }
    }

    visit(svg, 'root');
    return AtlasFigure(viewBox: size, paths: paths);
  }
}
