/// Research-based weekly training-volume landmarks for hypertrophy, used to
/// colour the analytics muscle map: a muscle reddens as its weekly working-set
/// count approaches the volume that drives growth.
///
/// Numbers are **hard working sets per muscle per week** and follow the
/// Renaissance Periodization / Dr. Mike Israetel volume-landmark framework
/// (MV / MEV / MAV / MRV), cross-checked against Brad Schoenfeld's dose-response
/// meta-analyses on weekly set volume and hypertrophy.
///
/// Landmarks:
///   - MV  (Maintenance Volume)        — sets to keep muscle, not grow it.
///   - MEV (Minimum Effective Volume)  — the floor where growth reliably starts.
///   - MAV (Maximum Adaptive Volume)   — top of the productive range; the best
///                                       return on fatigue. This is our "fully
///                                       stimulated / 100% red" target.
///   - MRV (Maximum Recoverable Volume)— the recoverable ceiling; sustainable
///                                       only briefly before a deload. NOT the
///                                       target — training here chronically is
///                                       overreaching.
///
/// We anchor "fully red" at MAV (not MEV, which would light the map up at
/// minimal effort, and not MRV, which would nudge users into unrecoverable
/// volume). Schoenfeld et al. (2017) show growth keeps rising past ~10
/// sets/week with diminishing returns and an eventual recovery-limited plateau,
/// so the sweet spot sits at the upper end of the productive range — i.e. MAV.
///
/// Sources:
///   - Renaissance Periodization — Training Volume Landmarks for Muscle Growth
///     https://rpstrength.com/blogs/articles/training-volume-landmarks-muscle-growth
///   - Schoenfeld, Ogborn & Krieger (2017), "Dose-response relationship between
///     weekly resistance training volume and increases in muscle mass" — the
///     <5 / 5–9 / 10+ sets/week tiers, ~+0.37% growth per added set.
library;

/// Weekly working-set landmarks for one muscle group (sets/week).
class MuscleVolumeLandmark {
  /// Maintenance volume — enough to retain, not grow.
  final int mv;

  /// Minimum effective volume — growth reliably begins here.
  final int mev;

  /// Maximum adaptive volume — top of the productive range; our red target.
  final int mav;

  /// Maximum recoverable volume — the unsustainable ceiling.
  final int mrv;

  const MuscleVolumeLandmark({
    required this.mv,
    required this.mev,
    required this.mav,
    required this.mrv,
  });
}

/// Per-muscle landmarks keyed to the app's `Exercise.primaryMuscle` vocabulary
/// (chest, back, shoulders, rear-delts, biceps, triceps, core, quads,
/// hamstrings, glutes, calves, forearms).
///
/// Mapping notes: RP groups side+rear delts together; we split `shoulders`
/// (side-delt driven — the main hypertrophy target) from `rear-delts` so the
/// map rewards dedicated rear-delt work. `core` maps to abs. `forearms` carries
/// a low MEV (grip/pulling already loads them heavily) but a high MRV.
const Map<String, MuscleVolumeLandmark> kMuscleVolumeLandmarks = {
  'chest': MuscleVolumeLandmark(mv: 6, mev: 8, mav: 20, mrv: 22),
  'back': MuscleVolumeLandmark(mv: 6, mev: 10, mav: 22, mrv: 25),
  'shoulders': MuscleVolumeLandmark(mv: 6, mev: 8, mav: 20, mrv: 26),
  'rear-delts': MuscleVolumeLandmark(mv: 0, mev: 6, mav: 18, mrv: 22),
  'biceps': MuscleVolumeLandmark(mv: 5, mev: 8, mav: 18, mrv: 26),
  'triceps': MuscleVolumeLandmark(mv: 4, mev: 6, mav: 14, mrv: 18),
  'core': MuscleVolumeLandmark(mv: 0, mev: 6, mav: 18, mrv: 25),
  'quads': MuscleVolumeLandmark(mv: 6, mev: 8, mav: 18, mrv: 20),
  'hamstrings': MuscleVolumeLandmark(mv: 4, mev: 6, mav: 15, mrv: 20),
  'glutes': MuscleVolumeLandmark(mv: 0, mev: 4, mav: 14, mrv: 16),
  'calves': MuscleVolumeLandmark(mv: 6, mev: 8, mav: 15, mrv: 20),
  'forearms': MuscleVolumeLandmark(mv: 2, mev: 6, mav: 14, mrv: 25),
  // Smaller lower-body stabilizers — modest targets (no formal RP landmarks;
  // chosen to mirror other small muscles so the heatmap tints them sensibly).
  'adductors': MuscleVolumeLandmark(mv: 0, mev: 4, mav: 12, mrv: 16),
  'abductors': MuscleVolumeLandmark(mv: 0, mev: 4, mav: 12, mrv: 16),
  'tibialis': MuscleVolumeLandmark(mv: 0, mev: 4, mav: 12, mrv: 16),
};

/// Maps a muscle's weekly working-set count to a 0..1 "fill" used by the muscle
/// map's colour ramp (slate → coral → red).
///
/// The ramp is anchored to the muscle's own research landmarks rather than to
/// the busiest muscle of the week, so colour means the same thing across the
/// map and across weeks:
///   - 0 sets (or unknown muscle)  → 0.0  (untrained slate)
///   - approaching MEV              → 0.0 .. 0.5  (slate → coral; under-dosed)
///   - MEV reached                  → 0.5  (coral; productive volume begins)
///   - MEV → MAV                    → 0.5 .. 1.0 (coral → red; filling to target)
///   - at/above MAV                 → 1.0  (full red; weekly target hit)
///
/// Clamped at 1.0 — past MAV the muscle is already maxed on the map (the MRV
/// "overreaching" zone is surfaced separately in the breakdown sheet, not by
/// pushing colour beyond red).
double hypertrophyFill(String muscleKey, num weeklySets) {
  final lm = kMuscleVolumeLandmarks[muscleKey];
  if (lm == null || weeklySets <= 0) return 0.0;

  final sets = weeklySets.toDouble();
  if (lm.mev > 0 && sets < lm.mev) {
    return (0.5 * (sets / lm.mev)).clamp(0.0, 0.5);
  }
  final span = lm.mav - lm.mev;
  if (span <= 0) return 1.0;
  final progress = (sets - lm.mev) / span;
  return (0.5 + 0.5 * progress).clamp(0.0, 1.0);
}
