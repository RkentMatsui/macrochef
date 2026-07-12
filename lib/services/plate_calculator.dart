/// Barbell plate math for the logger's plate calculator (Boostcamp-style):
/// given a target total weight, a bar weight, and the plates available in the
/// gym, work out what to load on EACH side of the bar — and the reverse, the
/// total for a given set of loaded plates.
///
/// Unit-agnostic: all weights are in whatever unit the caller works in (kg or
/// lb); pass the matching plate set. A standard Olympic bar is 20 kg / 45 lb.
library;

/// One plate denomination and how many of it go on each side of the bar.
class PlateOnBar {
  final double weight; // per plate, in the working unit
  final int count; // plates per side
  const PlateOnBar(this.weight, this.count);
}

/// The result of loading a bar: the plates per side (heaviest first) and the
/// achievable total. [exact] is false when the available plates can't hit the
/// requested target precisely (the loadout is then the closest that does not
/// exceed it).
class PlateLoadout {
  final double bar;
  final List<PlateOnBar> perSide;
  final double total;
  final double target;

  const PlateLoadout({
    required this.bar,
    required this.perSide,
    required this.total,
    required this.target,
  });

  bool get exact => (total - target).abs() < 1e-6;

  /// Weight loaded on one side of the bar.
  double get perSideWeight => (total - bar) / 2;
}

/// Standard plate denominations (per plate), heaviest → lightest.
const List<double> kKgPlates = [25, 20, 15, 10, 5, 2.5, 1.25];
const List<double> kLbPlates = [45, 35, 25, 10, 5, 2.5];

/// Common bar weights to offer in the picker, per unit.
const List<double> kKgBars = [20, 15, 10, 0];
const List<double> kLbBars = [45, 35, 25, 0];

class PlateCalculator {
  static List<double> platesFor(String unit) =>
      unit == 'lb' ? kLbPlates : kKgPlates;

  static List<double> barsFor(String unit) => unit == 'lb' ? kLbBars : kKgBars;

  static double defaultBar(String unit) => unit == 'lb' ? 45 : 20;

  /// Greedily load each side of the bar to get as close to [target] as possible
  /// without exceeding it, using [plates] (defaults to the standard set for
  /// [unit]). Returns the per-side breakdown plus the achievable total.
  static PlateLoadout solve({
    required double target,
    required double bar,
    List<double>? plates,
    String unit = 'kg',
  }) {
    final avail = [...(plates ?? platesFor(unit))]
      ..sort((a, b) => b.compareTo(a));
    final perSideTarget = (target - bar) / 2;
    final out = <PlateOnBar>[];
    var remaining = perSideTarget;
    if (perSideTarget > 0) {
      for (final p in avail) {
        if (p <= 0) continue;
        var c = 0;
        while (remaining >= p - 1e-9) {
          remaining -= p;
          c++;
        }
        if (c > 0) out.add(PlateOnBar(p, c));
      }
    }
    return PlateLoadout(
      bar: bar,
      perSide: out,
      total: totalFor(bar: bar, perSide: out),
      target: target,
    );
  }

  /// Total bar weight for a given per-side loadout: `bar + 2 × Σ(plate×count)`.
  static double totalFor({
    required double bar,
    required Iterable<PlateOnBar> perSide,
  }) =>
      bar +
      2 * perSide.fold<double>(0, (s, p) => s + p.weight * p.count);

  /// Total for a per-side denomination→count map.
  static double totalForCounts({
    required double bar,
    required Map<double, int> counts,
  }) =>
      bar +
      2 *
          counts.entries
              .fold<double>(0, (s, e) => s + e.key * e.value);
}
